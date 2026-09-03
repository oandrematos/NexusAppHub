import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppPreferencesService {
  static final AppPreferencesService _instance = AppPreferencesService._internal();
  factory AppPreferencesService() => _instance;
  AppPreferencesService._internal();

  final Set<String> _ignoredUpdates = {};
  final Map<String, String> _appSources = {}; // appId -> 'nexus' | 'winget' | 'choco'
  File? _file;
  bool _initialized = false;

  Set<String> get ignoredUpdates => Set.unmodifiable(_ignoredUpdates);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/nexus_app_preferences.json');
      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (data['ignored_updates'] is List) {
          _ignoredUpdates.addAll(List<String>.from(data['ignored_updates']));
        }
        if (data['app_sources'] is Map) {
          data['app_sources'].forEach((k, v) {
            _appSources[k.toString()] = v.toString();
          });
        }
      }
    } catch (_) {} finally {
      _initialized = true;
    }
  }

  bool isUpdateIgnored(String appId) {
    return _ignoredUpdates.contains(appId);
  }

  Future<void> setUpdateIgnored(String appId, bool ignored) async {
    if (ignored) {
      _ignoredUpdates.add(appId);
    } else {
      _ignoredUpdates.remove(appId);
    }
    await _save();
  }

  String getAppSource(String appId) {
    return _appSources[appId] ?? 'nexus';
  }

  Future<void> setAppSource(String appId, String source) async {
    _appSources[appId] = source;
    await _save();
  }

  Future<void> _save() async {
    try {
      if (_file == null) {
        final dir = await getApplicationSupportDirectory();
        _file = File('${dir.path}/nexus_app_preferences.json');
      }
      final data = {
        'ignored_updates': _ignoredUpdates.toList(),
        'app_sources': _appSources,
      };
      await _file!.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}