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

  static Future<bool> isAppInstalled(String? executableName, String? packageName) async {
    if (Platform.isAndroid) {
      if (packageName == null || packageName.isEmpty) return false;
      try {
        final res = await _androidChannel.invokeMethod<bool>(
          'isAppInstalled',
          {'packageName': packageName},
        );
        return res ?? false;
      } catch (_) {
        return false;
      }
    }

    final path = await getInstalledExecutablePath(executableName);
    return path != null;
  }

  static Future<String?> getInstalledVersion(String? executableName, String? packageName) async {
    if (Platform.isAndroid) {
      if (packageName == null || packageName.isEmpty) return null;
      try {
        final version = await _androidChannel.invokeMethod<String>(
          'getAppVersion',
          {'packageName': packageName},
        );
        return version;
      } catch (_) {
        return null;
      }
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
      }
    }

    return null;
  }

  static Future<String?> getInstalledExecutablePath(String? executableName) async {
    if (executableName == null || executableName.isEmpty) return null;

    final sanitizedBase = executableName.replaceAll('.exe', '').trim();

    for (final base in _baseDirs) {
      final directPath = '$base/$executableName';
      if (File(directPath).existsSync()) return directPath;

      final subfolderPath = '$base/$sanitizedBase/$executableName';
      if (File(subfolderPath).existsSync()) return subfolderPath;

      final normalizedSub = '$base/${sanitizedBase.replaceAll('_', ' ')}/$executableName';
      if (File(normalizedSub).existsSync()) return normalizedSub;

      final underscoreSub = '$base/${sanitizedBase.replaceAll(' ', '_')}/$executableName';
      if (File(underscoreSub).existsSync()) return underscoreSub;
    }

    return null;
  }

  static Future<bool> launchApp(AppItem app) async {
    if (Platform.isAndroid) {
      final pkg = app.android?.packageName;
      if (pkg == null || pkg.isEmpty) return false;
      try {
        final res = await _androidChannel.invokeMethod<bool>(
          'launchApp',
          {'packageName': pkg},
        );
        return res ?? false;
      } catch (_) {
        return false;
      }
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
      try {
        final res = await _androidChannel.invokeMethod<bool>(
          'uninstallApp',
          {'packageName': pkg},
        );
        return res ?? false;
      } catch (_) {
        return false;
      }
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