import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'animated_action_button.dart';
import 'cluster_image.dart';
import 'tilt_3d_widget.dart';

class HeroSpotlight extends StatelessWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final double? downloadProgress;
  final String? downloadStatus;
  final bool isActionInProgress;
  final bool isInstalling;
  final VoidCallback onTap;
  final VoidCallback onInstall;

  const HeroSpotlight({
    super.key,
    required this.app,
    this.isInstalled = false,
    this.hasUpdate = false,
    this.downloadProgress,
    this.downloadStatus,
    this.isActionInProgress = false,
    this.isInstalling = false,
    required this.onTap,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);

    return Tilt3DWidget(
      borderRadius: 20,
      maxTilt: 0.05,
      scaleOnHover: 1.015,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentCyan, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DESTAQUE DA SEMANA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: ClusterImage(
                      url: app.iconUrl,
                      fit: BoxFit.cover,
                      fallback: Center(
                        child: Text(app.icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              app.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              app.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AnimatedActionButton(
                  app: app,
                  isInstalled: isInstalled,
                  hasUpdate: hasUpdate,
                  isAvailable: isAvailable,
                  downloadProgress: downloadProgress,
                  downloadStatus: downloadStatus,
                  isActionInProgress: isActionInProgress,
                  isInstalling: isInstalling,
                  height: 46,
                  onAction: onInstall,
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ver Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}