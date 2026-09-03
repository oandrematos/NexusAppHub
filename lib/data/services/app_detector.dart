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

  static final Map<String, String?> _pathCache = {};
  static final Map<String, String?> _versionCache = {};
  static final Map<String, String?> _fileVerCache = {};

  static void clearCache() {
    _pathCache.clear();
    _versionCache.clear();
    _fileVerCache.clear();
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

    if (executableName == null || executableName.isEmpty) return false;
    if (_pathCache.containsKey(executableName)) {
      final cached = _pathCache[executableName];
      if (cached != null) {
        if (File(cached).existsSync()) {
          return true;
        } else {
          _pathCache[executableName] = null;
          _versionCache[executableName] = null;
          return false;
        }
      }
      return false;
    }

    final path = await getInstalledExecutablePath(executableName);
    _pathCache[executableName] = path;
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

      if (_versionCache.containsKey(executableName)) {
        return _versionCache[executableName];
      }

      final execPath = await getInstalledExecutablePath(executableName);
      if (execPath != null) {
        final dir = File(execPath).parent;
        final vFile = File('${dir.path}/version.json');
        if (vFile.existsSync()) {
          try {
            final content = vFile.readAsStringSync();
            final match = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(content);
            if (match != null) {
              _versionCache[executableName] = match.group(1);
              return match.group(1);
            }
          } catch (_) {}
        }

        final baseName = File(execPath).uri.pathSegments.last.replaceAll('.exe', '');
        final regVer = await _getWindowsRegistryVersion(baseName);
        if (regVer != null) {
          _versionCache[executableName] = regVer;
          return regVer;
        }

        final fileVer = await _getFileVersion(execPath);
        if (fileVer != null) {
          _versionCache[executableName] = fileVer;
          return fileVer;
        }
      }
    }

    _versionCache[executableName ?? ''] = null;
    return null;
  }

  static final Map<String, List<String>> _knownApplicationPaths = {
    'chrome.exe': [
      r'C:\Program Files\Google\Chrome\Application\chrome.exe',
      r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Google\\Chrome\\Application\\chrome.exe',
    ],
    'firefox.exe': [
      r'C:\Program Files\Mozilla Firefox\firefox.exe',
      r'C:\Program Files (x86)\Mozilla Firefox\firefox.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Mozilla Firefox\\firefox.exe',
    ],
    'tailscale-ipn.exe': [
      r'C:\Program Files\Tailscale\tailscale-ipn.exe',
      r'C:\Program Files\Tailscale\tailscale.exe',
      r'C:\Program Files (x86)\Tailscale IPN\tailscale-ipn.exe',
    ],
    'tailscale.exe': [
      r'C:\Program Files\Tailscale\tailscale.exe',
      r'C:\Program Files\Tailscale\tailscale-ipn.exe',
    ],
    'zerotier_desktop_ui.exe': [
      r'C:\Program Files (x86)\ZeroTier\One\zerotier_desktop_ui.exe',
      r'C:\Program Files\ZeroTier\One\zerotier_desktop_ui.exe',
    ],
    'parsecd.exe': [
      r'C:\Program Files\Parsec\parsecd.exe',
      r'C:\Program Files\Parsec\parsec.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Parsec\\parsecd.exe',
    ],
    'ep_setup.exe': [
      r'C:\Program Files\ExplorerPatcher\ep_setup.exe',
    ],
    'devenv.exe': [
      r'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\devenv.exe',
      r'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe',
      r'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe',
      r'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe',
      r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe',
    ],
    'anydesk.exe': [
      r'C:\Program Files (x86)\AnyDesk\AnyDesk.exe',
      r'C:\Program Files\AnyDesk\AnyDesk.exe',
      if (Platform.environment['APPDATA'] != null)
        '${Platform.environment['APPDATA']}\\AnyDesk\\AnyDesk.exe',
    ],
    '7+ taskbar tweaker.exe': [
      r'C:\Program Files\7+ Taskbar Tweaker\7+ Taskbar Tweaker.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\7+ Taskbar Tweaker\\7+ Taskbar Tweaker.exe',
    ],
    'sharex.exe': [
      r'C:\Program Files\ShareX\ShareX.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\ShareX\\ShareX.exe',
    ],
    'vlc.exe': [
      r'C:\Program Files\VideoLAN\VLC\vlc.exe',
      r'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe',
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\VLC\\vlc.exe',
    ],
    'notepad++.exe': [
      r'C:\Program Files\Notepad++\notepad++.exe',
      r'C:\Program Files (x86)\Notepad++\notepad++.exe',
    ],
    'winrar.exe': [
      r'C:\Program Files\WinRAR\WinRAR.exe',
      r'C:\Program Files (x86)\WinRAR\WinRAR.exe',
    ],
    'threadsdl.exe': [
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\ThreadsDL\\ThreadsDL.exe',
    ],
    'smirror.exe': [
      if (Platform.environment['LOCALAPPDATA'] != null)
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\Smirror\\Smirror.exe',
    ],
  };

  static Future<String?> _queryAppPathRegistry(String executableName) async {
    final hives = [
      'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\$executableName',
      'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\$executableName',
    ];
    for (final hive in hives) {
      try {
        final res = await Process.run('reg', ['query', hive, '/ve']);
        if (res.exitCode == 0) {
          final stdout = res.stdout.toString();
          final match = RegExp(r'REG_SZ\s+(.+)$', multiLine: true).firstMatch(stdout);
          if (match != null) {
            String path = match.group(1)!.trim();
            if (path.startsWith('"') && path.endsWith('"')) {
              path = path.substring(1, path.length - 1);
            }
            if (File(path).existsSync()) return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _getFileVersion(String path) async {
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "\$item = Get-Item -LiteralPath '$path'; \$v = \$item.VersionInfo.FileVersion; if (!\$v) { \$v = \$item.VersionInfo.ProductVersion }; \$v",
      ]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _getWindowsRegistryVersion(String appName) async {
    final candidates = [
      appName,
      appName.replaceAll(' ', ''),
      appName.replaceAll('_', ''),
      appName.replaceAll(' ', '_'),
    ];
    final hives = [
      'HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
      'HKLM\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
      'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
    ];

    for (final hive in hives) {
      for (final key in candidates) {
        try {
          final result = await Process.run(
            'reg',
            ['query', '$hive\\$key', '/v', 'DisplayVersion'],
          );
          if (result.exitCode == 0) {
            final stdout = result.stdout.toString();
            final match = RegExp(r'DisplayVersion\s+REG_SZ\s+(.+)$', multiLine: true).firstMatch(stdout);
            if (match != null) {
              String raw = match.group(1)!.trim();
              raw = raw.replaceAll(RegExp(r'^[a-zA-Z\s]+'), '').trim();
              if (raw.isNotEmpty) return raw;
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static Future<String?> getInstalledExecutablePath(String? executableName) async {
    if (executableName == null || executableName.isEmpty) return null;

    final lowerExe = executableName.toLowerCase();

    // 1. Verificação em caminhos conhecidos de softwares corporativos e padrões de mercado
    if (_knownApplicationPaths.containsKey(lowerExe)) {
      for (final p in _knownApplicationPaths[lowerExe]!) {
        if (File(p).existsSync()) return p;
      }
    }

    // 2. Consulta direta à tabela de App Paths do Registro do Windows
    final appPath = await _queryAppPathRegistry(executableName);
    if (appPath != null) return appPath;

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