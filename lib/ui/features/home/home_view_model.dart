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

  Future<void> _checkInstallations() async {
    final isAndroid = Platform.isAndroid;
    for (final app in _allApps) {
      final installed = await AppDetector.isAppInstalled(
        app.windows?.executable,
        app.android?.packageName,
      );
      _installedStatus[app.id] = installed;
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