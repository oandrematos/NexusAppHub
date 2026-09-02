import 'dart:io';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget body;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.accentCyan, AppColors.accentPurple],
                            ),
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 24),
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
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(child: body),
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.cardBg,
            indicatorColor: AppColors.accentCyan.withOpacity(0.2),
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
            ],
          ),
        );
      },
    );
  }
}