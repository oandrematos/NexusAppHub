import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';
import '../../core/app_colors.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/app_list_tile_widget.dart';
import '../../widgets/hero_carousel_widget.dart';
import '../../widgets/store_shelf_widget.dart';
import '../../widgets/game_card_widget.dart';
import '../details/app_detail_view.dart';
import 'package:nexus_app_hub/data/models/app_item.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<HomeViewModel>().loadData();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isSearching = vm.searchQuery.isNotEmpty || vm.selectedCategory != 'all' || vm.selectedPlatform != 'all';
    final isDesktop = MediaQuery.of(context).size.width >= 800 && !Platform.isAndroid;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => vm.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Cabeçalho de Busca e Categorias
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchBarWidget(
                      controller: _searchCtrl,
                      onChanged: (val) => vm.search(val),
                    ),
                    const SizedBox(height: 16),

                    // Alerta de Atualização da Loja
                    if (vm.hasStoreUpdate) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                    'Versão ${vm.storeUpdateVersion} pronta para atualização.',
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

                    // Seletor de Plataforma
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPlatformChip(vm, 'all', 'Todas as Plataformas', Icons.devices_rounded),
                          const SizedBox(width: 8),
                          _buildPlatformChip(vm, 'windows', 'Windows (PC)', Icons.desktop_windows_rounded),
                          const SizedBox(width: 8),
                          _buildPlatformChip(vm, 'android', 'Android (Celular)', Icons.phone_android_rounded),
                          const SizedBox(width: 8),
                          _buildPlatformChip(vm, 'linux', 'Linux (Nós & HUD)', Icons.terminal_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chips de Categoria Deslizantes
                    SizedBox(
                      height: 38,
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
                              fontSize: 12,
                            ),
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.accentCyan,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
            else if (isSearching)
              // MODO DE BUSCA / FILTRO ESPECÍFICO: Grade/Lista Fluida
              _buildSearchOrCategoryResults(vm, isDesktop)
            else
              // MODO VITRINE PRINCIPAL: Prateleiras e Carrosséis Estilo MS Store & Play Store
              _buildStorefrontSections(vm, isDesktop),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStorefrontSections(HomeViewModel vm, bool isDesktop) {
    final all = vm.apps;

    // Categorias de Apps
    final ecosystemApps = all.where((a) =>
      a.id == 'nexus_dashboard' || a.id == 'wappchat' || a.id == 'threadsdl' || a.id == 'alfred' || a.id == 'smirror' || a.id == 'nexus_app_hub'
    ).toList();

    final gameApps = all.where((a) => a.category == 'games').toList();
    final toolApps = all.where((a) => a.category == 'productivity' || a.category == 'media' || a.category == 'system').toList();
    final linuxApps = all.where((a) => a.platformsSupported.contains('linux') || a.linux != null).toList();
    final featuredForCarousel = vm.featuredApps.isNotEmpty ? vm.featuredApps : all.take(5).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        // 1. Hero Showcase Carousel
        HeroCarouselWidget(
          apps: featuredForCarousel,
          isInstalled: (id) => vm.isInstalled(id),
          hasUpdate: (id) => vm.hasUpdate(id),
          onTap: (app) => _openDetails(context, app, vm),
          onAction: (app) => vm.handleAction(app, context),
        ),
        const SizedBox(height: 28),

        // 2. Prateleira "Jogos & Arcade" (Carrossel Horizontal com Banner)
        if (gameApps.isNotEmpty) ...[
          StoreShelfWidget(
            title: '🎮 Jogos & Arcade',
            subtitle: 'Títulos originais do ecossistema Antigravity',
            height: 190,
            itemCount: gameApps.length,
            itemBuilder: (context, index) {
              final game = gameApps[index];
              return GameCardWidget(
                app: game,
                isInstalled: vm.isInstalled(game.id),
                hasUpdate: vm.hasUpdate(game.id),
                onTap: () => _openDetails(context, game, vm),
                onAction: () => vm.handleAction(game, context),
              );
            },
          ),
          const SizedBox(height: 28),
        ],

        // 3. Prateleira "Aplicativos Essenciais do Ecossistema" (Estilo Play Store Tiles)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚡ Essenciais do Ecossistema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Centrais de monitoramento, automação e mensageria unificada',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoCols = constraints.maxWidth >= 700;
                  if (useTwoCols) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: ecosystemApps.map((app) {
                        return SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildTile(vm, app),
                        );
                      }).toList(),
                    );
                  }

                  return Column(
                    children: ecosystemApps.map((app) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildTile(vm, app),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 4. Seção "Ferramentas & Utilitários"
        if (toolApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛠️ Ferramentas & Produtividade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Utilitários essenciais e ferramentas de rede curadas',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useTwoCols = constraints.maxWidth >= 700;
                    if (useTwoCols) {
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: toolApps.map((app) {
                          return SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: _buildTile(vm, app),
                          );
                        }).toList(),
                      );
                    }

                    return Column(
                      children: toolApps.map((app) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildTile(vm, app),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        // 5. Seção "Cluster Linux & Telemetria"
        if (linuxApps.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: AppColors.accentCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cluster Linux & Telemetria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'HUDs de terminal AMOLED, TUIs e ferramentas de monitoramento para nós de rede',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useTwoCols = constraints.maxWidth >= 700;
                    if (useTwoCols) {
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: linuxApps.map((app) {
                          return SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: _buildTile(vm, app),
                          );
                        }).toList(),
                      );
                    }

                    return Column(
                      children: linuxApps.map((app) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildTile(vm, app),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildSearchOrCategoryResults(HomeViewModel vm, bool isDesktop) {
    if (vm.apps.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Nenhum aplicativo encontrado.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          if (width < 650) {
            // Em smartphones ou janelas estreitas: Lista de tiles compactos
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = vm.apps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildTile(vm, app),
                  );
                },
                childCount: vm.apps.length,
              ),
            );
          }

          // Em telas médias e grandes: Grade adaptativa fluida
          int crossAxisCount = width >= 1200 ? 3 : 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 88,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = vm.apps[index];
                return _buildTile(vm, app);
              },
              childCount: vm.apps.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(HomeViewModel vm, AppItem app) {
    return AppListTileWidget(
      app: app,
      isInstalled: vm.isInstalled(app.id),
      hasUpdate: vm.hasUpdate(app.id),
      isUpdateIgnored: vm.isUpdateIgnored(app.id),
      appSource: vm.getAppSource(app.id),
      installedVersion: vm.getInstalledVersion(app.id),
      downloadProgress: vm.getProgress(app.id),
      onTap: () => _openDetails(context, app, vm),
      onAction: () => vm.handleAction(app, context),
      onUninstall: () => vm.uninstallApp(app, context),
      onToggleIgnoreUpdate: () => vm.toggleIgnoreUpdate(app.id),
      onSourceChanged: (src) => vm.setAppSource(app.id, src),
    );
  }

  Widget _buildPlatformChip(HomeViewModel vm, String id, String label, IconData icon) {
    final isSelected = vm.selectedPlatform == id;
    return InkWell(
      onTap: () => vm.setPlatform(id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, AppItem app, HomeViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppDetailView(app: app),
      ),
    );
  }
}