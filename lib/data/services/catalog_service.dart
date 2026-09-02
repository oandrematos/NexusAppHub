import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/app_item.dart';

class CatalogService {
  static const List<String> clusterCatalogUrls = [
    'http://192.168.0.246/installers/software_catalog.json',   // S2 (Wi-Fi Doméstico Casa Real)
    'http://192.168.196.101/installers/software_catalog.json', // S1 (ZeroTier)
    'http://192.168.196.102/installers/software_catalog.json', // S2 (ZeroTier)
    'http://100.84.133.101/installers/software_catalog.json',  // S1 (Tailscale)
    'http://100.104.81.102/installers/software_catalog.json',  // S2 (Tailscale)
    'http://192.168.100.166/installers/software_catalog.json', // S1 (Wi-Fi Escritório)
  ];

  Future<List<AppItem>> loadCatalog() async {
    for (final url in clusterCatalogUrls) {
      try {
        final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (resp.statusCode == 200) {
          final data = json.decode(utf8.decode(resp.bodyBytes));
          if (data['apps'] != null) {
            return (data['apps'] as List).map((i) => AppItem.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }

    // Fallback local do asset
    final localData = await rootBundle.loadString('assets/software_catalog.json');
    final data = json.decode(localData);
    return (data['apps'] as List).map((i) => AppItem.fromJson(i)).toList();
  }
}