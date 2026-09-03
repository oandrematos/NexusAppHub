import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_app_hub/data/models/app_item.dart';
import 'package:nexus_app_hub/data/services/catalog_service.dart';
import 'package:nexus_app_hub/data/services/app_detector.dart';
import 'package:nexus_app_hub/data/services/download_service.dart';

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

  bool get isLoading => _isLoading;
  List<AppItem> get apps => _filteredApps;
  List<AppItem> get featuredApps => _allApps.where((a) => a.featured).toList();
  String get selectedCategory => _selectedCategory;

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
      _applyFilters();
    } catch (e) {
      debugPrint('Erro ao carregar catálogo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> handleAction(AppItem app, BuildContext context) async {
    if (isInstalled(app.id) && !hasUpdate(app.id)) {
      final launched = await AppDetector.launchApp(app);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível iniciar ${app.name}.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    await installApp(app, context);
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