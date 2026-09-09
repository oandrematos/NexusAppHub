import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Widget 3D ultra-leve e otimizado para rodar a 120 FPS cravados sem engasgos.
/// Em repouso, não executa cálculos matriciais nem animações, preservando
/// 100% da performance da rolagem da loja.
/// Quando focado por controle ou apontado com o mouse, ativa perspectiva suave
/// e anel neon dinâmico (Gamepad Focus Ring).
class Tilt3DWidget extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final double perspective;
  final bool enableGlare;
  final double borderRadius;
  final VoidCallback? onTap;
  final double scaleOnHover;
  final Color? glareColor;
  final FocusNode? focusNode;
  final bool autofocus;

  const Tilt3DWidget({
    super.key,
    required this.child,
    this.maxTilt = 0.08,
    this.perspective = 0.0012,
    this.enableGlare = false,
    this.borderRadius = 18.0,
    this.onTap,
    this.scaleOnHover = 1.03,
    this.glareColor,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<Tilt3DWidget> createState() => _Tilt3DWidgetState();
}

class _Tilt3DWidgetState extends State<Tilt3DWidget> with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  bool _isHovered = false;
  bool _isFocused = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent e) {
    final size = context.size;
    if (size == null || size.width == 0 || size.height == 0) return;
    final dx = ((e.localPosition.dx / size.width) - 0.5) * 2.0;
    final dy = ((e.localPosition.dy / size.height) - 0.5) * 2.0;
    setState(() {
      _tilt = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
      _isHovered = true;
    });
  }

  void _onExit() {
    if (_isHovered) {
      setState(() {
        _tilt = Offset.zero;
        _isHovered = false;
      });
    }
  }

  void _handleFocusChange(bool hasFocus) {
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
        _tilt = hasFocus ? const Offset(0.0, -0.15) : Offset.zero;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (widget.onTap != null) {
        widget.onTap!();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || _isFocused;

    // Se estiver em repouso e sem foco, renderiza o container padrão com zero custo de animação
    if (!active && _tilt == Offset.zero) {
      return Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        onFocusChange: _handleFocusChange,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onHover: _onHover,
          cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      );
    }

    // Quando ativo, aplica a projeção 3D acelerada por hardware
    final tiltX = _tilt.dx;
    final tiltY = _tilt.dy;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, widget.perspective)
      ..rotateX(-tiltY * widget.maxTilt)
      ..rotateY(tiltX * widget.maxTilt)
      ..scaleByDouble(widget.scaleOnHover, widget.scaleOnHover, 1.0, 1.0);

    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onHover: _onHover,
        onExit: (_) => _onExit(),
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () {
            _effectiveFocusNode.requestFocus();
            widget.onTap?.call();
          },
          child: Transform(
            transform: matrix,
            alignment: FractionalOffset.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? AppColors.accentCyan.withValues(alpha: 0.5)
                        : Colors.cyanAccent.withValues(alpha: 0.18),
                    blurRadius: _isFocused ? 24 : 16,
                    spreadRadius: _isFocused ? 3 : 1,
                    offset: Offset(tiltX * 6, tiltY * 6 + 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    widget.child,

                    // Gamepad Focus Ring Neon
                    if (_isFocused)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                              border: Border.all(
                                color: AppColors.accentCyan,
                                width: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
