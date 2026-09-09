import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_view_model.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_card_widget.dart';
import '../../widgets/tilt_3d_widget.dart';
import '../details/app_detail_view.dart';
import '../../core/spatial_route.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  bool _filterOnlyUpdates = false;
  bool _isChecking = false;

  Future<void> _checkUpdates(HomeViewModel vm) async {
    setState(() => _isChecking = true);
    final hasAny = await vm.checkForUpdates();
    if (!mounted) return;
    setState(() => _isChecking = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              hasAny ? Icons.system_update_rounded : Icons.check_circle_outline,
              color: hasAny ? Colors.orangeAccent : Colors.greenAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              hasAny
                  ? '${vm.updateCount} atualização(ões) encontrada(s)!'
                  : 'Todos os aplicativos estão na versão mais recente!',
            ),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final installedApps = vm.apps.where((a) => vm.isInstalled(a.id)).toList();
    final appsWithUpdates = vm.appsWithUpdates;
    final displayApps = _filterOnlyUpdates ? appsWithUpdates : installedApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biblioteca & Atualizações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : () => _checkUpdates(vm),
              icon: _isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(_isChecking ? 'Verificando...' : 'Buscar Atualizações'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.accentCyan,
                elevation: 0,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Filtros / Abas no Topo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                FilterChip(
                  selected: !_filterOnlyUpdates,
                  label: Text('Todos Instalados (${installedApps.length})'),
                  labelStyle: TextStyle(
                    color: !_filterOnlyUpdates ? Colors.black : AppColors.textPrimary,
                    fontWeight: !_filterOnlyUpdates ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accentCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: !_filterOnlyUpdates ? AppColors.accentCyan : AppColors.border,
                    ),
                  ),
                  onSelected: (_) => setState(() => _filterOnlyUpdates = false),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  selected: _filterOnlyUpdates,
                  avatar: appsWithUpdates.isNotEmpty
                      ? const Icon(Icons.circle, color: Colors.orangeAccent, size: 10)
                      : null,
                  label: Text('Atualizações Disponíveis (${appsWithUpdates.length})'),
                  labelStyle: TextStyle(
                    color: _filterOnlyUpdates ? Colors.black : (appsWithUpdates.isNotEmpty ? Colors.orangeAccent : AppColors.textPrimary),
                    fontWeight: _filterOnlyUpdates ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _filterOnlyUpdates
                          ? Colors.orangeAccent
                          : (appsWithUpdates.isNotEmpty ? Colors.orangeAccent.withValues(alpha: 0.6) : AppColors.border),
                    ),
                  ),
                  onSelected: (_) => setState(() => _filterOnlyUpdates = true),
                ),
              ],
            ),
          ),

          // Banner de Ação de Atualizações Pendentes
          if (appsWithUpdates.isNotEmpty && !_filterOnlyUpdates)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Tilt3DWidget(
                borderRadius: 16,
                maxTilt: 0.03,
                scaleOnHover: 1.01,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.system_update_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appsWithUpdates.length} Atualização(ões) Pronta(s)!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Novas melhorias do ecossistema prontas para instalar.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: vm.isUpdatingAll ? null : () => vm.updateAll(context),
                        icon: vm.isUpdatingAll
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(vm.isUpdatingAll ? 'Atualizando...' : 'Atualizar Todos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEA580C),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Se estiver filtrando por atualizações e NÃO houver nenhuma
          if (_filterOnlyUpdates && appsWithUpdates.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.verified_outlined, size: 52, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tudo Atualizado!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Todos os seus aplicativos estão na versão mais recente.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _filterOnlyUpdates = false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Ver Todos os Instalados'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentCyan,
                        side: const BorderSide(color: AppColors.accentCyan),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (installedApps.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum aplicativo instalado no momento.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 220,
                  ),
                  itemCount: displayApps.length,
                  itemBuilder: (context, index) {
                    final app = displayApps[index];
                    return AppCardWidget(
                      app: app,
                      isInstalled: true,
                      hasUpdate: vm.hasUpdate(app.id),
                      installedVersion: vm.getInstalledVersion(app.id),
                      downloadProgress: vm.getProgress(app.id),
                      downloadStatus: vm.getStatus(app.id),
                      isActionInProgress: vm.isActionInProgress(app.id),
                      isInstalling: vm.isInstalling(app.id),
                      onTap: () {
                        Navigator.push(
                          context,
                          Spatial3DRoute(
                            page: AppDetailView(app: app),
                          ),
                        );
                      },
                      onAction: () => vm.handleAction(app, context),
                      onUninstall: () => vm.uninstallApp(app, context),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}