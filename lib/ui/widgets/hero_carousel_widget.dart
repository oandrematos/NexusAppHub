import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'cluster_image.dart';
import 'animated_action_button.dart';
import 'tilt_3d_widget.dart';

class HeroCarouselWidget extends StatefulWidget {
  final List<AppItem> apps;
  final bool Function(String id) isInstalled;
  final bool Function(String id) hasUpdate;
  final double? Function(String id)? getProgress;
  final String? Function(String id)? getStatus;
  final bool Function(String id)? isActionInProgress;
  final bool Function(String id)? isInstalling;
  final void Function(AppItem app) onTap;
  final void Function(AppItem app) onAction;

  const HeroCarouselWidget({
    super.key,
    required this.apps,
    required this.isInstalled,
    required this.hasUpdate,
    this.getProgress,
    this.getStatus,
    this.isActionInProgress,
    this.isInstalling,
    required this.onTap,
    required this.onAction,
  });

  @override
  State<HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
}

class _HeroCarouselWidgetState extends State<HeroCarouselWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    if (widget.apps.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || widget.apps.isEmpty) return;
        final next = (_currentPage + 1) % widget.apps.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apps.isEmpty) return const SizedBox.shrink();

    final isDesktop = MediaQuery.of(context).size.width >= 800 && !Platform.isAndroid;
    final carouselHeight = isDesktop ? 280.0 : 200.0;

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: widget.apps.length,
            itemBuilder: (context, index) {
              final app = widget.apps[index];
              final installed = widget.isInstalled(app.id);
              final update = widget.hasUpdate(app.id);
              final progress = widget.getProgress?.call(app.id);
              final status = widget.getStatus?.call(app.id);
              final inProgress = widget.isActionInProgress?.call(app.id) ?? (progress != null && progress > 0);
              final installing = widget.isInstalling?.call(app.id) ?? false;
              final isAvailable = app.isAvailableOn(Platform.isAndroid);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, cardChild) {
                  double pageOffset = 0.0;
                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                    pageOffset = (_pageController.page ?? _currentPage.toDouble()) - index;
                  } else {
                    pageOffset = (_currentPage - index).toDouble();
                  }

                  final rotY = (pageOffset * -0.22).clamp(-0.45, 0.45);
                  final scale = (1.0 - (pageOffset.abs() * 0.06)).clamp(0.88, 1.0);
                  final opacity = (1.0 - (pageOffset.abs() * 0.25)).clamp(0.45, 1.0);

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(rotY)
                    ..scaleByDouble(scale, scale, 1.0, 1.0);

                  return RepaintBoundary(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform(
                        transform: matrix,
                        alignment: pageOffset > 0 ? Alignment.centerRight : Alignment.centerLeft,
                        child: Tilt3DWidget(
                          borderRadius: 20,
                          onTap: () => widget.onTap(app),
                          child: cardChild!,
                        ),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Banner em alta definição embutido
                        ClusterImage(
                          url: app.banner ?? app.bannerCard ?? app.iconUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),

                        // Gradiente de sobreposição cinematográfico
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                                Colors.black.withValues(alpha: 0.95),
                              ],
                              stops: const [0.3, 0.6, 1.0],
                            ),
                          ),
                        ),

                        // Toque para abrir detalhes na base do card
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onTap(app),
                            ),
                          ),
                        ),

                        // Conteúdo Informativo e Botão de Ação
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Row(
                            children: [
                              // Ícone do App em Squircle
                              Container(
                                width: isDesktop ? 52 : 46,
                                height: isDesktop ? 52 : 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ClusterImage(
                                    url: app.iconUrl,
                                    fit: BoxFit.cover,
                                    fallback: Center(
                                      child: Text(
                                        app.icon,
                                        style: TextStyle(fontSize: isDesktop ? 26 : 22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Título, Categoria e Badge
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
                                            style: TextStyle(
                                              fontSize: isDesktop ? 19 : 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (app.badge.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentCyan.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.accentCyan.withValues(alpha: 0.6),
                                                width: 1,
                                              ),
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
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      app.shortDescription.isNotEmpty ? app.shortDescription : app.categoryName,
                                      style: TextStyle(
                                        fontSize: isDesktop ? 13 : 11.5,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isDesktop && app.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        app.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Botão de Ação com Barra de Progresso e Animações
                              AnimatedActionButton(
                                app: app,
                                isInstalled: installed,
                                hasUpdate: update,
                                isAvailable: isAvailable,
                                isActionInProgress: inProgress,
                                downloadProgress: progress,
                                downloadStatus: status,
                                isInstalling: installing,
                                isHero: true,
                                height: isDesktop ? 44 : 38,
                                onAction: () => widget.onAction(app),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.apps.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.apps.length, (index) {
              final isSel = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSel ? 22 : 6,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isSel ? AppColors.accentCyan : AppColors.border,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}