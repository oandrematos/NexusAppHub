import 'dart:io';
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

    // 1. PRIORIDADE ZERO-LATÊNCIA NO DESKTOP: Repositório Local de Instaladores
    if (!isAndroid) {
      final localInstallersDir = Directory(r'D:\OneDrive\Antigravity Projects\Installers');
      final localFile = File('${localInstallersDir.path}/$filename');
      if (localFile.existsSync() && localFile.lengthSync() > 0) {
        onStatus('Obtendo do repositório local de instaladores...');
        onProgress(0.5);
        try {
          await localFile.copy(targetFile.path);
          onProgress(1.0);
          success = true;
        } catch (_) {}
      }
    }

    if (!success) {
      // Codificar URL para suportar nomes com espaços (ex: "Space Duel_Android_v1.1.0.apk")
      final safeUrlFilename = Uri.encodeComponent(filename).replaceAll('+', '%20');

      for (final base in clusterEndpoints) {
        try {
          final uri = Uri.parse('$base/$safeUrlFilename');
          onStatus('Conectando ao nó do cluster ($base)...');

          final client = http.Client();
          final request = http.Request('GET', uri);
          var response = await client.send(request).timeout(const Duration(seconds: 5));

          // Suporte explícito a redirecionamentos (ex: GitHub Releases 302 para AWS S3)
          if (response.statusCode == 301 || response.statusCode == 302) {
            final loc = response.headers['location'];
            if (loc != null) {
              final redirectReq = http.Request('GET', Uri.parse(loc));
              response = await client.send(redirectReq).timeout(const Duration(seconds: 5));
            }
          }

          if (response.statusCode == 200) {
            final totalBytes = response.contentLength ?? 0;
            int receivedBytes = 0;
            final sink = targetFile.openWrite();

            await for (final chunk in response.stream) {
              sink.add(chunk);
              receivedBytes += chunk.length;
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
        final res = await OpenFilex.open(
          targetFile.path,
          type: 'application/vnd.android.package-archive',
        );
        if (res.type != ResultType.done) {
          onError('Erro ao abrir o instalador: ${res.message}');
          return;
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
            // Atualização da própria loja: abre a interface visual do instalador
            // e encerra a loja para liberar os arquivos para a nova instalação.
            await Process.start(
              targetFile.path,
              [],
              mode: ProcessStartMode.detached,
            );
            await Future.delayed(const Duration(milliseconds: 500));
            exit(0);
          } else {
            final proc = await Process.start(
              targetFile.path,
              ['/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES', '/SP-', '/SILENT', '/S', '/qn', '/quiet'],
              mode: ProcessStartMode.normal,
            );
            await proc.exitCode;
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