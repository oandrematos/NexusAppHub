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
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

    final double clampedProgress =
        installing ? 1.0 : (progress != null ? progress.clamp(0.02, 1.0) : 0.0);

    // Estado 1: Em Progresso (Baixando ou Instalando) -> Transforma no botão barra de progresso!
    if (inProgress || installing) {
      return _buildProgressPill(clampedProgress, installing);
    }

    // Estado 2: Botão Normal Interativo com micro-animação de toque
    return _buildInteractiveButton(isAndroid);
  }

  Widget _buildProgressPill(double progress, bool isInstalling) {
    final radius = BorderRadius.circular(widget.isCompact ? 18 : 14);
    final accentColor = widget.hasUpdate ? Colors.orangeAccent : AppColors.accentCyan;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _pulseAnimation.value * 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // 1. Fundo Trilho Escuro
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),

                // 2. Barra de Progresso Fluida com Gradiente
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isInstalling ? 1.0 : progress,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isInstalling
                              ? [
                                  AppColors.accentPurple.withValues(alpha: 0.8),
                                  AppColors.accentCyan.withValues(alpha: 0.8),
                                ]
                              : (widget.hasUpdate
                                  ? [
                                      const Color(0xFFD97706),
                                      const Color(0xFFF59E0B),
                                    ]
                                  : [
                                      const Color(0xFF0891B2),
                                      const Color(0xFF06B6D4),
                                    ]),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Efeito de Shimmer / Linha de Brilho Superior
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),

                // 4. Borda Tecnológica
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                // 5. Conteúdo e Tipografia Central
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: widget.isCompact
                          ? _buildCompactProgressContent(progress, isInstalling, accentColor)
                          : _buildExpandedProgressContent(progress, isInstalling),
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
          SizedBox(width: 5),
          Text(
            'Instalando',
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
            value: progress > 0 ? progress : null,
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$pct%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildExpandedProgressContent(double progress, bool isInstalling) {
    if (isInstalling) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Instalando aplicativo...',
            style: TextStyle(
              fontSize: 14,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          'Baixando... $pct%',
          style: const TextStyle(
            fontSize: 14,
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

    // Cores e Estilo
    Color bg;
    Color fg;
    IconData icon;
    BorderSide border = BorderSide.none;

    if (hasUpdate) {
      bg = const Color(0xFFF59E0B);
      fg = Colors.black;
      icon = Icons.system_update_alt_rounded;
    } else if (isInstalled) {
      bg = AppColors.surface;
      fg = AppColors.accentCyan;
      icon = Icons.play_arrow_rounded;
      border = const BorderSide(color: AppColors.accentCyan, width: 1.2);
    } else {
      bg = AppColors.accentCyan;
      fg = Colors.black;
      icon = Icons.download_rounded;
    }

    final radius = BorderRadius.circular(widget.isCompact ? 18 : 14);

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAction,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            width: widget.width,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 14 : 20,
              vertical: widget.isCompact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
              boxShadow: [
                if (!isInstalled || hasUpdate)
                  BoxShadow(
                    color: bg.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
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
        ),
      ),
    );
  }

  Widget _buildLinuxButton() {
    return InkWell(
      onTap: widget.onAction,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentCyan, width: 0.8),
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
