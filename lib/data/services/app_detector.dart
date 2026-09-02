import 'dart:io';

class AppDetector {
  static Future<bool> isAppInstalled(String? executableName, String? packageName) async {
    if (Platform.isAndroid) {
      return false;
    }

    if (executableName == null || executableName.isEmpty) return false;

    final localAppData = Platform.environment['LOCALAPPDATA'];
    final programFiles = Platform.environment['ProgramFiles'];
    final programFilesX86 = Platform.environment['ProgramFiles(x86)'];

    final checkPaths = [
      if (localAppData != null) '$localAppData/Programs/$executableName',
      if (localAppData != null) '$localAppData/Programs/${executableName.replaceAll(".exe", "")}/$executableName',
      if (programFiles != null) '$programFiles/$executableName',
      if (programFiles != null) '$programFiles/${executableName.replaceAll(".exe", "")}/$executableName',
      if (programFilesX86 != null) '$programFilesX86/$executableName',
      if (programFilesX86 != null) '$programFilesX86/${executableName.replaceAll(".exe", "")}/$executableName',
      'C:/Games/$executableName',
      'D:/Games/$executableName',
    ];

    for (final p in checkPaths) {
      if (File(p).existsSync()) return true;
    }
    return false;
  }
}