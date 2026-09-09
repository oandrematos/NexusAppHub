import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/app_item.dart';
import '../../../data/services/gamepad_service.dart';
import '../../core/app_colors.dart';
import '../../core/spatial_route.dart';
import '../../widgets/cluster_image.dart';
import '../../widgets/gamepad_hud_bar.dart';
import '../../widgets/tilt_3d_widget.dart';
import '../details/app_detail_view.dart';
import '../home/home_view_model.dart';

class BigPictureView extends StatefulWidget {
  const BigPictureView({super.key});

  @override
  State<BigPictureView> createState() => _BigPictureViewState();
}

class _BigPictureViewState extends State<BigPictureView> {
  int _selectedCategoryIndex = 0;
  AppItem? _focusedApp;
  late Timer _clockTimer;
  String _currentTime = '';
  final ScrollController _shelfController = ScrollController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Todos os Apps'},
    {'id': 'games', 'name': 'Jogos & Arcade'},
    {'id': 'media', 'name': 'Mídia & Ferramentas'},
    {'id': 'system', 'name': 'Sistema & Nós'},
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());

    // Conecta atalho de retorno ao GamepadService
    GamepadService().onBackAction = () {
      if (mounted) Navigator.of(context).maybePop();
    };
    GamepadService().onTabNext = () => _changeCategory(1);
    GamepadService().onTabPrevious = () => _changeCategory(-1);
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  void _changeCategory(int delta) {
    setState(() {
      final newIdx = (_selectedCategoryIndex + delta) % _categories.length;
      _selectedCategoryIndex = newIdx < 0 ? _categories.length - 1 : newIdx;
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _shelfController.dispose();
    GamepadService().onBackAction = null;
    GamepadService().onTabNext = null;
    GamepadService().onTabPrevious = null;
    super.dispose();
  }

  List<AppItem> _getFilteredApps(List<AppItem> allApps) {
    final catId = _categories[_selectedCategoryIndex]['id']!;
    if (catId == 'all') return allApps;
    return allApps.where((a) => a.category == catId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isAndroid = Platform.isAndroid;
    final availableApps = vm.apps.where((a) => a.isAvailableOn(isAndroid)).toList();
    final currentList = _getFilteredApps(availableApps);

    // Seleciona o primeiro app focado por padrão
    final activeApp = _focusedApp ?? (currentList.isNotEmpty ? currentList.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo dinâmico com iluminação ambiente e desfoque cinematográfico
          if (activeApp != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: ClusterImage(
                    url: activeApp.bannerCard ?? activeApp.banner ?? activeApp.coverCard ?? activeApp.iconUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF090D16).withValues(alpha: 0.85),
                  const Color(0xFF05080E).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),

          // Estrutura Principal
          SafeArea(
            child: Column(
              children: [
                // Header Topo Estilo Console
                _buildTopBar(),

                // Hero Showcase Superior do App Focado
                Expanded(
                  flex: 5,
                  child: activeApp != null
                      ? _buildHeroShowcase(activeApp, vm)
                      : const Center(
                          child: CircularProgressIndicator(color: AppColors.accentCyan),
                        ),
                ),

                // Carrossel de Posters Verticais 3D
                Expanded(
                  flex: 6,
                  child: _buildPostersCarousel(currentList, vm),
                ),

                // Barra HUD Inferior com Botões do Controle
                const GamepadHudBar(
                  prompts: [
                    GamepadPromptItem(assetName: 'xbox_a.png', label: 'Jogar / Instalar'),
                    GamepadPromptItem(assetName: 'xbox_x.png', label: 'Ver Detalhes'),
                    GamepadPromptItem(assetName: 'xbox_lb.png', label: 'Aba Anterior'),
                    GamepadPromptItem(assetName: 'xbox_rb.png', label: 'Próxima Aba'),
                    GamepadPromptItem(assetName: 'xbox_b.png', label: 'Sair do Big Picture'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
      child: Row(
        children: [
          // Logo Big Picture
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.sports_esports, color: AppColors.accentCyan, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXUS BIG PICTURE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  Text(
                    'MODO CONSOLE ARCADE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Seletor de Categorias Estilo Abas de Console
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (idx) {
                  final isSelected = idx == _selectedCategoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategoryIndex = idx),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentCyan
                              : AppColors.cardBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentCyan
                                : AppColors.border.withValues(alpha: 0.5),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentCyan.withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          _categories[idx]['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Indicador de Controle & Relógio Digital
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gamepad, size: 16, color: Colors.greenAccent),
                const SizedBox(width: 6),
                const Text(
                  'GAMEPAD CONECTADO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
                const SizedBox(width: 14),
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Botão Sair do Big Picture
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white70),
            tooltip: 'Sair do Modo Big Picture (B / Esc)',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroShowcase(AppItem app, HomeViewModel vm) {
    final isAndroid = Platform.isAndroid;
    final isInstalled = vm.isInstalled(app.id);
    final sizeMb = app.getSizeMb(isAndroid);
    final appVersion = app.getVersion(isAndroid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banner Panorâmico 16:9 com Tilt 3D
          SizedBox(
            width: 380,
            height: 214,
            child: Tilt3DWidget(
              borderRadius: 20,
              maxTilt: 0.07,
              scaleOnHover: 1.02,
              onTap: () => _openDetails(app),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClusterImage(
                      url: app.bannerCard ?? app.banner ?? app.coverCard ?? app.iconUrl,
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
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                    if (app.gamepad)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_esports, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'GAMEPAD READY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Detalhes e Ações Rápidas
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        app.categoryName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (sizeMb != null)
                      Text(
                        '${sizeMb.toStringAsFixed(1)} MB',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    if (appVersion != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        'v$appVersion',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  app.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Text(
                  app.shortDescription,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 20),

                // Botão Primário de Ação Estilo Arcade [A]
                Row(
                  children: [
                    Tilt3DWidget(
                      borderRadius: 14,
                      maxTilt: 0.05,
                      scaleOnHover: 1.05,
                      onTap: () => vm.handleAction(app, context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentCyan, Color(0xFF00B4D8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/gamepad/xbox_a.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(Icons.play_arrow, color: Colors.black),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isInstalled ? 'JOGAR AGORA' : 'INSTALAR / BAIXAR',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Botão Secundário [X] Detalhes
                    Tilt3DWidget(
                      borderRadius: 14,
                      maxTilt: 0.05,
                      scaleOnHover: 1.05,
                      onTap: () => _openDetails(app),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/gamepad/xbox_x.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.info_outline, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'DETALHES',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostersCarousel(List<AppItem> list, HomeViewModel vm) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum item nesta categoria.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.0, vertical: 4.0),
          child: Text(
            'SELEÇÃO EM DESTAQUE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _shelfController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 12.0),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final isFocused = _focusedApp?.id == item.id;

              return Padding(
                padding: const EdgeInsets.only(right: 22.0),
                child: SizedBox(
                  width: 170,
                  child: Tilt3DWidget(
                    borderRadius: 16,
                    maxTilt: 0.12,
                    scaleOnHover: 1.08,
                    autofocus: index == 0 && _focusedApp == null,
                    onTap: () {
                      setState(() => _focusedApp = item);
                      _openDetails(item);
                    },
                    child: Focus(
                      onFocusChange: (hasF) {
                        if (hasF) {
                          setState(() => _focusedApp = item);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused
                                ? AppColors.accentCyan
                                : AppColors.border.withValues(alpha: 0.6),
                            width: isFocused ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isFocused
                                  ? AppColors.accentCyan.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.5),
                              blurRadius: isFocused ? 24 : 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Capa do Poster
                              ClusterImage(
                                url: item.coverCard ?? item.bannerCard ?? item.banner ?? item.iconUrl,
                                fit: BoxFit.cover,
                                fallback: Container(color: AppColors.surface),
                              ),
                              // Gradiente Inferior com Título
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.9),
                                    ],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 10,
                                right: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.categoryName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.accentCyan,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (item.gamepad)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.sports_esports,
                                      size: 14,
                                      color: AppColors.accentPurple,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetails(AppItem app) {
    Navigator.of(context).push(
      Spatial3DRoute(page: AppDetailView(app: app)),
    );
  }
}
