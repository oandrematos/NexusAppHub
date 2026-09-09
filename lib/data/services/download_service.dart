import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class DownloadService {
  static const List<String> clusterEndpoints = [
    'http://192.168.0.246/installers',   // S2 (Wi-Fi Doméstico Casa Real - Menor Latência)
    'http://192.168.196.101/installers', // S1 (ZeroTier / Nuvem)
    'http://100.84.133.101/installers',  // S1 (Tailscale)
    'https://github.com/oandrematos/NexusAppHub/releases/latest/download', // GitHub CDN Global
  ];

  Future<void> downloadAndInstall({
    required String filename,
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
    required Function(String error) onError,
    required Function() onCompleted,
  }) async {
    final isAndroid = Platform.isAndroid;
    Directory tempDir;
    if (isAndroid) {
      tempDir = (await getExternalStorageDirectory()) ?? await getTemporaryDirectory();
    } else {
      tempDir = await getTemporaryDirectory();
    }

    final targetFile = File('${tempDir.path}/$filename');
    if (targetFile.existsSync()) {
      try { targetFile.deleteSync(); } catch (_) {}
    }

    bool success = false;

    // 1. PRIORIDADE ZERO-LATÊNCIA NO DESKTOP: Repositório Local de Instaladores (OneDrive e Drive W:)
    if (!isAndroid) {
      final localCandidates = [
        Directory(r'D:\OneDrive\Antigravity Projects\Installers'),
        Directory(r'W:\Installers'),
        Directory(r'W:\Antigravity Projects\Installers'),
      ];
      for (final dir in localCandidates) {
        final localFile = File('${dir.path}/$filename');
        if (localFile.existsSync() && localFile.lengthSync() > 0) {
          final totalBytes = localFile.lengthSync();
          onStatus('Obtendo do repositório local (${dir.path})...');
          try {
            int copiedBytes = 0;
            final reader = localFile.openRead();
            final sink = targetFile.openWrite();
            int lastEmit = 0;

            await for (final chunk in reader) {
              sink.add(chunk);
              copiedBytes += chunk.length;
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastEmit >= 32 || copiedBytes == totalBytes) {
                lastEmit = now;
                final prog = totalBytes > 0 ? (copiedBytes / totalBytes) : 0.5;
                onProgress(prog);
                final mbCopied = (copiedBytes / (1024 * 1024)).toStringAsFixed(1);
                final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                onStatus('Copiando: $mbCopied MB / $mbTotal MB (${(prog * 100).toInt()}%)');
              }
            }
            await sink.flush();
            await sink.close();

            onProgress(1.0);
            success = true;
            break;
          } catch (_) {}
        }
      }
    }

    if (!success) {
      // Codificar URL para suportar nomes com espaços (ex: "Space Duel_Android_v1.1.0.apk")
      final safeUrlFilename = Uri.encodeComponent(filename).replaceAll('+', '%20');

      for (final base in clusterEndpoints) {
        try {
          // GitHub Releases converte espaços em pontos (ex: "Space Duel.exe" -> "Space.Duel.exe")
          final isGitHub = base.contains('github.com');
          final targetFilename = isGitHub ? filename.replaceAll(' ', '.') : safeUrlFilename;

          final uri = Uri.parse('$base/$targetFilename');
          onStatus('Conectando ao nó do cluster ($base)...');

          final client = http.Client();
          final request = http.Request('GET', uri);
          var response = await client.send(request).timeout(const Duration(seconds: 8));

          // Suporte explícito a múltiplos redirecionamentos (ex: GitHub Releases 302 -> AWS S3 / Azure CDN)
          int redirectCount = 0;
          while ((response.statusCode == 301 ||
                  response.statusCode == 302 ||
                  response.statusCode == 307 ||
                  response.statusCode == 308) &&
              redirectCount < 5) {
            final loc = response.headers['location'];
            if (loc == null || loc.isEmpty) break;
            final redirectReq = http.Request('GET', Uri.parse(loc));
            response = await client.send(redirectReq).timeout(const Duration(seconds: 10));
            redirectCount++;
          }

          if (response.statusCode == 200) {
            final totalBytes = response.contentLength ?? 0;
            int receivedBytes = 0;
            final sink = targetFile.openWrite();

            int lastEmitTime = 0;
            await for (final chunk in response.stream) {
              sink.add(chunk);
              receivedBytes += chunk.length;
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastEmitTime >= 32 || receivedBytes == totalBytes) {
                lastEmitTime = now;
                if (totalBytes > 0) {
                  final prog = receivedBytes / totalBytes;
                  onProgress(prog);
                  final mbRec = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                  final mbTot = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                  onStatus('Baixando: $mbRec MB / $mbTot MB (${(prog * 100).toInt()}%)');
                } else {
                  final mbRec = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                  onStatus('Baixando: $mbRec MB...');
                }
              }
            }

            await sink.flush();
            await sink.close();
            client.close();
            success = true;
            break;
          } else {
            client.close();
          }
        } catch (e) {
          // Tenta o próximo endpoint silenciosamente
        }
      }
    }

    if (!success) {
      onError('Falha ao obter $filename dos servidores do cluster.');
      return;
    }

    onStatus('Iniciando instalação...');
    onProgress(1.0);

    try {
      if (isAndroid) {
        bool installed = false;
        try {
          const channel = MethodChannel('com.antigravity.nexus_app_hub/app_manager');
          await channel.invokeMethod('installApk', {'filePath': targetFile.path});
          installed = true;
        } catch (e) {
          // Fallback para OpenFilex se o canal customizado reportar exceção
          try {
            final res = await OpenFilex.open(
              targetFile.path,
              type: 'application/vnd.android.package-archive',
            );
            if (res.type == ResultType.done) {
              installed = true;
            } else {
              onError('Erro ao abrir o instalador: ${res.message}');
              return;
            }
          } catch (err) {
            onError('Falha ao acionar instalador do Android: $err');
            return;
          }
        }
        if (!installed) {
          onError('Não foi possível iniciar a instalação do APK.');
          return;
        }
      } else if (Platform.isLinux) {
        final lower = filename.toLowerCase();
        if (lower.endsWith('.deb')) {
          onStatus('Instalando pacote DEB nativo via PolicyKit (apt)...');
          final proc = await Process.start('pkexec', ['apt-get', 'install', '-y', targetFile.path]);
          final exitCode = await proc.exitCode;
          if (exitCode != 0) {
            onStatus('Aplicando dependências via dpkg/apt-get...');
            final dpkgProc = await Process.start('pkexec', ['dpkg', '-i', targetFile.path]);
            await dpkgProc.exitCode;
            final fixProc = await Process.start('pkexec', ['apt-get', 'install', '-f', '-y']);
            await fixProc.exitCode;
          }
        } else if (lower.endsWith('.sh') || lower.endsWith('.run')) {
          onStatus('Executando script de instalação com privilégios...');
          await Process.run('chmod', ['+x', targetFile.path]);
          final proc = await Process.start('pkexec', [targetFile.path]);
          await proc.exitCode;
        } else if (lower.endsWith('.appimage')) {
          onStatus('Instalando AppImage em ~/Applications...');
          await Process.run('chmod', ['+x', targetFile.path]);
          final home = Platform.environment['HOME'] ?? '/home';
          final appDir = Directory('$home/Applications');
          if (!appDir.existsSync()) appDir.createSync(recursive: true);
          final dest = File('${appDir.path}/$filename');
          targetFile.copySync(dest.path);
          await Process.run('chmod', ['+x', dest.path]);
        } else {
          final home = Platform.environment['HOME'] ?? '/home';
          final binDir = Directory('$home/.local/bin');
          if (!binDir.existsSync()) binDir.createSync(recursive: true);
          final dest = File('${binDir.path}/$filename');
          targetFile.copySync(dest.path);
          await Process.run('chmod', ['+x', dest.path]);
        }
      } else {
        final lower = filename.toLowerCase();
        bool isInstaller = lower.contains('installer') ||
            lower.contains('setup') ||
            lower.contains('_x64.exe') ||
            lower.contains('space duel');

        if (!isInstaller) {
          try {
            final bytes = targetFile.readAsBytesSync();
            final str = String.fromCharCodes(bytes.take(2000000));
            if (str.contains('Nullsoft') || str.contains('Inno Setup') || str.contains('WiseMain')) {
              isInstaller = true;
            }
          } catch (_) {}
        }

        if (isInstaller) {
          final lowerF = filename.toLowerCase();
          final isSelfUpdate = lowerF.contains('nexusapphub') || lowerF.contains('nexus_app_hub');

          if (isSelfUpdate) {
            // Atualização da própria loja: dispara o instalador silencioso desacoplado no Shell do Windows
            await Process.start(
              'cmd.exe',
              ['/c', 'start', '""', targetFile.path, '/S'],
              mode: ProcessStartMode.detached,
            );
            await Future.delayed(const Duration(milliseconds: 600));
            exit(0);
          } else {
            // Flags otimizadas e limpas para cada tipo de instalador
            List<String> silentArgs = ['/S'];
            try {
              final bytes = targetFile.readAsBytesSync();
              final header = String.fromCharCodes(bytes.take(1000000));
              if (header.contains('Inno Setup')) {
                silentArgs = ['/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES', '/SP-'];
              } else if (header.contains('Nullsoft')) {
                silentArgs = ['/S'];
              }
            } catch (_) {}

            int exitCode = -1;
            try {
              onStatus('Instalando ${filename.replaceAll('.exe', '')}...');
              final proc = await Process.start(
                targetFile.path,
                silentArgs,
                workingDirectory: targetFile.parent.path,
                mode: ProcessStartMode.normal,
              );
              exitCode = await proc.exitCode;
            } catch (_) {}

            // Se o instalador silencioso falhar ou retornar código de erro, dispara interativo via Shell do Windows
            if (exitCode != 0) {
              await Process.start(
                'cmd.exe',
                ['/c', 'start', '""', targetFile.path],
                mode: ProcessStartMode.detached,
              );
            }
          }
        } else {
          final localAppData = Platform.environment['LOCALAPPDATA'] ?? 'C:/Users/Andre/AppData/Local';
          final appBaseName = filename.replaceAll('.exe', '').split('_')[0].trim();
          final installDir = Directory('$localAppData/Programs/$appBaseName');
          if (!installDir.existsSync()) installDir.createSync(recursive: true);
          final targetDest = File('${installDir.path}/$filename');
          targetFile.copySync(targetDest.path);
        }
      }
      onCompleted();
    } catch (e) {
      onError('Erro ao executar a instalação: $e');
    }
  }
}