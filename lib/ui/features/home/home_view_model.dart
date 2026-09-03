import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_app_hub/data/models/app_item.dart';
import 'package:nexus_app_hub/data/services/catalog_service.dart';
import 'package:nexus_app_hub/data/services/app_detector.dart';
import 'package:nexus_app_hub/data/services/download_service.dart';
import 'package:nexus_app_hub/data/services/app_version_service.dart';
import '../../core/app_colors.dart';

class HomeViewModel extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();
  final DownloadService _downloadService = DownloadService();

  List<AppItem> _allApps = [];
  List<AppItem> _filteredApps = [];
  final Map<String, bool> _installedStatus = {};
  final Map<String, String?> _installedVersions = {};
  final Map<String, bool> _hasUpdateStatus = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  bool _hasStoreUpdate = false;
  String _storeUpdateVersion = '';
  AppItem? _storeUpdateApp;

  bool get isLoading => _isLoading;
  List<AppItem> get apps => _filteredApps;
  List<AppItem> get featuredApps => _allApps.where((a) => a.featured).toList();
  String get selectedCategory => _selectedCategory;

  bool get hasStoreUpdate => _hasStoreUpdate;
  String get storeUpdateVersion => _storeUpdateVersion;
  AppItem? get storeUpdateApp => _storeUpdateApp;

  bool isInstalled(String appId) => _installedStatus[appId] ?? false;
  bool hasUpdate(String appId) => _hasUpdateStatus[appId] ?? false;
  String? getInstalledVersion(String appId) => _installedVersions[appId];
  double? getProgress(String appId) => _downloadProgress[appId];
  String? getStatus(String appId) => _downloadStatus[appId];

  HomeViewModel() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allApps = await _catalogService.loadCatalog();
      await _checkInstallations();
      await _checkStoreSelfUpdate();
      _applyFilters();
    } catch (e) {
      debugPrint('Erro ao carregar catálogo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkStoreSelfUpdate() async {
    final isAndroid = Platform.isAndroid;
    try {
      final hubApp = _allApps.firstWhere((a) => a.id == 'nexus_app_hub');
      final serverVer = hubApp.getVersion(isAndroid);
      if (serverVer == null) return;

      String? currentVer;
      if (isAndroid) {
        currentVer = await AppDetector.getInstalledVersion(
          null,
          'com.antigravity.nexus_app_hub',
        );
      }
      currentVer ??= AppVersionService.currentVersion;

      if (_isNewerVersion(currentVer, serverVer)) {
        _hasStoreUpdate = true;
        _storeUpdateVersion = serverVer;
        _storeUpdateApp = hubApp;
      }
    } catch (_) {}
  }

  Future<void> updateStore(BuildContext context) async {
    if (_storeUpdateApp == null) return;
    await installApp(_storeUpdateApp!, context);
  }

  bool _isNewerVersion(String? installed, String? catalog) {
    if (installed == null || catalog == null) return false;
    final cleanInstalled = installed
        .replaceAll('v', '')
        .replaceAll('-alpha', '')
        .replaceAll('-beta', '')
        .trim();
    final cleanCatalog = catalog
        .replaceAll('v', '')
        .replaceAll('-alpha', '')
        .replaceAll('-beta', '')
        .trim();

    if (cleanInstalled.isEmpty || cleanCatalog.isEmpty) return false;
    if (cleanInstalled == cleanCatalog) return false;

    final instParts = cleanInstalled.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final catParts = cleanCatalog.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < catParts.length; i++) {
      final catNum = catParts[i];
      final instNum = i < instParts.length ? instParts[i] : 0;
      if (catNum > instNum) return true;
      if (catNum < instNum) return false;
    }

    return false;
  }

  Future<void> _checkInstallations() async {
    final isAndroid = Platform.isAndroid;
    for (final app in _allApps) {
      if (app.id == 'nexus_app_hub') {
        _installedStatus[app.id] = true;
        _installedVersions[app.id] = AppVersionService.currentVersion;
        final catVer = app.getVersion(isAndroid);
        _hasUpdateStatus[app.id] = _isNewerVersion(AppVersionService.currentVersion, catVer);
        continue;
      }

      final installed = await AppDetector.isAppInstalled(
        app.windows?.executable,
        app.android?.packageName,
      );
      _installedStatus[app.id] = installed;

      if (installed) {
        final instVer = await AppDetector.getInstalledVersion(
          app.windows?.executable,
          app.android?.packageName,
        );
        _installedVersions[app.id] = instVer;

        final catVer = app.getVersion(isAndroid);
        _hasUpdateStatus[app.id] = _isNewerVersion(instVer, catVer);
      } else {
        _installedVersions[app.id] = null;
        _hasUpdateStatus[app.id] = false;
      }
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredApps = _allApps.where((app) {
      final matchesSearch = app.name.toLowerCase().contains(_searchQuery) ||
          app.description.toLowerCase().contains(_searchQuery) ||
          app.categoryName.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == 'all' || app.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
    notifyListeners();
  }

  // Aplicativos protegidos por credencial de segurança (configuração restrita sob comando direto do Diretor)
  static const Map<String, String> _protectedApps = {
    'nexus_dashboard': '5081',
  };

  bool isAppProtected(String appId) {
    return _protectedApps.containsKey(appId);
  }

  Future<void> handleAction(AppItem app, BuildContext context) async {
    if (isInstalled(app.id) && !hasUpdate(app.id)) {
      final launched = await AppDetector.launchApp(app);
      if (!launched) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível iniciar ${app.name}.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    // Checagem de proteção por credencial antes do download / instalação
    if (isAppProtected(app.id)) {
      final authorized = await _requestAppPassword(context, app);
      if (!authorized) return;
    }

    if (!context.mounted) return;
    await installApp(app, context);
  }

  Future<bool> _requestAppPassword(BuildContext context, AppItem app) async {
    final expectedPassword = _protectedApps[app.id];
    if (expectedPassword == null) return true;

    final controller = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.accentCyan, width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.accentCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Acesso Restrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O download de ${app.name} requer autorização de segurança.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Digite a senha',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.key, color: AppColors.accentCyan, size: 20),
                    ),
                    onSubmitted: (val) {
                      if (val.trim() == expectedPassword) {
                        Navigator.pop(ctx, true);
                      } else {
                        setState(() {
                          errorMessage = 'Senha incorreta. Acesso negado.';
                        });
                        controller.clear();
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim() == expectedPassword) {
                      Navigator.pop(ctx, true);
                    } else {
                      setState(() {
                        errorMessage = 'Senha incorreta. Acesso negado.';
                      });
                      controller.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Autorizar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> uninstallApp(AppItem app, BuildContext context) async {
    final success = await AppDetector.uninstallApp(app);
    if (success) {
      await _checkInstallations();
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.name} desinstalado com sucesso.'),
          backgroundColor: const Color(0xFF00FFCC),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível desinstalar ${app.name} automaticamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> installApp(AppItem app, BuildContext context) async {
    final isAndroid = Platform.isAndroid;
    final filename = app.getFilename(isAndroid);
    if (filename == null) return;

    _downloadProgress[app.id] = 0.01;
    notifyListeners();

    await _downloadService.downloadAndInstall(
      filename: filename,
      onProgress: (p) {
        _downloadProgress[app.id] = p;
        notifyListeners();
      },
      onStatus: (s) {
        _downloadStatus[app.id] = s;
        notifyListeners();
      },
      onError: (err) {
        _downloadProgress.remove(app.id);
        _downloadStatus.remove(app.id);
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      onCompleted: () async {
        _downloadProgress.remove(app.id);
        _downloadStatus.remove(app.id);
        await _checkInstallations();
        notifyListeners();
      },
    );
  }
}