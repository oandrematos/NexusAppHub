import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'animated_action_button.dart';
import 'cluster_image.dart';

class AppCardWidget extends StatelessWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final String? installedVersion;
  final double? downloadProgress;
  final String? downloadStatus;
  final bool isActionInProgress;
  final bool isInstalling;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback? onUninstall;

  const AppCardWidget({
    super.key,
    required this.app,
    required this.isInstalled,
    this.hasUpdate = false,
    this.installedVersion,
    this.downloadProgress,
    this.downloadStatus,
    this.isActionInProgress = false,
    this.isInstalling = false,
    required this.onTap,
    required this.onAction,
    this.onUninstall,
  });

  String _formatVersion(String? v) {
    if (v == null || v.isEmpty) return '';
    final clean = v.trim();
    return clean.startsWith('v') || clean.startsWith('V') ? clean : 'v$clean';
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);
    final sizeMb = app.getSizeMb(isAndroid);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: ClusterImage(
                        url: app.iconUrl,
                        fit: BoxFit.cover,
                        fallback: Center(
                          child: Text(app.icon, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'ATUALIZAÇÃO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    )
                  else if (isInstalled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'INSTALADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    )
                  else if (app.badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        app.badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  app.shortDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasUpdate) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatVersion(installedVersion),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 10, color: Colors.orangeAccent),
                            const SizedBox(width: 4),
                            Text(
                              _formatVersion(app.getVersion(isAndroid)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ] else if (isInstalled) ...[
                        Text(
                          _formatVersion(installedVersion ?? app.getVersion(isAndroid)),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Text(
                          _formatVersion(app.getVersion(isAndroid)),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        isAvailable && sizeMb != null ? '${sizeMb.toStringAsFixed(1)} MB' : '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isInstalled && onUninstall != null && !isActionInProgress && (downloadProgress == null || downloadProgress == 0)) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Desinstalar',
                          onPressed: onUninstall,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      AnimatedActionButton(
                        app: app,
                        isInstalled: isInstalled,
                        hasUpdate: hasUpdate,
                        isAvailable: isAvailable,
                        isActionInProgress: isActionInProgress || (downloadProgress != null && downloadProgress! > 0),
                        downloadProgress: downloadProgress,
                        downloadStatus: downloadStatus,
                        isInstalling: isInstalling,
                        isCompact: true,
                        height: 36,
                        onAction: isAvailable ? onAction : onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}