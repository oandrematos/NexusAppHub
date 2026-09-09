import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/app_item.dart';
import '../../../data/services/gamepad_service.dart';
import '../../core/app_colors.dart';
import '../../core/spatial_route.dart';
import '../../widgets/cluster_image.dart';
import '../../widgets/gamepad_hud_bar.dart';
import '../details/app_detail_view.dart';
import '../home/home_view_model.dart';

class BigPictureView extends StatefulWidget {
  const BigPictureView({super.key});

  @override
  State<BigPictureView> createState() => _BigPictureViewState();
}

class _BigPictureViewState extends State<BigPictureView> {
  int _selectedCategoryIndex = 0;
  int _focusedAppIndex = 0;
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

    // Conecta controles do GamepadService
    final gp = GamepadService();
    gp.onBackAction = () {
      if (mounted) Navigator.of(context).maybePop();
    };
    gp.onTabNext = () => _changeCategory(1);
    gp.onTabPrevious = () => _changeCategory(-1);
    gp.onActionA = () => _handleGamepadActionA();
    gp.onActionX = () => _handleGamepadActionX();
    gp.onDirectionalStep = (step) => _handleDirectionalStep(step);
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
      _focusedAppIndex = 0;
    });
    _scrollToFocused();
  }

  void _handleDirectionalStep(int step) {
    final vm = context.read<HomeViewModel>();
    final isAndroid = Platform.isAndroid;
    final availableApps = vm.apps.where((a) => a.isAvailableOn(isAndroid)).toList();
    final currentList = _getFilteredApps(availableApps);
    if (currentList.isEmpty) return;

    if (step == 1) {
      // Direita
      if (_focusedAppIndex < currentList.length - 1) {
        setState(() => _focusedAppIndex++);
        _scrollToFocused();
      }
    } else if (step == -1) {
      // Esquerda
      if (_focusedAppIndex > 0) {
        setState(() => _focusedAppIndex--);
        _scrollToFocused();
      }
    } else if (step == -2) {
      // Cima -> muda categoria
      _changeCategory(-1);
    } else if (step == 2) {
      // Baixo -> muda categoria
      _changeCategory(1);
    }
  }

  void _scrollToFocused() {
    if (_shelfController.hasClients) {
      final targetOffset = (_focusedAppIndex * 192.0).clamp(0.0, _shelfController.position.maxScrollExtent);
      _shelfController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleGamepadActionA() {
    final vm = context.read<HomeViewModel>();
    final isAndroid = Platform.isAndroid;
    final availableApps = vm.apps.where((a) => a.isAvailableOn(isAndroid)).toList();
    final currentList = _getFilteredApps(availableApps);
    if (currentList.isNotEmpty && _focusedAppIndex < currentList.length) {
      final app = currentList[_focusedAppIndex];
      vm.handleAction(app, context);
    }
  }

  void _handleGamepadActionX() {
    final vm = context.read<HomeViewModel>();
    final isAndroid = Platform.isAndroid;
    final availableApps = vm.apps.where((a) => a.isAvailableOn(isAndroid)).toList();
    final currentList = _getFilteredApps(availableApps);
    if (currentList.isNotEmpty && _focusedAppIndex < currentList.length) {
      _openDetails(currentList[_focusedAppIndex]);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _shelfController.dispose();
    final gp = GamepadService();
    gp.onBackAction = null;
    gp.onTabNext = null;
    gp.onTabPrevious = null;
    gp.onActionA = null;
    gp.onActionX = null;
    gp.onDirectionalStep = null;
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

    if (_focusedAppIndex >= currentList.length && currentList.isNotEmpty) {
      _focusedAppIndex = currentList.length - 1;
    }

    final activeApp = currentList.isNotEmpty ? currentList[_focusedAppIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo imersivo com gradiente cibernético de alta performance (Zero GPU Lag)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.4, -0.6),
                  radius: 1.4,
                  colors: [
                    Color(0xFF0E1A2D),
                    Color(0xFF060910),
                  ],
                ),
              ),
            ),
          ),

          // Estrutura Principal
          SafeArea(
            child: Column(
              children: [
                // Top Bar Estilo Console
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
    final isConnected = GamepadService().isGamepadConnected;

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

          // Seletor de Categorias
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (idx) {
                  final isSelected = idx == _selectedCategoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedCategoryIndex = idx;
                        _focusedAppIndex = 0;
                        _scrollToFocused();
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
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
                Icon(
                  Icons.gamepad,
                  size: 16,
                  color: isConnected ? Colors.greenAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'GAMEPAD ATIVO' : 'TECLADO / GAMEPAD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.greenAccent : AppColors.textSecondary,
                  ),
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
          // Banner Panorâmico 16:9
          SizedBox(
            width: 380,
            height: 214,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
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

                // Botões de Ação
                Row(
                  children: [
                    InkWell(
                      onTap: () => vm.handleAction(app, context),
                      borderRadius: BorderRadius.circular(14),
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

                    InkWell(
                      onTap: () => _openDetails(app),
                      borderRadius: BorderRadius.circular(14),
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
              final isFocused = _focusedAppIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 22.0),
                child: SizedBox(
                  width: 170,
                  child: InkWell(
                    onTap: () {
                      setState(() => _focusedAppIndex = index);
                      _scrollToFocused();
                      _openDetails(item);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      transform: isFocused
                          ? (Matrix4.identity()..scaleByDouble(1.06, 1.06, 1.0, 1.0))
                          : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFocused ? AppColors.accentCyan : AppColors.border.withValues(alpha: 0.6),
                          width: isFocused ? 2.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isFocused
                                ? AppColors.accentCyan.withValues(alpha: 0.45)
                                : Colors.black.withValues(alpha: 0.4),
                            blurRadius: isFocused ? 24 : 12,
                            offset: Offset(0, isFocused ? 8 : 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClusterImage(
                              url: item.coverCard ?? item.bannerCard ?? item.banner ?? item.iconUrl,
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
