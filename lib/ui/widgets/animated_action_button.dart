import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';

class AnimatedActionButton extends StatefulWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final bool isAvailable;
  final bool isActionInProgress;
  final double? downloadProgress;
  final String? downloadStatus;
  final bool isInstalling;
  final VoidCallback? onAction;
  final double height;
  final double? width;
  final bool isCompact;
  final bool isHero;

  const AnimatedActionButton({
    super.key,
    required this.app,
    required this.isInstalled,
    this.hasUpdate = false,
    this.isAvailable = true,
    this.isActionInProgress = false,
    this.downloadProgress,
    this.downloadStatus,
    this.isInstalling = false,
    this.onAction,
    this.height = 50,
    this.width,
    this.isCompact = false,
    this.isHero = false,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _shimmerController;

  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 0.25, end: 0.70).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final initialProgress = (widget.downloadProgress ?? 0.0).clamp(0.0, 1.0);
    _currentProgress = initialProgress;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(begin: initialProgress, end: initialProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    final inProgress = widget.isActionInProgress || (initialProgress > 0);
    final isInst = widget.isInstalling ||
        (widget.downloadStatus != null &&
            widget.downloadStatus!.toLowerCase().contains('instalando'));
    if (inProgress || isInst) {
      _shimmerController.repeat();
      _pulseController.repeat(reverse: true);
    } else if (widget.hasUpdate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isInst = widget.isInstalling ||
        (widget.downloadStatus != null &&
            widget.downloadStatus!.toLowerCase().contains('instalando'));
    final target = isInst ? 1.0 : (widget.downloadProgress ?? 0.0).clamp(0.0, 1.0);

    if (target != _currentProgress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: target,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.forward(from: 0.0);
      _currentProgress = target;
    }

    final inProg = widget.isActionInProgress || ((widget.downloadProgress ?? 0) > 0);
    if (inProg || isInst) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else if (!_isHovered) {
      if (_shimmerController.isAnimating) _shimmerController.stop();
      if (!widget.hasUpdate && _pulseController.isAnimating) _pulseController.stop();
      if (widget.hasUpdate && !_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final progress = widget.downloadProgress;
    final inProgress = widget.isActionInProgress || (progress != null && progress > 0);
    final installing = widget.isInstalling ||
        (widget.downloadStatus != null &&
            widget.downloadStatus!.toLowerCase().contains('instalando'));

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: (inProgress || installing)
            ? _buildProgressPill(installing)
            : _buildInteractiveButton(isAndroid),
      ),
    );
  }

  Widget _buildProgressPill(bool isInstalling) {
    final radius = BorderRadius.circular(widget.isCompact ? 18 : 14);
    final accentColor = widget.hasUpdate ? Colors.orangeAccent : AppColors.accentCyan;
    final pillWidth = widget.width ?? (widget.isCompact ? 96.0 : 160.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _shimmerController, _progressAnimation]),
      builder: (context, _) {
        final animProgress = isInstalling ? 1.0 : _progressAnimation.value.clamp(0.02, 1.0);
        final shimmerPos = _shimmerController.value;

        return Container(
          key: const ValueKey('progress_pill'),
          height: widget.height,
          width: pillWidth,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _pulseAnimation.value * 0.40),
                blurRadius: 14,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // 1. Trilho Escuro com Profundidade
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF070B14),
                          Color(0xFF0F172A),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Barra de Progresso Fluida Interpolada a 120 FPS
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isInstalling
                              ? [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFF06B6D4),
                                ]
                              : (widget.hasUpdate
                                  ? [
                                      const Color(0xFFB45309),
                                      const Color(0xFFF59E0B),
                                    ]
                                  : [
                                      const Color(0xFF0369A1),
                                      const Color(0xFF00FFCC),
                                    ]),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Feixe Shimmer de Luz Contínuo (Wave a 120 FPS)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-2.0 + (shimmerPos * 4.0), -1.0),
                          end: Alignment(-1.0 + (shimmerPos * 4.0), 1.0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: isInstalling ? 0.35 : 0.30),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Friso de Luz Especular Superior 3D
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Borda Neon 3D
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.65),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                // 6. Tipografia e Telemetria Centralizada
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: widget.isCompact
                          ? _buildCompactProgressContent(animProgress, isInstalling, accentColor)
                          : _buildExpandedProgressContent(animProgress, isInstalling),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactProgressContent(double progress, bool isInstalling, Color accentColor) {
    if (isInstalling) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Instalando...',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      );
    }

    final pct = (progress * 100).toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedProgressContent(double progress, bool isInstalling) {
    if (isInstalling) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.downloadStatus ?? 'Instalando aplicativo...',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    final pct = (progress * 100).toInt();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            value: progress,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Baixando... $pct%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveButton(bool isAndroid) {
    if (!widget.isAvailable) {
      if (widget.app.platformsSupported.contains('linux') &&
          !widget.app.platformsSupported.contains(isAndroid ? 'android' : 'windows')) {
        return _buildLinuxButton();
      }
      return _buildUnavailableBadge(isAndroid);
    }

    final bool isInstalled = widget.isInstalled;
    final bool hasUpdate = widget.hasUpdate;
    final text = widget.app.getActionText(isAndroid, isInstalled, hasUpdate: hasUpdate);

    // Paleta Neon 3D
    Color bg;
    Color fg;
    IconData icon;
    Color glowColor;
    BorderSide border = BorderSide.none;

    if (hasUpdate) {
      bg = const Color(0xFFF59E0B);
      fg = Colors.black;
      glowColor = const Color(0xFFF59E0B);
      icon = Icons.system_update_alt_rounded;
    } else if (isInstalled) {
      bg = AppColors.surface;
      fg = AppColors.accentCyan;
      glowColor = AppColors.accentCyan;
      icon = Icons.play_arrow_rounded;
      border = const BorderSide(color: AppColors.accentCyan, width: 1.4);
    } else {
      bg = AppColors.accentCyan;
      fg = Colors.black;
      glowColor = AppColors.accentCyan;
      icon = Icons.download_rounded;
    }

    final radius = BorderRadius.circular(widget.isCompact ? 18 : 14);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (!_shimmerController.isAnimating) _shimmerController.repeat();
        if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        final inProgress = widget.isActionInProgress || ((widget.downloadProgress ?? 0) > 0);
        final isInst = widget.isInstalling ||
            (widget.downloadStatus != null &&
                widget.downloadStatus!.toLowerCase().contains('instalando'));
        if (!inProgress && !isInst) {
          if (_shimmerController.isAnimating) _shimmerController.stop();
          if (!widget.hasUpdate && _pulseController.isAnimating) _pulseController.stop();
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onAction,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _shimmerController]),
          builder: (context, child) {
            final shimmerPos = _shimmerController.value;

            // Matriz 3D com perspectiva tátil realista
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..translateByDouble(0.0, _isPressed ? 3.0 : (_isHovered ? -3.0 : 0.0), 0.0, 1.0);

            return AnimatedScale(
              scale: _isPressed ? 0.92 : (_isHovered ? 1.05 : 1.0),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              child: Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: Container(
                  key: const ValueKey('interactive_btn'),
                  height: widget.height,
                  width: widget.width ?? (widget.isCompact ? 96.0 : null),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 10 : 20,
                    vertical: widget.isCompact ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: radius,
                    border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: _isHovered
                              ? 0.55
                              : ((!isInstalled || hasUpdate) ? _pulseAnimation.value * 0.45 : 0.18),
                        ),
                        blurRadius: _isHovered ? 16 : 8,
                        spreadRadius: _isHovered ? 2 : 0,
                        offset: Offset(0, _isPressed ? 1 : (_isHovered ? 6 : 3)),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Feixe Holográfico Diagonal contínuo no Hover
                        if (_isHovered)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-2.0 + (shimmerPos * 4.0), -1.0),
                                    end: Alignment(-1.0 + (shimmerPos * 4.0), 1.0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.30),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Brilho Especular Superior 3D
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 1.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.4),
                                  Colors.white.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: widget.isCompact ? 16 : 20, color: fg),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: widget.isCompact ? 12 : 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLinuxButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accentCyan, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.15),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded, size: 14, color: AppColors.accentCyan),
              SizedBox(width: 4),
              Text(
                'Linux',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableBadge(bool isAndroid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isAndroid ? 'Apenas PC' : 'Apenas Celular',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}
