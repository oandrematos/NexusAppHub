import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class DownloadService {
  static const List<String> clusterEndpoints = [
    'http://192.168.196.101/installers', // S1 (ZeroTier / Nuvem)
    'http://192.168.196.102/installers', // S2 (ZeroTier / Nuvem)
    'http://192.168.0.205/installers',   // S2 (Wi-Fi Doméstico)
    'http://192.168.100.166/installers', // S1 (Wi-Fi Escritório)
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
    // Codificar URL para suportar nomes com espaços (ex: "Space Duel_Android_v1.1.0.apk")
    final safeUrlFilename = Uri.encodeComponent(filename).replaceAll('+', '%20');

    for (final base in clusterEndpoints) {
      try {
        final uri = Uri.parse('$base/$safeUrlFilename');
        onStatus('Conectando ao nó do cluster...');

        final client = http.Client();
        final request = http.Request('GET', uri);
        final response = await client.send(request).timeout(const Duration(seconds: 4));

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

    if (!success) {
      onError('Falha no download dos servidores do cluster.');
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
        await Process.start(targetFile.path, [], mode: ProcessStartMode.detached);
      }
      onCompleted();
    } catch (e) {
      onError('Erro ao executar o instalador: $e');
    }
  }
}