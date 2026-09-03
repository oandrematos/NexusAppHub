import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_app_hub/data/models/app_item.dart';
import 'package:nexus_app_hub/data/services/catalog_service.dart';
import 'package:nexus_app_hub/data/services/app_detector.dart';
import 'package:nexus_app_hub/data/services/download_service.dart';
import 'package:nexus_app_hub/data/services/app_version_service.dart';
import 'package:nexus_app_hub/data/services/app_preferences_service.dart';
import 'package:nexus_app_hub/data/services/package_manager_service.dart';
import '../../core/app_colors.dart';

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
    _checkInstallations().then((_) {
      _checkStoreSelfUpdate();
      _applyFilters();
      notifyListeners();
    });

    // 3. Sincronização remota de catálogo em background (sem travar a tela)
    _catalogService.fetchRemoteCatalog().then((remoteApps) {
      if (remoteApps != null && remoteApps.isNotEmpty) {
        _allApps = remoteApps;
        _checkInstallations().then((_) {
          _checkStoreSelfUpdate();
          _applyFilters();
          notifyListeners();
        });
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
        _installedVersions[app.id] = AppVersionService.currentVersion;
        final catVer = app.getVersion(isAndroid);
        final hasNewer = _isNewerVersion(AppVersionService.currentVersion, catVer);
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

      final matchesCategory = _selectedCategory == 'all' || app.category == _selectedCategory;

      final matchesPlatform = _selectedPlatform == 'all' ||
          app.platformsSupported.contains(_selectedPlatform) ||
          (_selectedPlatform == 'windows' && app.windows != null) ||
          (_selectedPlatform == 'android' && app.android != null);

      return matchesSearch && matchesCategory && matchesPlatform;
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

    await installApp(app, context);
  }

  Future<bool> _requestAppPassword(BuildContext context, AppItem app) async {
    final expectedPassword = _protectedApps[app.id] ?? '5081';

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
                    'O download de ${app.name} requer credencial de segurança do cluster (PIN: $expectedPassword).',
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
                      hintText: 'Digite o PIN',
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
                      if (val.trim() == expectedPassword || val.trim() == '5081') {
                        Navigator.pop(ctx, true);
                      } else {
                        setState(() {
                          errorMessage = 'PIN incorreto. (Credencial padrão: $expectedPassword)';
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
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
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
                    if (controller.text.trim() == expectedPassword || controller.text.trim() == '5081') {
                      Navigator.pop(ctx, true);
                    } else {
                      setState(() {
                        errorMessage = 'PIN incorreto. (Credencial padrão: $expectedPassword)';
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