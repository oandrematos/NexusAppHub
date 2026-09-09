import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Definições nativas da API XInput do Windows
final class XInputGamepad extends Struct {
  @Uint16()
  external int wButtons;
  @Uint8()
  external int bLeftTrigger;
  @Uint8()
  external int bRightTrigger;
  @Int16()
  external int sThumbLX;
  @Int16()
  external int sThumbLY;
  @Int16()
  external int sThumbRX;
  @Int16()
  external int sThumbRY;
}

final class XInputState extends Struct {
  @Uint32()
  external int dwPacketNumber;
  external XInputGamepad gamepad;
}

typedef XInputGetStateNative = Uint32 Function(Uint32 dwUserIndex, Pointer<XInputState> pState);
typedef XInputGetStateDart = int Function(int dwUserIndex, Pointer<XInputState> pState);

/// Serviço de Gamepad de Ultra-Baixa Latência para Windows (XInput nativo via FFI)
/// e Android/Desktop (HardwareKeyboard).
class GamepadService extends ChangeNotifier {
  static final GamepadService _instance = GamepadService._internal();
  factory GamepadService() => _instance;
  GamepadService._internal();

  bool _isGamepadConnected = false;
  bool get isGamepadConnected => _isGamepadConnected;

  // Callbacks globais
  VoidCallback? onToggleBigPicture;
  VoidCallback? onTabNext;
  VoidCallback? onTabPrevious;
  VoidCallback? onBackAction;
  VoidCallback? onActionX;
  VoidCallback? onActionA;

  // Callbacks para navegação direcional no Big Picture
  void Function(int direction)? onDirectionalStep; // -1: esquerda, 1: direita, -2: cima, 2: baixo

  Timer? _pollingTimer;
  Pointer<XInputState>? _xinputPtr;
  XInputGetStateDart? _xinputGetState;

  int _lastButtons = 0;
  DateTime _lastDirectionTime = DateTime.now();

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // 1. Escuta eventos padrão de teclado (Windows, Linux, Android)
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // 2. Se estiver no Windows, ativa o motor nativo XInput via FFI
    if (Platform.isWindows) {
      _initWindowsXInput();
    }
  }

  void _initWindowsXInput() {
    DynamicLibrary? dylib;
    for (final dll in ['xinput1_4.dll', 'xinput1_3.dll', 'xinput9_1_0.dll']) {
      try {
        dylib = DynamicLibrary.open(dll);
        break;
      } catch (_) {}
    }

    if (dylib != null) {
      try {
        _xinputGetState = dylib.lookupFunction<XInputGetStateNative, XInputGetStateDart>('XInputGetState');
        _xinputPtr = calloc<XInputState>();

        // Polling contínuo de 20ms (~50-60 Hz) com custo insignificante de CPU (< 0.05%)
        _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) => _pollXInput());
      } catch (_) {}
    }
  }

  void _pollXInput() {
    if (_xinputGetState == null || _xinputPtr == null) return;

    final res = _xinputGetState!(0, _xinputPtr!);
    final connected = (res == 0);

    if (connected != _isGamepadConnected) {
      _isGamepadConnected = connected;
      notifyListeners();
    }

    if (!connected) return;

    final state = _xinputPtr!.ref;
    final buttons = state.gamepad.wButtons;
    final thumbLX = state.gamepad.sThumbLX;
    final thumbLY = state.gamepad.sThumbLY;

    // Detecta botões recém-pressionados (Borda de subida)
    final pressed = buttons & ~_lastButtons;
    _lastButtons = buttons;

    // Botão A (0x1000)
    if ((pressed & 0x1000) != 0) {
      if (onActionA != null) {
        onActionA!();
      } else {
        _triggerFocusActivation();
      }
    }

    // Botão B (0x2000)
    if ((pressed & 0x2000) != 0) {
      onBackAction?.call();
    }

    // Botão X (0x4000)
    if ((pressed & 0x4000) != 0) {
      onActionX?.call();
    }

    // Bumpers LB (0x0100) e RB (0x0200)
    if ((pressed & 0x0100) != 0) {
      onTabPrevious?.call();
    }
    if ((pressed & 0x0200) != 0) {
      onTabNext?.call();
    }

    // Select / Back (0x0020) ou Start (0x0010) -> Alternar Big Picture
    if ((pressed & 0x0020) != 0 || (pressed & 0x0010) != 0) {
      onToggleBigPicture?.call();
    }

    // Navegação Direcional: D-Pad ou Analógico com Deadzone
    final now = DateTime.now();
    final elapsed = now.difference(_lastDirectionTime).inMilliseconds;

    // D-Pad: UP=0x0001, DOWN=0x0002, LEFT=0x0004, RIGHT=0x0008
    final isRight = (buttons & 0x0008) != 0 || thumbLX > 15000;
    final isLeft = (buttons & 0x0004) != 0 || thumbLX < -15000;
    final isDown = (buttons & 0x0002) != 0 || thumbLY < -15000;
    final isUp = (buttons & 0x0001) != 0 || thumbLY > 15000;

    if (elapsed > 170) {
      if (isRight) {
        _lastDirectionTime = now;
        _navigate(TraversalDirection.right, 1);
      } else if (isLeft) {
        _lastDirectionTime = now;
        _navigate(TraversalDirection.left, -1);
      } else if (isDown) {
        _lastDirectionTime = now;
        _navigate(TraversalDirection.down, 2);
      } else if (isUp) {
        _lastDirectionTime = now;
        _navigate(TraversalDirection.up, -2);
      }
    }
  }

  void _navigate(TraversalDirection direction, int stepCode) {
    if (onDirectionalStep != null) {
      onDirectionalStep!(stepCode);
    }
    FocusManager.instance.primaryFocus?.focusInDirection(direction);
  }

  void _triggerFocusActivation() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.context != null) {
      Actions.maybeInvoke(focus.context!, const ActivateIntent());
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.f11 ||
        key == LogicalKeyboardKey.gameButtonSelect ||
        key == LogicalKeyboardKey.gameButtonMode) {
      onToggleBigPicture?.call();
      return true;
    }

    if (key == LogicalKeyboardKey.gameButtonRight1 || key == LogicalKeyboardKey.pageDown) {
      onTabNext?.call();
      return true;
    }

    if (key == LogicalKeyboardKey.gameButtonLeft1 || key == LogicalKeyboardKey.pageUp) {
      onTabPrevious?.call();
      return true;
    }

    if (key == LogicalKeyboardKey.gameButtonB || key == LogicalKeyboardKey.escape) {
      if (onBackAction != null) {
        onBackAction!();
        return true;
      }
    }

    return false;
  }

  void disposeService() {
    _pollingTimer?.cancel();
    if (_xinputPtr != null) {
      calloc.free(_xinputPtr!);
      _xinputPtr = null;
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _initialized = false;
  }
}
