import 'package:flutter/material.dart';

/// Rota com transição tridimensional suave a 120 FPS.
/// Aplica aproximação espacial em Z (escala 0.92x -> 1.0x),
/// leve rotação de perspectiva no eixo Y e cross-fade contínuo.
class Spatial3DRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  Spatial3DRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnim = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return RepaintBoundary(
              child: AnimatedBuilder(
                animation: curvedAnim,
                builder: (context, _) {
                  final progress = curvedAnim.value;
                  final scale = 0.93 + (0.07 * progress);
                  final rotY = (1.0 - progress) * 0.06;
                  final opacity = progress.clamp(0.0, 1.0);

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(-rotY)
                    ..scaleByDouble(scale, scale, 1.0, 1.0);

                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
        );
}
