import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_view_model.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_card_widget.dart';
import '../details/detail_sheet.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final installedApps = vm.apps.where((a) => vm.isInstalled(a.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biblioteca de Aplicativos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: installedApps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum aplicativo instalado no momento.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 220,
                ),
                itemCount: installedApps.length,
                itemBuilder: (context, index) {
                  final app = installedApps[index];
                  return AppCardWidget(
                    app: app,
                    isInstalled: true,
                    hasUpdate: vm.hasUpdate(app.id),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DetailSheet(
                          app: app,
                          isInstalled: true,
                          hasUpdate: vm.hasUpdate(app.id),
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
                    },
                    onAction: () => vm.handleAction(app, context),
                    onUninstall: () => vm.uninstallApp(app, context),
                  );
                },
              ),
            ),
    );
  }
}