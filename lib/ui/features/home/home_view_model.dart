import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_app_hub/data/models/app_item.dart';
import 'package:nexus_app_hub/data/services/catalog_service.dart';
import 'package:nexus_app_hub/data/services/app_detector.dart';
import 'package:nexus_app_hub/data/services/download_service.dart';
import 'package:nexus_app_hub/data/services/app_version_service.dart';
import 'package:nexus_app_hub/data/services/app_preferences_service.dart';
import 'package:nexus_app_hub/data/services/package_manager_service.dart';

class HomeViewModel extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();
  final DownloadService _downloadService = DownloadService();
  final AppPreferencesService _prefs = AppPreferencesService();

  List<AppItem> _allApps = [];
  List<AppItem> _filteredApps = [];
  final Map<String, bool> _installedStatus = {};
  final Map<String, String?> _installedVersions = {};
  final Map<String, bool> _hasUpdateStatus = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};
  final Map<String, bool> _isInstalling = {};

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedPlatform = 'all';

  bool _hasStoreUpdate = false;
  String _storeUpdateVersion = '';
  AppItem? _storeUpdateApp;

  bool get isLoading => _isLoading;
  List<AppItem> get apps => _filteredApps;
  List<AppItem> get featuredApps => _allApps.where((a) => a.featured).toList();
  String get selectedCategory => _selectedCategory;
  String get selectedPlatform => _selectedPlatform;
  String get searchQuery => _searchQuery;

  bool get hasStoreUpdate => _hasStoreUpdate;
  String get storeUpdateVersion => _storeUpdateVersion;
  AppItem? get storeUpdateApp => _storeUpdateApp;

  bool isInstalled(String appId) => _installedStatus[appId] ?? false;
  bool hasUpdate(String appId) => !_prefs.isUpdateIgnored(appId) && (_hasUpdateStatus[appId] ?? false);
  String? getInstalledVersion(String appId) => _installedVersions[appId];
  double? getProgress(String appId) => _downloadProgress[appId];
  String? getStatus(String appId) => _downloadStatus[appId];
  bool isDownloading(String appId) => _downloadProgress.containsKey(appId);
  bool isInstalling(String appId) => _isInstalling[appId] ?? false;
  bool isActionInProgress(String appId) => isDownloading(appId) || isInstalling(appId);

  List<AppItem> get appsWithUpdates => _allApps.where((a) => isInstalled(a.id) && hasUpdate(a.id)).toList();
  int get updateCount => appsWithUpdates.length + (hasStoreUpdate ? 1 : 0);

  List<AppItem> get recentlyUpdatedApps {
    return _allApps.where((a) => a.latestChangelog != null && a.latestChangelog!.isNotEmpty).toList();
  }

  bool _isUpdatingAll = false;
  bool get isUpdatingAll => _isUpdatingAll;

  HomeViewModel() {
    loadData();
  }

  Future<void> loadData() async {
    // 1. Carrega localmente e exibe a vitrine em ZERO MILISSEGUNDOS!
    try {
      await _prefs.init();
      if (_allApps.isEmpty) {
        _allApps = await _catalogService.loadLocalCatalog();
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Erro ao carregar catálogo local: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Renderiza a loja IMEDIATAMENTE!
    }

    // 2. Detecção de instalações em paralelo de forma não-bloqueante
    _checkInstallations().then((_) async {
      await _checkStoreSelfUpdate();
      _applyFilters();
      notifyListeners();
    });

    // 3. Sincronização remota de catálogo em background (sem travar a tela)
    _catalogService.fetchRemoteCatalog().then((remoteApps) async {
      if (remoteApps != null && remoteApps.isNotEmpty) {
        _allApps = remoteApps;
        await _checkInstallations();
        await _checkStoreSelfUpdate();
        _applyFilters();
        notifyListeners();
      }
    });
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
      } else {
        currentVer = await AppDetector.getInstalledVersion(
          'NexusAppHub.exe',
          null,
        );
      }
      currentVer ??= AppVersionService.currentVersion;

      if (_isNewerVersion(currentVer, serverVer)) {
        _hasStoreUpdate = true;
        _storeUpdateVersion = serverVer;
        _storeUpdateApp = hubApp;
      } else {
        _hasStoreUpdate = false;
        _storeUpdateApp = null;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> checkForUpdates() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remoteApps = await _catalogService.fetchRemoteCatalog();
      if (remoteApps != null && remoteApps.isNotEmpty) {
        _allApps = remoteApps;
      }
      await _checkInstallations();
      await _checkStoreSelfUpdate();
      _applyFilters();
      return updateCount > 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAll(BuildContext context) async {
    if (_isUpdatingAll) return;
    final toUpdate = List<AppItem>.from(appsWithUpdates);
    if (toUpdate.isEmpty) return;

    _isUpdatingAll = true;
    notifyListeners();

    try {
      for (final app in toUpdate) {
        if (!context.mounted) break;
        await installApp(app, context);
      }
    } finally {
      _isUpdatingAll = false;
      notifyListeners();
    }
  }

  Future<void> updateStore(BuildContext context) async {
    if (_storeUpdateApp == null) return;
    await installApp(_storeUpdateApp!, context);
  }

  bool _isNewerVersion(String? installed, String? catalog) {
    if (installed == null || catalog == null) return false;
    final cleanInstalled = installed
        .replaceAll('v', '')
        .replaceAll('V', '')
        .replaceAll('-alpha', '')
        .replaceAll('-beta', '')
        .replaceAll(',', '.')
        .replaceAll('_', '.')
        .replaceAll(' ', '')
        .trim();
    final cleanCatalog = catalog
        .replaceAll('v', '')
        .replaceAll('V', '')
        .replaceAll('-alpha', '')
        .replaceAll('-beta', '')
        .replaceAll(',', '.')
        .replaceAll('_', '.')
        .replaceAll(' ', '')
        .trim();

    if (cleanInstalled.isEmpty || cleanCatalog.isEmpty) return false;
    if (cleanInstalled == cleanCatalog) return false;

    // Special case: if installed version is the legacy mistaken 1.1.x and catalog is 0.x, it's an update!
    if (cleanInstalled.startsWith('1.1.') && cleanCatalog.startsWith('0.')) {
      return true;
    }

    final instParts = cleanInstalled.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final catParts = cleanCatalog.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = instParts.length > catParts.length ? instParts.length : catParts.length;
    for (int i = 0; i < maxLen; i++) {
      final catNum = i < catParts.length ? catParts[i] : 0;
      final instNum = i < instParts.length ? instParts[i] : 0;
      if (catNum > instNum) return true;
      if (catNum < instNum) return false;
    }

    return false;
  }

  bool isUpdateIgnored(String appId) => _prefs.isUpdateIgnored(appId);

  Future<void> toggleIgnoreUpdate(String appId) async {
    final current = _prefs.isUpdateIgnored(appId);
    await _prefs.setUpdateIgnored(appId, !current);
    if (!current) {
      _hasUpdateStatus[appId] = false;
    } else {
      await _checkInstallations();
    }
    notifyListeners();
  }

  String getAppSource(String appId) => _prefs.getAppSource(appId);

  Future<void> setAppSource(String appId, String source) async {
    await _prefs.setAppSource(appId, source);
    notifyListeners();
  }

  Future<void> _checkInstallations() async {
    final isAndroid = Platform.isAndroid;
    await Future.wait(_allApps.map((app) async {
      if (app.id == 'nexus_app_hub') {
        _installedStatus[app.id] = true;
        String curVer = AppVersionService.currentVersion;
        if (isAndroid) {
          final installedOnDevice = await AppDetector.getInstalledVersion(
            null,
            'com.antigravity.nexus_app_hub',
          );
          if (installedOnDevice != null && installedOnDevice.isNotEmpty) {
            curVer = installedOnDevice;
          }
        }
        _installedVersions[app.id] = curVer;
        final catVer = app.getVersion(isAndroid);
        final hasNewer = _isNewerVersion(curVer, catVer);
        _hasUpdateStatus[app.id] = hasNewer && !_prefs.isUpdateIgnored(app.id);
        return;
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
        final hasNewer = _isNewerVersion(instVer, catVer);
        _hasUpdateStatus[app.id] = hasNewer && !_prefs.isUpdateIgnored(app.id);
      } else {
        _installedVersions[app.id] = null;
        _hasUpdateStatus[app.id] = false;
      }
    }));
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setPlatform(String platform) {
    _selectedPlatform = platform;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredApps = _allApps.where((app) {
      final matchesSearch = app.name.toLowerCase().contains(_searchQuery) ||
          app.description.toLowerCase().contains(_searchQuery) ||
          app.categoryName.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == 'all' ||
          (_selectedCategory == 'updates'
              ? (isInstalled(app.id) && hasUpdate(app.id))
              : app.category == _selectedCategory);

      final matchesPlatform = _selectedPlatform == 'all' ||
          app.platformsSupported.contains(_selectedPlatform) ||
          (_selectedPlatform == 'windows' && app.windows != null) ||
          (_selectedPlatform == 'android' && app.android != null) ||
          (_selectedPlatform == 'linux' && (app.platformsSupported.contains('linux') || app.linux != null));

      return matchesSearch && matchesCategory && matchesPlatform;
    }).toList();
    notifyListeners();
  }

  bool isAppProtected(String appId) => false;

  Future<void> handleAction(AppItem app, BuildContext context) async {
    if (isActionInProgress(app.id)) return;

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

    await installApp(app, context);
  }

  Future<void> uninstallApp(AppItem app, BuildContext context) async {
    // 1. Atualização Otimista Imediata (Na mesma hora, zero delay)
    _installedStatus[app.id] = false;
    _installedVersions[app.id] = null;
    _hasUpdateStatus[app.id] = false;
    AppDetector.clearCache();
    notifyListeners();

    final success = await AppDetector.uninstallApp(app);
    AppDetector.clearCache();
    await _checkInstallations();
    notifyListeners();

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.name} desinstalado com sucesso.'),
            backgroundColor: const Color(0xFF00FFCC),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível desinstalar ${app.name} automaticamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> installApp(AppItem app, BuildContext context) async {
    final isAndroid = Platform.isAndroid;
    final source = !isAndroid ? getAppSource(app.id) : 'nexus';

    if (source == 'winget' && app.windows?.wingetId != null) {
      _downloadProgress[app.id] = 0.5;
      _downloadStatus[app.id] = 'Instalando via Winget...';
      notifyListeners();

      final success = await PackageManagerService.installPackage(
        packageId: app.windows!.wingetId!,
        source: 'winget',
        onStatus: (st) {
          _downloadStatus[app.id] = st;
          notifyListeners();
        },
      );

      _downloadProgress.remove(app.id);
      _downloadStatus.remove(app.id);
      if (success) {
        await _checkInstallations();
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.name} instalado com sucesso via Winget!'),
              backgroundColor: const Color(0xFF00FFCC),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha na instalação de ${app.name} via Winget.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    if (source == 'choco' && app.windows?.chocoId != null) {
      _downloadProgress[app.id] = 0.5;
      _downloadStatus[app.id] = 'Instalando via Chocolatey...';
      notifyListeners();

      final success = await PackageManagerService.installPackage(
        packageId: app.windows!.chocoId!,
        source: 'chocolatey',
        onStatus: (st) {
          _downloadStatus[app.id] = st;
          notifyListeners();
        },
      );

      _downloadProgress.remove(app.id);
      _downloadStatus.remove(app.id);
      if (success) {
        await _checkInstallations();
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.name} instalado com sucesso via Chocolatey!'),
              backgroundColor: const Color(0xFF00FFCC),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha na instalação de ${app.name} via Chocolatey.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    final filename = app.getFilename(isAndroid);
    if (filename == null) return;

    _downloadProgress[app.id] = 0.01;
    _downloadStatus[app.id] = 'Iniciando download...';
    _isInstalling[app.id] = false;
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
        _isInstalling.remove(app.id);
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      onCompleted: () async {
        if (isAndroid) {
          // No Android, a chamada para installApk dispara o instalador do sistema.
          // Mantemos o app no estado 'Instalando...' com o botão indisponível/bloqueado.
          _isInstalling[app.id] = true;
          _downloadStatus[app.id] = 'Instalando aplicativo...';
          _downloadProgress[app.id] = 1.0;
          notifyListeners();

          // Monitoramento ativo e não-bloqueante em background (polling a cada 1s por até 90s)
          int attempts = 0;
          Timer.periodic(const Duration(seconds: 1), (timer) async {
            attempts++;
            AppDetector.clearCache();
            final installed = await AppDetector.isAppInstalled(null, app.android?.packageName);
            if (installed || attempts >= 90) {
              timer.cancel();
              _isInstalling.remove(app.id);
              _downloadProgress.remove(app.id);
              _downloadStatus.remove(app.id);
              await _checkInstallations();
              notifyListeners();
            }
          });
        } else {
          _downloadProgress.remove(app.id);
          _downloadStatus.remove(app.id);
          _isInstalling.remove(app.id);
          AppDetector.clearCache();
          await _checkInstallations();
          notifyListeners();

          // Segunda verificação após 1.5s para garantir que os arquivos e registros terminaram de ser escritos
          Future.delayed(const Duration(milliseconds: 1500), () async {
            AppDetector.clearCache();
            await _checkInstallations();
            notifyListeners();
          });
        }
      },
    );
  }
}