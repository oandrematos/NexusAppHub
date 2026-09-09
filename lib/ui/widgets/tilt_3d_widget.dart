import 'package:flutter/material.dart';

/// Widget 3D de alta performance projetado para rodar a 120 FPS cravados.
/// Aplica perspectiva tridimensional com rotação nos eixos X e Y baseada na
/// interação do usuário (mouse no Desktop ou toque no Mobile) e camada de
/// reflexo especular holográfico dinâmico (TCG Foil Shimmer).
class Tilt3DWidget extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final double perspective;
  final bool enableGlare;
  final double borderRadius;
  final VoidCallback? onTap;
  final double scaleOnHover;
  final Color? glareColor;

  const Tilt3DWidget({
    super.key,
    required this.child,
    this.maxTilt = 0.16, // ~9 a 10 graus de inclinação máxima
    this.perspective = 0.0014, // Fator de perspectiva 3D realista
    this.enableGlare = true,
    this.borderRadius = 20.0,
    this.onTap,
    this.scaleOnHover = 1.025,
    this.glareColor,
  });

  @override
  State<Tilt3DWidget> createState() => _Tilt3DWidgetState();
}

class _Tilt3DWidgetState extends State<Tilt3DWidget> {
  Offset _tilt = Offset.zero; // Normalizado de -1.0 a 1.0
  bool _isHovered = false;

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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return MouseRegion(
            onHover: (e) => _onHover(e.localPosition, size),
            onExit: (_) => _onExit(),
            cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanUpdate: (e) => _onHover(e.localPosition, size),
              onPanEnd: (_) => _onExit(),
              onPanCancel: _onExit,
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset.zero, end: _tilt),
                duration: Duration(milliseconds: _isHovered ? 120 : 350),
                curve: Curves.easeOutCubic,
                builder: (context, tiltOffset, child) {
                  final tiltX = tiltOffset.dx;
                  final tiltY = tiltOffset.dy;

                  // Matriz de projeção 3D com perspectiva cônica
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, widget.perspective)
                    ..rotateX(-tiltY * widget.maxTilt)
                    ..rotateY(tiltX * widget.maxTilt);

                  if (_isHovered) {
                    matrix.scaleByDouble(widget.scaleOnHover, widget.scaleOnHover, 1.0, 1.0);
                  }

                  return Transform(
                    transform: matrix,
                    alignment: FractionalOffset.center,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.22),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: Offset(tiltX * 8, tiltY * 8 + 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
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
                            if (widget.enableGlare && _isHovered)
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
                                          (widget.glareColor ?? Colors.cyanAccent).withValues(alpha: 0.12),
                                          Colors.white.withValues(alpha: 0.22),
                                          Colors.purpleAccent.withValues(alpha: 0.10),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Borda chanfrada de luz neon 3D
                            if (_isHovered)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(widget.borderRadius),
                                      border: Border.all(
                                        color: Colors.cyanAccent.withValues(alpha: 0.45),
                                        width: 1.2,
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
    );
  }
}
