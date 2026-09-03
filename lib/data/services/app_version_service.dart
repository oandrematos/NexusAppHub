import 'dart:convert';
import 'package:flutter/services.dart';

class AppVersionService {
  static String currentVersion = '0.3.11';
  static int currentBuild = 14;

  static Future<void> init() async {
    try {
      final data = await rootBundle.loadString('assets/nexus_version.json');
      final json = jsonDecode(data);
      if (json['version'] != null) {
        currentVersion = json['version'].toString();
      }
      if (json['build'] != null) {
        currentBuild = int.tryParse(json['build'].toString()) ?? currentBuild;
      }
    } catch (_) {}
  }
}