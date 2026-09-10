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
  final double liftOnHover;
  final Color? glareColor;
  final FocusNode? focusNode;
  final bool autofocus;

  const Tilt3DWidget({
    super.key,
    required this.child,
    this.maxTilt = 0.18,
    this.perspective = 0.0014,
    this.enableGlare = false,
    this.borderRadius = 18.0,
    this.onTap,
    this.scaleOnHover = 1.09,
    this.liftOnHover = -16.0,
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

  late final AnimationController _animController;
  late final Animation<double> _anim;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
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
      if (!_isHovered) {
        _isHovered = true;
        _animController.forward();
      }
    });
  }

  void _onExit() {
    if (_isHovered) {
      setState(() {
        _tilt = Offset.zero;
        _isHovered = false;
        _animController.reverse();
      });
    }
  }

  void _handleFocusChange(bool hasFocus) {
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
        _tilt = hasFocus ? const Offset(0.0, -0.20) : Offset.zero;
        if (hasFocus) {
          _animController.forward();
        } else if (!_isHovered) {
          _animController.reverse();
        }
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
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final progress = _anim.value;

              // Em repouso total, renderiza com zero matrizes
              if (progress == 0.0 && !_isFocused) {
                return widget.child;
              }

              final tiltX = _tilt.dx * progress;
              final tiltY = _tilt.dy * progress;
              final currentScale = 1.0 + ((widget.scaleOnHover - 1.0) * progress);
              final currentLift = widget.liftOnHover * progress;

              final matrix = Matrix4.identity()
                ..setEntry(3, 2, widget.perspective)
                ..translateByDouble(tiltX * 12.0, currentLift + (tiltY * 8.0), 0.0, 1.0)
                ..rotateX(-tiltY * widget.maxTilt)
                ..rotateY(tiltX * widget.maxTilt)
                ..scaleByDouble(currentScale, currentScale, 1.0, 1.0);

              return Transform(
                transform: matrix,
                alignment: FractionalOffset.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: [
                      // Brilho Neon Ciano de Profundidade
                      BoxShadow(
                        color: _isFocused
                            ? AppColors.accentCyan.withValues(alpha: 0.65)
                            : AppColors.accentCyan.withValues(alpha: 0.38 * progress),
                        blurRadius: 16.0 + (24.0 * progress),
                        spreadRadius: 1.0 + (3.0 * progress),
                        offset: Offset(tiltX * 12, 6.0 + (14.0 * progress) + (tiltY * 10)),
                      ),
                      // Sombra Oclusiva Escura Volumétrica
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35 + (0.35 * progress)),
                        blurRadius: 12.0 + (22.0 * progress),
                        offset: Offset(0, 6.0 + (18.0 * progress)),
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
                                    width: 2.4,
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
      ),
    );
  }
}
