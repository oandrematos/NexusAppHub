import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';
import 'cluster_image.dart';

class HeroCarouselWidget extends StatefulWidget {
  final List<AppItem> apps;
  final bool Function(String id) isInstalled;
  final bool Function(String id) hasUpdate;
  final void Function(AppItem app) onTap;
  final void Function(AppItem app) onAction;

  const HeroCarouselWidget({
    super.key,
    required this.apps,
    required this.isInstalled,
    required this.hasUpdate,
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
    _pageController = PageController(viewportFraction: 0.94);
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
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

                      // Conteúdo Informativo e Botão de Ação
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Ícone
                            Container(
                              width: isDesktop ? 58 : 46,
                              height: isDesktop ? 58 : 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: ClusterImage(
                                  url: app.iconUrl,
                                  fit: BoxFit.cover,
                                  fallback: Center(child: Text(app.icon, style: const TextStyle(fontSize: 24))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Título e Descrição
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentCyan.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          app.categoryName.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.accentCyan,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    app.name,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 22 : 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
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

                            // Botão de Ação Direta
                            FilledButton(
                              onPressed: () => widget.onAction(app),
                              style: FilledButton.styleFrom(
                                backgroundColor: update
                                    ? Colors.orangeAccent
                                    : (installed ? Colors.white.withValues(alpha: 0.2) : AppColors.accentCyan),
                                foregroundColor: update ? Colors.black : (installed ? Colors.white : Colors.black),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 20 : 14,
                                  vertical: isDesktop ? 12 : 8,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: Text(
                                update ? 'Atualizar' : (installed ? 'Abrir' : 'Instalar'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Toque para abrir detalhes
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onTap(app),
                          ),
                        ),
                      ),
                    ],
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