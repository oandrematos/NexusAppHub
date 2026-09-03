import 'dart:convert';
import 'dart:io';

class PackageItem {
  final String id;
  final String name;
  final String version;
  final String source; // 'winget' | 'chocolatey'
  final String? description;

  PackageItem({
    required this.id,
    required this.name,
    required this.version,
    required this.source,
    this.description,
  });
}

class PackageManagerService {
  static bool? _hasWinget;
  static bool? _hasChoco;

  static Future<bool> isWingetAvailable() async {
    if (_hasWinget != null) return _hasWinget!;
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('where.exe', ['winget']);
      _hasWinget = res.exitCode == 0;
    } catch (_) {
      _hasWinget = false;
    }
    return _hasWinget!;
  }

  static Future<bool> isChocoAvailable() async {
    if (_hasChoco != null) return _hasChoco!;
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('where.exe', ['choco']);
      _hasChoco = res.exitCode == 0;
    } catch (_) {
      _hasChoco = false;
    }
    return _hasChoco!;
  }

  static Future<List<PackageItem>> searchWinget(String query) async {
    if (!Platform.isWindows || query.trim().isEmpty) return [];
    final available = await isWingetAvailable();
    if (!available) return [];

    try {
      final res = await Process.run(
        'winget',
        ['search', query.trim(), '--accept-source-agreements'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (res.exitCode != 0) return [];
      final lines = res.stdout.toString().split(RegExp(r'\r?\n'));
      final results = <PackageItem>[];

      bool foundHeader = false;
      for (final line in lines) {
        if (line.contains('---') || line.contains('Nome') || line.contains('Name')) {
          foundHeader = true;
          continue;
        }
        if (!foundHeader || line.trim().isEmpty) continue;

        // Formato típico: Name     Id     Version     Match     Source
        final parts = line.split(RegExp(r'\s{2,}'));
        if (parts.length >= 3) {
          final name = parts[0].trim();
          final id = parts[1].trim();
          final version = parts[2].trim();
          if (id.isNotEmpty && !id.contains('---')) {
            results.add(PackageItem(
              id: id,
              name: name,
              version: version,
              source: 'winget',
            ));
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  static Future<List<PackageItem>> searchChoco(String query) async {
    if (!Platform.isWindows || query.trim().isEmpty) return [];
    final available = await isChocoAvailable();
    if (!available) return [];

    try {
      // Usando -r para obter formato delimitado por pipe (id|version)
      final res = await Process.run(
        'choco',
        ['search', query.trim(), '-r'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (res.exitCode != 0) return [];
      final lines = res.stdout.toString().split(RegExp(r'\r?\n'));
      final results = <PackageItem>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length >= 2) {
          final id = parts[0].trim();
          final version = parts[1].trim();
          results.add(PackageItem(
            id: id,
            name: id,
            version: version,
            source: 'chocolatey',
          ));
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> installPackage({
    required String packageId,
    required String source,
    required Function(String status) onStatus,
  }) async {
    if (!Platform.isWindows) return false;

    try {
      if (source == 'winget') {
        onStatus('Iniciando instalação via Windows Package Manager (Winget)...');
        final proc = await Process.start(
          'winget',
          ['install', '--id', packageId, '--silent', '--accept-source-agreements', '--accept-package-agreements'],
          mode: ProcessStartMode.normal,
        );

        proc.stdout.transform(utf8.decoder).listen((data) {
          final clean = data.trim();
          if (clean.isNotEmpty) onStatus('Winget: $clean');
        });

        final exitCode = await proc.exitCode;
        return exitCode == 0;
      } else if (source == 'chocolatey') {
        onStatus('Iniciando instalação via Chocolatey...');
        final proc = await Process.start(
          'choco',
          ['install', packageId, '-y'],
          mode: ProcessStartMode.normal,
        );

        proc.stdout.transform(utf8.decoder).listen((data) {
          final clean = data.trim();
          if (clean.isNotEmpty) onStatus('Choco: $clean');
        });

        final exitCode = await proc.exitCode;
        return exitCode == 0;
      }
    } catch (e) {
      onStatus('Erro ao executar gerenciador de pacotes: $e');
    }

    return false;
  }
}