import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'cluster_image.dart';

class AppListTileWidget extends StatelessWidget {
  final AppItem app;
  final bool isInstalled;
  final bool hasUpdate;
  final bool isUpdateIgnored;
  final String? installedVersion;
  final double? downloadProgress;
  final String appSource;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback? onUninstall;
  final VoidCallback? onToggleIgnoreUpdate;
  final ValueChanged<String>? onSourceChanged;

  const AppListTileWidget({
    super.key,
    required this.app,
    required this.isInstalled,
    this.hasUpdate = false,
    this.isUpdateIgnored = false,
    this.installedVersion,
    this.downloadProgress,
    this.appSource = 'nexus',
    required this.onTap,
    required this.onAction,
    this.onUninstall,
    this.onToggleIgnoreUpdate,
    this.onSourceChanged,
  });

  String _formatVersion(String? v) {
    if (v == null || v.isEmpty) return '';
    String clean = v.trim();
    clean = clean.replaceAll(RegExp(r'^[a-zA-Z\s]+'), '');
    if (clean.isEmpty) return '';
    return 'v$clean';
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);
    final sizeMb = app.getSizeMb(isAndroid);
    final isDownloading = downloadProgress != null && downloadProgress! > 0 && downloadProgress! < 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.surface.withValues(alpha: 0.6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // Ícone M3E Squircle com Aura
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: ClusterImage(
                    url: app.iconUrl,
                    fit: BoxFit.cover,
                    fallback: Center(
                      child: Text(app.icon, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Informações do App
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUpdate) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orangeAccent, width: 0.8),
                            ),
                            child: const Text(
                              'ATUALIZAÇÃO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          app.categoryName,
                          style: const TextStyle(fontSize: 12, color: AppColors.accentCyan),
                        ),
                        if (sizeMb != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            '${sizeMb.toStringAsFixed(1)} MB',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                        if (isInstalled && installedVersion != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            _formatVersion(installedVersion),
                            style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
                          ),
                        ],
                        if (!isAndroid && appSource != 'nexus') ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            appSource.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: appSource == 'winget' ? AppColors.accentCyan : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Botão de Ação Estilo Pílula Play Store
              if (isDownloading)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: downloadProgress,
                        color: AppColors.accentCyan,
                        strokeWidth: 3,
                      ),
                      Text(
                        '${((downloadProgress ?? 0) * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (!isAvailable)
                Container(
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
                )
              else
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: hasUpdate
                        ? Colors.orangeAccent
                        : (isInstalled ? AppColors.surface : AppColors.accentCyan),
                    foregroundColor: hasUpdate
                        ? Colors.black
                        : (isInstalled ? AppColors.textPrimary : Colors.black),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    hasUpdate ? 'Atualizar' : (isInstalled ? 'Abrir' : 'Instalar'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),

              // Menu de Opções Rápido (Ignorar atualizações / Trocar Fonte)
              if (!isAndroid)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'ignore') {
                      onToggleIgnoreUpdate?.call();
                    } else if (val.startsWith('src_')) {
                      onSourceChanged?.call(val.replaceFirst('src_', ''));
                    } else if (val == 'uninstall') {
                      onUninstall?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'ignore',
                      child: Row(
                        children: [
                          Icon(
                            isUpdateIgnored ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                            size: 16,
                            color: isUpdateIgnored ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(isUpdateIgnored ? 'Ativar atualizações' : 'Ignorar atualizações'),
                        ],
                      ),
                    ),
                    if (app.windows?.wingetId != null || app.windows?.chocoId != null) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text('FONTE DE DOWNLOAD:', style: TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                      ),
                      PopupMenuItem(
                        value: 'src_nexus',
                        child: Row(
                          children: [
                            Icon(appSource == 'nexus' ? Icons.check_circle : Icons.circle_outlined, size: 16, color: AppColors.accentCyan),
                            const SizedBox(width: 8),
                            const Text('Cluster Nexus (Oficial)'),
                          ],
                        ),
                      ),
                      if (app.windows?.wingetId != null)
                        PopupMenuItem(
                          value: 'src_winget',
                          child: Row(
                            children: [
                              Icon(appSource == 'winget' ? Icons.check_circle : Icons.circle_outlined, size: 16, color: AppColors.accentCyan),
                              const SizedBox(width: 8),
                              const Text('Winget'),
                            ],
                          ),
                        ),
                      if (app.windows?.chocoId != null)
                        PopupMenuItem(
                          value: 'src_choco',
                          child: Row(
                            children: [
                              Icon(appSource == 'choco' ? Icons.check_circle : Icons.circle_outlined, size: 16, color: AppColors.accentCyan),
                              const SizedBox(width: 8),
                              const Text('Chocolatey'),
                            ],
                          ),
                        ),
                    ],
                    if (isInstalled && onUninstall != null && !app.id.contains('nexus_app_hub')) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'uninstall',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Desinstalar', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}