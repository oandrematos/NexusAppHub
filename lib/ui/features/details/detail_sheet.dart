import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/app_item.dart';
import '../../core/app_colors.dart';

class DetailSheet extends StatelessWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final String? installedVersion;
  final double? downloadProgress;
  final VoidCallback onAction;
  final VoidCallback? onUninstall;

  const DetailSheet({
    super.key,
    required this.app,
    required this.isInstalled,
    this.hasUpdate = false,
    this.installedVersion,
    this.downloadProgress,
    required this.onAction,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);
    final sizeMb = app.getSizeMb(isAndroid);
    final version = app.getVersion(isAndroid);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(app.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.categoryName,
                      style: const TextStyle(color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            app.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('TAMANHO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      sizeMb != null ? '${sizeMb.toStringAsFixed(1)} MB' : 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('VERSÃO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    if (hasUpdate && installedVersion != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'v$installedVersion',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 10, color: Colors.orangeAccent),
                          const SizedBox(width: 4),
                          Text(
                            version ?? 'v1.0.0',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ] else if (isInstalled && installedVersion != null) ...[
                      Text(
                        'v$installedVersion',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                      ),
                    ] else ...[
                      Text(
                        version ?? 'v1.0.0',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                Column(
                  children: [
                    const Text('PLATAFORMA', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      isAndroid ? 'Android' : 'Windows x64',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isInstalled && onUninstall != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUpdate ? Colors.orangeAccent : AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        hasUpdate ? 'ATUALIZAR' : 'ABRIR',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onUninstall,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'DESINSTALAR',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isAvailable ? onAction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasUpdate
                      ? Colors.orangeAccent
                      : (isInstalled ? AppColors.surface : AppColors.accentCyan),
                  foregroundColor: (hasUpdate || !isInstalled) ? Colors.black : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  app.getActionText(isAndroid, isInstalled, hasUpdate: hasUpdate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}