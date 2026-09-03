import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';
import '../../core/app_colors.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/app_card_widget.dart';
import '../../widgets/hero_spotlight.dart';
import '../details/detail_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Todos'},
    {'id': 'games', 'name': 'Jogos & Arcade'},
    {'id': 'system', 'name': 'Sistema & Cluster'},
    {'id': 'social', 'name': 'Comunicação'},
    {'id': 'productivity', 'name': 'Produtividade & IA'},
    {'id': 'media', 'name': 'Mídia & Ferramentas'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBarWidget(
                    controller: _searchCtrl,
                    onChanged: (val) => vm.search(val),
                  ),
                  const SizedBox(height: 20),
                  if (vm.hasStoreUpdate) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.system_update_rounded, color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nova versão da Loja Disponível!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  'Versão ${vm.storeUpdateVersion} pronta para atualização automática.',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => vm.updateStore(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Atualizar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (vm.featuredApps.isNotEmpty)
                    HeroSpotlight(
                      app: vm.featuredApps.first,
                      isInstalled: vm.isInstalled(vm.featuredApps.first.id),
                      hasUpdate: vm.hasUpdate(vm.featuredApps.first.id),
                      onTap: () => _openDetails(context, vm.featuredApps.first, vm),
                      onInstall: () => vm.handleAction(vm.featuredApps.first, context),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = vm.selectedCategory == cat['id'];
                        return FilterChip(
                          selected: isSelected,
                          label: Text(cat['name']!),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.accentCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.accentCyan : AppColors.border,
                            ),
                          ),
                          onSelected: (_) => vm.setCategory(cat['id']!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentCyan),
              ),
            )
          else if (vm.apps.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Nenhum aplicativo encontrado.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  int crossAxisCount = 1;
                  if (width >= 1200) {
                    crossAxisCount = 4;
                  } else if (width >= 800) {
                    crossAxisCount = 3;
                  } else if (width >= 500) {
                    crossAxisCount = 2;
                  }

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 220,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final app = vm.apps[index];
                        return AppCardWidget(
                          app: app,
                          isInstalled: vm.isInstalled(app.id),
                          hasUpdate: vm.hasUpdate(app.id),
                          downloadProgress: vm.getProgress(app.id),
                          onTap: () => _openDetails(context, app, vm),
                          onAction: () => vm.handleAction(app, context),
                          onUninstall: () => vm.uninstallApp(app, context),
                        );
                      },
                      childCount: vm.apps.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, dynamic app, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailSheet(
        app: app,
        isInstalled: vm.isInstalled(app.id),
        hasUpdate: vm.hasUpdate(app.id),
        downloadProgress: vm.getProgress(app.id),
        onAction: () {
          Navigator.pop(context);
          vm.handleAction(app, context);
        },
        onUninstall: () {
          Navigator.pop(context);
          vm.uninstallApp(app, context);
        },
      ),
    );
  }
}