import 'dart:io';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../widgets/tilt_3d_widget.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback? onOpenBigPicture;
  final Widget body;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onOpenBigPicture,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768 && !Platform.isAndroid;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentCyan.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'NEXUS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Tilt3DWidget(
                          borderRadius: 14,
                          maxTilt: 0.08,
                          scaleOnHover: 1.08,
                          onTap: onOpenBigPicture,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.accentCyan.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_esports, color: AppColors.accentCyan, size: 22),
                                SizedBox(height: 4),
                                Text(
                                  'BIG PICTURE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront, color: AppColors.accentCyan),
                      label: Text('Destaques'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.apps_outlined),
                      selectedIcon: Icon(Icons.apps, color: AppColors.accentCyan),
                      label: Text('Biblioteca'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.source_outlined),
                      selectedIcon: Icon(Icons.source_rounded, color: AppColors.accentCyan),
                      label: Text('Gerenciadores'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: AppColors.accentCyan),
                      label: Text('Ajustes'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                body,
                // Botão flutuante de Big Picture para Mobile/Tablet
                Positioned(
                  top: 12,
                  right: 16,
                  child: Tilt3DWidget(
                    borderRadius: 20,
                    maxTilt: 0.05,
                    scaleOnHover: 1.05,
                    onTap: onOpenBigPicture,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_esports, color: AppColors.accentCyan, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'BIG PICTURE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.cardBg,
            indicatorColor: AppColors.accentCyan.withValues(alpha: 0.2),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront, color: AppColors.accentCyan),
                label: 'Loja',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps, color: AppColors.accentCyan),
                label: 'Meus Apps',
              ),
              NavigationDestination(
                icon: Icon(Icons.source_outlined),
                selectedIcon: Icon(Icons.source_rounded, color: AppColors.accentCyan),
                label: 'Pacotes',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: AppColors.accentCyan),
                label: 'Ajustes',
              ),
            ],
          ),
        );
      },
    );
  }
}