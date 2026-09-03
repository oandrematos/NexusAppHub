import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_item.dart';
import '../../core/app_colors.dart';
import '../home/home_view_model.dart';
import '../../widgets/cluster_image.dart';

class AppDetailView extends StatelessWidget {
  final AppItem app;

  const AppDetailView({
    super.key,
    required this.app,
  });

  String _formatVersion(String? v) {
    if (v == null || v.isEmpty) return 'v1.0.0';
    String clean = v.trim();
    clean = clean.replaceAll(RegExp(r'^[a-zA-Z\s]+'), '');
    if (clean.isEmpty) return 'v1.0.0';
    return 'v$clean';
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);
    final sizeMb = app.getSizeMb(isAndroid);
    final version = app.getVersion(isAndroid);

    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        final isInstalled = vm.isInstalled(app.id);
        final hasUpdate = vm.hasUpdate(app.id);
        final installedVersion = vm.getInstalledVersion(app.id);
        final downloadProgress = vm.getProgress(app.id);
        final isDownloading = downloadProgress != null && downloadProgress > 0 && downloadProgress < 1.0;

        final hasBanner = app.banner != null && app.banner!.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: hasBanner ? 280.0 : 160.0,
                pinned: true,
                backgroundColor: AppColors.cardBg,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Voltar',
                ),
                actions: [
                  if (isInstalled && !app.id.contains('nexus_app_hub'))
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Desinstalar aplicativo',
                      onPressed: () => _confirmUninstall(context, vm),
                    ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasBanner)
                        ClusterImage(
                          url: app.banner,
                          fit: BoxFit.cover,
                          fallback: _buildFallbackHeader(),
                        )
                      else
                        _buildFallbackHeader(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.6),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: ClusterImage(
                                    url: app.iconUrl,
                                    fit: BoxFit.cover,
                                    fallback: Center(
                                      child: Text(app.icon, style: const TextStyle(fontSize: 40)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.title.isNotEmpty ? app.title : app.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          app.categoryName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.accentCyan,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (hasUpdate)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orangeAccent.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                                            ),
                                            child: const Text(
                                              'ATUALIZAÇÃO DISPONÍVEL',
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
                                    const SizedBox(height: 8),
                                    Text(
                                      app.shortDescription,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (isDownloading) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Baixando e instalando...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${(downloadProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: downloadProgress,
                                    backgroundColor: AppColors.background,
                                    color: AppColors.accentCyan,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          Row(
                            children: [
                              Expanded(
                                flex: isInstalled && !app.id.contains('nexus_app_hub') ? 3 : 1,
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: (isAvailable && !isDownloading) ? () => vm.handleAction(app, context) : null,
                                    icon: Icon(
                                      isInstalled
                                          ? (hasUpdate ? Icons.system_update_alt : Icons.play_arrow_rounded)
                                          : Icons.download_rounded,
                                      size: 24,
                                    ),
                                    label: Text(
                                      app.getActionText(isAndroid, isInstalled, hasUpdate: hasUpdate),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasUpdate
                                          ? Colors.orangeAccent
                                          : (isInstalled ? AppColors.surface : AppColors.accentCyan),
                                      foregroundColor: (hasUpdate || !isInstalled) ? Colors.black : AppColors.textPrimary,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: isInstalled && !hasUpdate
                                            ? const BorderSide(color: AppColors.border)
                                            : BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isInstalled && !app.id.contains('nexus_app_hub')) ...[
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: isDownloading ? null : () => _confirmUninstall(context, vm),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                    label: const Text(
                                      'Desinstalar',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Gestão de Fonte de Instalação e Atualizações
                          if (!isAndroid && app.windows != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.source_outlined, size: 20, color: AppColors.accentCyan),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Fonte de Instalação:',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: vm.getAppSource(app.id),
                                        dropdownColor: AppColors.surface,
                                        underline: const SizedBox(),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                        items: [
                                          const DropdownMenuItem(
                                            value: 'nexus',
                                            child: Text('Cluster Nexus (Oficial)'),
                                          ),
                                          if (app.windows?.wingetId != null)
                                            DropdownMenuItem(
                                              value: 'winget',
                                              child: Text('Winget (${app.windows!.wingetId})'),
                                            ),
                                          if (app.windows?.chocoId != null)
                                            DropdownMenuItem(
                                              value: 'choco',
                                              child: Text('Chocolatey (${app.windows!.chocoId})'),
                                            ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) vm.setAppSource(app.id, val);
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, color: AppColors.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              vm.isUpdateIgnored(app.id) ? Icons.do_not_disturb_on_rounded : Icons.system_update_alt_rounded,
                                              size: 20,
                                              color: vm.isUpdateIgnored(app.id) ? AppColors.accentCyan : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Ignorar atualizações deste app',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: vm.isUpdateIgnored(app.id) ? AppColors.accentCyan : AppColors.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    vm.isUpdateIgnored(app.id)
                                                        ? 'Atualizações estão ignoradas (não serão mostradas)'
                                                        : 'Exibir avisos quando houver nova versão',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: vm.isUpdateIgnored(app.id),
                                        activeThumbColor: AppColors.accentCyan,
                                        onChanged: (_) => vm.toggleIgnoreUpdate(app.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSpecItem(
                                  label: 'TAMANHO',
                                  value: isAvailable && sizeMb != null ? '${sizeMb.toStringAsFixed(1)} MB' : 'N/A',
                                  icon: Icons.data_usage_outlined,
                                ),
                                _buildDivider(),
                                _buildSpecItem(
                                  label: 'VERSÃO ATUAL',
                                  value: _formatVersion(isInstalled ? (installedVersion ?? version) : version),
                                  subValue: hasUpdate ? 'Nova: ${_formatVersion(version)}' : null,
                                  icon: Icons.info_outline,
                                  isHighlight: hasUpdate,
                                ),
                                _buildDivider(),
                                _buildSpecItem(
                                  label: 'PLATAFORMA',
                                  value: isAndroid ? 'Android' : 'Windows x64',
                                  icon: isAndroid ? Icons.android : Icons.desktop_windows,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text(
                            'Sobre o Aplicativo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              app.description.isNotEmpty ? app.description : app.shortDescription,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (app.latestChangelog != null && app.latestChangelog!.isNotEmpty) ...[
                            const Row(
                              children: [
                                Icon(Icons.rocket_launch_outlined, color: AppColors.accentCyan, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Novidades desta versão',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: app.latestChangelog!.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppColors.accentCyan, fontSize: 16)),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          if (app.screenshots != null && app.screenshots!.isNotEmpty) ...[
                            const Text(
                              'Capturas de Tela',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: app.screenshots!.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, idx) {
                                  final imgUrl = app.screenshots![idx];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClusterImage(
                                        url: imgUrl,
                                        fit: BoxFit.cover,
                                        fallback: Container(
                                          width: 320,
                                          color: AppColors.surface,
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.cardBg,
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Text(app.icon, style: const TextStyle(fontSize: 100)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isHighlight ? Colors.orangeAccent : AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isHighlight ? Colors.orangeAccent : AppColors.textPrimary,
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ],
    );
  }

  void _confirmUninstall(BuildContext context, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desinstalar ${app.name}?',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tem certeza de que deseja remover este aplicativo do seu dispositivo?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              vm.uninstallApp(app, context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Desinstalar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}