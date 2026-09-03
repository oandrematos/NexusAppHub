import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/app_version_service.dart';
import '../../core/app_colors.dart';
import '../home/home_view_model.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isCheckingUpdate = false;
  String? _checkStatus;

  Future<void> _manualCheckUpdate(HomeViewModel vm) async {
    setState(() {
      _isCheckingUpdate = true;
      _checkStatus = 'Consultando CDN global e servidores do cluster...';
    });

    await vm.loadData();

    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
      if (vm.hasStoreUpdate) {
        _checkStatus = 'Nova versão encontrada: v${vm.storeUpdateVersion}!';
      } else {
        _checkStatus = 'Você já está usando a versão mais recente!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isAndroid = Platform.isAndroid;
    final currentAppVersion = AppVersionService.currentVersion;
    final currentBuildNumber = AppVersionService.currentBuild.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header com Logo e Versão Oficial
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nexus App Hub',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Central & Launcher Oficial do Ecossistema',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Versão $currentAppVersion (Build $currentBuildNumber)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Seção: Atualizações do Sistema
          _buildSectionHeader('ATUALIZAÇÃO DO SISTEMA'),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        vm.hasStoreUpdate ? Icons.system_update_rounded : Icons.check_circle_outline,
                        color: vm.hasStoreUpdate ? Colors.orangeAccent : Colors.greenAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.hasStoreUpdate
                                  ? 'Atualização Disponível (v${vm.storeUpdateVersion})'
                                  : 'Nexus App Hub está atualizado',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _checkStatus ?? (vm.hasStoreUpdate
                                  ? 'Toque para instalar a nova versão oficial.'
                                  : 'Canal estável conectado aos servidores do cluster.'),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingUpdate
                              ? null
                              : () => _manualCheckUpdate(vm),
                          icon: _isCheckingUpdate
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(_isCheckingUpdate ? 'Verificando...' : 'Buscar Atualizações'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (vm.hasStoreUpdate) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => vm.updateStore(context),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Atualizar Agora'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Rede & Servidores
          _buildSectionHeader('CONECTIVIDADE DO CLUSTER'),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.cloud_outlined,
                  title: 'CDN Global GitHub',
                  subtitle: 'raw.githubusercontent.com (Ativo / Primário)',
                  trailing: const Icon(Icons.wifi, color: Colors.greenAccent, size: 20),
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile(
                  icon: Icons.dns_outlined,
                  title: 'Cluster S1 (Escritório / Nuvem)',
                  subtitle: '192.168.196.101 (ZeroTier) / 100.84.133.101',
                  trailing: const Icon(Icons.check, color: AppColors.textSecondary, size: 20),
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile(
                  icon: Icons.home_outlined,
                  title: 'Cluster S2 (Casa Real)',
                  subtitle: '192.168.0.246 (Wi-Fi Local)',
                  trailing: const Icon(Icons.check, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Dispositivo & Ambiente
          _buildSectionHeader('INFORMAÇÕES DO AMBIENTE'),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildInfoTile(
                  icon: isAndroid ? Icons.phone_android : Icons.computer,
                  title: 'Plataforma',
                  subtitle: isAndroid ? 'Android (ARM64)' : 'Windows (x64 Desktop)',
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  title: 'Identificador do Pacote',
                  subtitle: isAndroid ? 'com.antigravity.nexus_app_hub' : 'NexusAppHub.exe',
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile(
                  icon: Icons.shield_outlined,
                  title: 'Divisão de Engenharia',
                  subtitle: 'Agente Citadel (NexusAppHub Core Engine)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentCyan, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: trailing,
    );
  }
}