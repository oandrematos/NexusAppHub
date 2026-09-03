import 'dart:io';
import 'package:flutter/services.dart';
import 'app_version_service.dart';
import '../models/app_item.dart';

class AppDetector {
  static const MethodChannel _androidChannel =
      MethodChannel('com.antigravity.nexus_app_hub/app_manager');

  static final List<String> _baseDirs = [
    if (Platform.environment['LOCALAPPDATA'] != null)
      '${Platform.environment['LOCALAPPDATA']}/Programs',
    if (Platform.environment['ProgramFiles'] != null)
      Platform.environment['ProgramFiles']!,
    if (Platform.environment['ProgramFiles(x86)'] != null)
      Platform.environment['ProgramFiles(x86)']!,
    'C:/Games',
    'D:/Games',
  ];

  static List<String> _getPackageCandidates(String packageName) {
    final list = <String>[packageName];
    if (packageName == 'com.antigravity.threadsdl') {
      list.add('com.andre.threadsdl');
    } else if (packageName == 'com.andre.threadsdl') {
      list.add('com.antigravity.threadsdl');
    }

    if (packageName == 'com.antigravity.spaceduel') {
      list.add('com.andre.spaceduel');
    } else if (packageName == 'com.andre.spaceduel') {
      list.add('com.antigravity.spaceduel');
    }

    if (packageName == 'com.antigravity.snakegame') {
      list.add('com.example.snake_game');
    } else if (packageName == 'com.example.snake_game') {
      list.add('com.antigravity.snakegame');
    }

    return list;
  }

  static Future<bool> isAppInstalled(String? executableName, String? packageName) async {
    if (Platform.isAndroid) {
      if (packageName == null || packageName.isEmpty) return false;
      final candidates = _getPackageCandidates(packageName);
      for (final candidate in candidates) {
        try {
          final res = await _androidChannel.invokeMethod<bool>(
            'isAppInstalled',
            {'packageName': candidate},
          );
          if (res == true) return true;
        } catch (_) {}
      }
      return false;
    }

    final path = await getInstalledExecutablePath(executableName);
    return path != null;
  }

  static Future<String?> getInstalledVersion(String? executableName, String? packageName) async {
    if (Platform.isAndroid) {
      if (packageName == null || packageName.isEmpty) return null;
      final candidates = _getPackageCandidates(packageName);
      for (final candidate in candidates) {
        try {
          final version = await _androidChannel.invokeMethod<String>(
            'getAppVersion',
            {'packageName': candidate},
          );
          if (version != null && version.isNotEmpty) return version;
        } catch (_) {}
      }
      return null;
    }

    if (Platform.isWindows) {
      if (executableName == null || executableName.isEmpty) return null;

      if (executableName.toLowerCase().contains('nexusapphub') ||
          executableName.toLowerCase().contains('nexus_app_hub')) {
        return AppVersionService.currentVersion;
      }

      final execPath = await getInstalledExecutablePath(executableName);
      if (execPath != null) {
        final dir = File(execPath).parent;
        final vFile = File('${dir.path}/version.json');
        if (vFile.existsSync()) {
          try {
            final content = vFile.readAsStringSync();
            final match = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(content);
            if (match != null) return match.group(1);
          } catch (_) {}
        }

        final baseName = File(execPath).uri.pathSegments.last.replaceAll('.exe', '');
        final regVer = await _getWindowsRegistryVersion(baseName);
        if (regVer != null) return regVer;
      }
    }

    return null;
  }

  static Future<String?> _getWindowsRegistryVersion(String appName) async {
    final candidates = [
      appName,
      appName.replaceAll(' ', ''),
      appName.replaceAll('_', ''),
      appName.replaceAll(' ', '_'),
    ];
    for (final key in candidates) {
      try {
        final result = await Process.run(
          'reg',
          ['query', 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$key', '/v', 'DisplayVersion'],
        );
        if (result.exitCode == 0) {
          final stdout = result.stdout.toString();
          final match = RegExp(r'DisplayVersion\s+REG_SZ\s+(\S+)').firstMatch(stdout);
          if (match != null) return match.group(1);
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> getInstalledExecutablePath(String? executableName) async {
    if (executableName == null || executableName.isEmpty) return null;

    final sanitizedBase = executableName.replaceAll('.exe', '').trim();
    final noSepBase = sanitizedBase.replaceAll('_', '').replaceAll(' ', '').toLowerCase();

    for (final base in _baseDirs) {
      final directPath = '$base/$executableName';
      if (File(directPath).existsSync()) return directPath;

      final subfolderPath = '$base/$sanitizedBase/$executableName';
      if (File(subfolderPath).existsSync()) return subfolderPath;

      final normalizedSub = '$base/${sanitizedBase.replaceAll('_', ' ')}/$executableName';
      if (File(normalizedSub).existsSync()) return normalizedSub;

      final underscoreSub = '$base/${sanitizedBase.replaceAll(' ', '_')}/$executableName';
      if (File(underscoreSub).existsSync()) return underscoreSub;

      final noSepSub = '$base/${sanitizedBase.replaceAll('_', '').replaceAll(' ', '')}/$executableName';
      if (File(noSepSub).existsSync()) return noSepSub;

      if (noSepBase.contains('dashboard')) {
        final legacyPaths = [
          '$base/NexusDashboard/nexus_dashboard.exe',
          '$base/Nexus Dashboard/nexus_dashboard.exe',
          '$base/Nexus Dashboard/AntigravityDashboard.exe',
          '$base/NexusDashboard/AntigravityDashboard.exe',
        ];
        for (final p in legacyPaths) {
          if (File(p).existsSync()) return p;
        }
      }

      if (noSepBase.contains('spaceduel')) {
        final sdPaths = [
          '$base/Space Duel/Space Duel.exe',
          '$base/SpaceDuel/Space Duel.exe',
          '$base/Space_Duel/Space Duel.exe',
        ];
        for (final p in sdPaths) {
          if (File(p).existsSync()) return p;
        }
      }

      try {
        final dir = Directory(base);
        if (dir.existsSync()) {
          for (final entity in dir.listSync(followLinks: false)) {
            if (entity is Directory) {
              final folderName = entity.uri.pathSegments.reversed.skip(1).first.toLowerCase();
              final cleanFolder = folderName.replaceAll('_', '').replaceAll(' ', '');
              if (cleanFolder == noSepBase) {
                final cand = '${entity.path}/$executableName';
                if (File(cand).existsSync()) return cand;
                for (final sub in entity.listSync()) {
                  if (sub is File && sub.path.toLowerCase().endsWith('.exe')) {
                    final subName = sub.uri.pathSegments.last.toLowerCase();
                    if (!subName.contains('unins')) {
                      return sub.path;
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<bool> launchApp(AppItem app) async {
    if (Platform.isAndroid) {
      final pkg = app.android?.packageName;
      if (pkg == null || pkg.isEmpty) return false;
      final candidates = _getPackageCandidates(pkg);
      for (final candidate in candidates) {
        try {
          final res = await _androidChannel.invokeMethod<bool>(
            'launchApp',
            {'packageName': candidate},
          );
          if (res == true) return true;
        } catch (_) {}
      }
      return false;
    }

    final exec = app.windows?.executable;
    final path = await getInstalledExecutablePath(exec);
    if (path != null) {
      final dir = File(path).parent.path;
      await Process.start(path, [], workingDirectory: dir, mode: ProcessStartMode.detached);
      return true;
    }
    return false;
  }

  static Future<bool> uninstallApp(AppItem app) async {
    if (Platform.isAndroid) {
      final pkg = app.android?.packageName;
      if (pkg == null || pkg.isEmpty) return false;
      final candidates = _getPackageCandidates(pkg);
      for (final candidate in candidates) {
        try {
          final installed = await isAppInstalled(null, candidate);
          if (installed) {
            final res = await _androidChannel.invokeMethod<bool>(
              'uninstallApp',
              {'packageName': candidate},
            );
            return res ?? false;
          }
        } catch (_) {}
      }
      return false;
    }

    final exec = app.windows?.executable;
    final path = await getInstalledExecutablePath(exec);
    if (path == null) return false;

    final appDir = File(path).parent;

    // 1. Procurar desinstalador padrão (InnoSetup, NSIS, etc.)
    try {
      final files = appDir.listSync();
      for (final f in files) {
        if (f is File) {
          final name = f.uri.pathSegments.last.toLowerCase();
          if (name.startsWith('unins') || name.startsWith('uninstall')) {
            final proc = await Process.start(
              f.path,
              ['/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES', '/SP-', '/SILENT', '/S'],
              mode: ProcessStartMode.normal,
            );
            await proc.exitCode;

            _removeDesktopShortcut(app.name);
            return true;
          }
        }
      }
    } catch (_) {}

    // 2. Se for aplicativo portátil / executável direto
    try {
      if (appDir.existsSync()) {
        appDir.deleteSync(recursive: true);
      }
      _removeDesktopShortcut(app.name);
      return true;
    } catch (_) {}

    return false;
  }

  static void _removeDesktopShortcut(String appName) {
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return;

      final desktop = '$userProfile/Desktop';
      final names = [
        '$desktop/$appName.lnk',
        '$desktop/${appName.replaceAll('_', ' ')}.lnk',
        '$desktop/${appName.replaceAll(' ', '_')}.lnk',
      ];
      for (final n in names) {
        final f = File(n);
        if (f.existsSync()) f.deleteSync();
      }
    } catch (_) {}
  }
}