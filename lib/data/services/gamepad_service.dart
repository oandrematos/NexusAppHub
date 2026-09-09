import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Serviço gerenciador de entradas de Gamepad e navegação espacial no Nexus App Hub.
/// Detecta controles Xbox, PlayStation, Switch e genéricos tanto no Windows quanto no Android,
/// além de oferecer suporte a teclado com mapeamento unificado de console.
class GamepadService extends ChangeNotifier {
  static final GamepadService _instance = GamepadService._internal();
  factory GamepadService() => _instance;
  GamepadService._internal();

  bool _isGamepadActive = false;
  bool get isGamepadActive => _isGamepadActive;

  // Callbacks para ações globais
  VoidCallback? onToggleBigPicture;
  VoidCallback? onTabNext;
  VoidCallback? onTabPrevious;
  VoidCallback? onBackAction;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void disposeService() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _initialized = false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;

    // Detecta se a entrada originou de um botão de Gamepad
    if (_isGamepadKey(key)) {
      if (!_isGamepadActive) {
        _isGamepadActive = true;
        notifyListeners();
      }
    }

    // Atalho global para Modo Big Picture (Select / View / Share / Guide / F11)
    if (key == LogicalKeyboardKey.gameButtonSelect ||
        key == LogicalKeyboardKey.gameButtonMode ||
        key == LogicalKeyboardKey.f11) {
      if (onToggleBigPicture != null) {
        onToggleBigPicture!();
        return true;
      }
    }

    // Navegação entre abas principais (LB / RB ou PageUp / PageDown)
    if (key == LogicalKeyboardKey.gameButtonRight1 ||
        key == LogicalKeyboardKey.pageDown) {
      if (onTabNext != null) {
        onTabNext!();
        return true;
      }
    }

    if (key == LogicalKeyboardKey.gameButtonLeft1 ||
        key == LogicalKeyboardKey.pageUp) {
      if (onTabPrevious != null) {
        onTabPrevious!();
        return true;
      }
    }

    // Botão B para voltar
    if (key == LogicalKeyboardKey.gameButtonB) {
      if (onBackAction != null) {
        onBackAction!();
        return true;
      }
    }

    return false;
  }

  static bool _isGamepadKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.gameButtonB ||
        key == LogicalKeyboardKey.gameButtonX ||
        key == LogicalKeyboardKey.gameButtonY ||
        key == LogicalKeyboardKey.gameButtonLeft1 ||
        key == LogicalKeyboardKey.gameButtonRight1 ||
        key == LogicalKeyboardKey.gameButtonLeft2 ||
        key == LogicalKeyboardKey.gameButtonRight2 ||
        key == LogicalKeyboardKey.gameButtonSelect ||
        key == LogicalKeyboardKey.gameButtonStart ||
        key == LogicalKeyboardKey.gameButtonMode ||
        key == LogicalKeyboardKey.gameButtonThumbLeft ||
        key == LogicalKeyboardKey.gameButtonThumbRight;
  }

  /// Verifica se a tecla é de ativação/confirmação primária
  static bool isActionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
  }

  /// Verifica se a tecla é de cancelamento/retorno
  static bool isBackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.gameButtonB ||
        key == LogicalKeyboardKey.escape;
  }
}
