import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Widget 3D de alta performance projetado para rodar a 120 FPS cravados.
/// Aplica perspectiva tridimensional com rotação nos eixos X e Y baseada na
/// interação do usuário (mouse no Desktop ou toque no Mobile) e camada de
/// reflexo especular holográfico dinâmico (TCG Foil Shimmer).
///
/// Possui suporte nativo e espacial a Gamepads (Xbox/PlayStation) e Teclado,
/// exibindo anel de foco neon 3D (Gamepad Focus Ring) e auto-scroll dinâmico.
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
    this.maxTilt = 0.16, // ~9 a 10 graus de inclinação máxima
    this.perspective = 0.0014, // Fator de perspectiva 3D realista
    this.enableGlare = true,
    this.borderRadius = 20.0,
    this.onTap,
    this.scaleOnHover = 1.035,
    this.glareColor,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<Tilt3DWidget> createState() => _Tilt3DWidgetState();
}

class _Tilt3DWidgetState extends State<Tilt3DWidget> {
  Offset _tilt = Offset.zero; // Normalizado de -1.0 a 1.0
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

  void _onHover(Offset localPos, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final dx = ((localPos.dx / size.width) - 0.5) * 2.0;
    final dy = ((localPos.dy / size.height) - 0.5) * 2.0;
    setState(() {
      _tilt = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
      _isHovered = true;
    });
  }

  void _onExit() {
    setState(() {
      _tilt = Offset.zero;
      _isHovered = false;
    });
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
      if (hasFocus) {
        _tilt = const Offset(0.0, -0.2); // Leve projeção 3D para cima
      } else {
        _tilt = Offset.zero;
      }
    });

    if (hasFocus && mounted) {
      // Auto-scroll suave para centralizar o elemento focado na tela
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
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

    return RepaintBoundary(
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        onFocusChange: _handleFocusChange,
        onKeyEvent: _handleKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return MouseRegion(
              onHover: (e) => _onHover(e.localPosition, size),
              onExit: (_) => _onExit(),
              cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                onTap: () {
                  _effectiveFocusNode.requestFocus();
                  widget.onTap?.call();
                },
                onPanUpdate: (e) => _onHover(e.localPosition, size),
                onPanEnd: (_) => _onExit(),
                onPanCancel: _onExit,
                child: TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(begin: Offset.zero, end: _tilt),
                  duration: Duration(milliseconds: active ? 140 : 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, tiltOffset, child) {
                    final tiltX = tiltOffset.dx;
                    final tiltY = tiltOffset.dy;

                    // Matriz de projeção 3D com perspectiva cônica
                    final matrix = Matrix4.identity()
                      ..setEntry(3, 2, widget.perspective)
                      ..rotateX(-tiltY * widget.maxTilt)
                      ..rotateY(tiltX * widget.maxTilt);

                    if (active) {
                      matrix.scaleByDouble(widget.scaleOnHover, widget.scaleOnHover, 1.0, 1.0);
                    }

                    return Transform(
                      transform: matrix,
                      alignment: FractionalOffset.center,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: _isFocused
                                        ? AppColors.accentCyan.withValues(alpha: 0.45)
                                        : Colors.cyanAccent.withValues(alpha: 0.22),
                                    blurRadius: _isFocused ? 32 : 28,
                                    spreadRadius: _isFocused ? 4 : 2,
                                    offset: Offset(tiltX * 8, tiltY * 8 + 6),
                                  ),
                                  const BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 24,
                                    offset: Offset(0, 12),
                                  ),
                                ]
                              : const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          child: Stack(
                            fit: StackFit.passthrough,
                            children: [
                              // Conteúdo principal
                              widget.child,

                              // Camada de Reflexo Especular Holográfico (Glare Shimmer)
                              if (widget.enableGlare && active)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(widget.borderRadius),
                                        gradient: LinearGradient(
                                          begin: Alignment(
                                            -tiltX * 1.5 - 0.5,
                                            -tiltY * 1.5 - 0.5,
                                          ),
                                          end: Alignment(
                                            -tiltX * 1.5 + 0.5,
                                            -tiltY * 1.5 + 0.5,
                                          ),
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            (widget.glareColor ?? Colors.cyanAccent).withValues(alpha: 0.15),
                                            Colors.white.withValues(alpha: 0.25),
                                            Colors.purpleAccent.withValues(alpha: 0.12),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Gamepad Focus Ring & Borda neon 3D
                              if (active)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(widget.borderRadius),
                                        border: Border.all(
                                          color: _isFocused
                                              ? AppColors.accentCyan
                                              : Colors.cyanAccent.withValues(alpha: 0.45),
                                          width: _isFocused ? 2.5 : 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
