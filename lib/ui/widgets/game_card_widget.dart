import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'animated_action_button.dart';
import 'cluster_image.dart';
import 'tilt_3d_widget.dart';

class GameCardWidget extends StatelessWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final double? downloadProgress;
  final String? downloadStatus;
  final bool isActionInProgress;
  final bool isInstalling;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const GameCardWidget({
    super.key,
    required this.app,
    required this.isInstalled,
    this.hasUpdate = false,
    this.downloadProgress,
    this.downloadStatus,
    this.isActionInProgress = false,
    this.isInstalling = false,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final sizeMb = app.getSizeMb(isAndroid);
    final isAvailable = app.isAvailableOn(isAndroid);

    return Tilt3DWidget(
      borderRadius: 18,
      maxTilt: 0.08,
      scaleOnHover: 1.03,
      onTap: onTap,
      child: Container(
        width: 255,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner / Card 3D Superior
              SizedBox(
                height: 112,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClusterImage(
                      url: app.bannerCard ?? app.coverCard ?? app.banner ?? app.iconUrl,
                      fit: BoxFit.cover,
                      fallback: Container(color: AppColors.surface),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    // Badge Categoria & Gamepad
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (app.gamepad) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.sports_esports_rounded, size: 12, color: Colors.white),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              app.badge.isNotEmpty ? app.badge : 'ARCADE',
                              style: const TextStyle(fontSize: 9, color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Informações Inferiores e Botão 3D
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: ClusterImage(
                          url: app.iconUrl,
                          fit: BoxFit.cover,
                          fallback: Center(child: Text(app.icon, style: const TextStyle(fontSize: 18))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sizeMb != null ? '${sizeMb.toStringAsFixed(1)} MB' : 'App',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedActionButton(
                      app: app,
                      isInstalled: isInstalled,
                      hasUpdate: hasUpdate,
                      isAvailable: isAvailable,
                      downloadProgress: downloadProgress,
                      downloadStatus: downloadStatus,
                      isActionInProgress: isActionInProgress,
                      isInstalling: isInstalling,
                      isCompact: true,
                      height: 32,
                      width: 96,
                      onAction: onAction,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}