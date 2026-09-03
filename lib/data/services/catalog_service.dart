import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/app_item.dart';

class CatalogService {
  static const List<String> clusterCatalogUrls = [
    'https://raw.githubusercontent.com/oandrematos/NexusAppHub/main/assets/software_catalog.json', // Global CDN (Universal e sempre atualizado)
    'http://192.168.0.246/installers/software_catalog.json',   // S2 (Wi-Fi Doméstico Casa Real)
    'http://192.168.196.101/installers/software_catalog.json', // S1 (ZeroTier)
    'http://100.84.133.101/installers/software_catalog.json',  // S1 (Tailscale)
  ];

  // Carregamento instantâneo do asset local em 0ms
  Future<List<AppItem>> loadLocalCatalog() async {
    try {
      final localData = await rootBundle.loadString('assets/software_catalog.json');
      final data = json.decode(localData);
      return (data['apps'] as List).map((i) => AppItem.fromJson(i)).toList();
    } catch (_) {
      return [];
    }
  }

  // Sincronização remota em background com timeout curto (1.5s)
  Future<List<AppItem>?> fetchRemoteCatalog() async {
    for (final url in clusterCatalogUrls) {
      try {
        final cacheBusterUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
        final resp = await http.get(
          Uri.parse(cacheBusterUrl),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ).timeout(const Duration(milliseconds: 1500));
        if (resp.statusCode == 200) {
          final data = json.decode(utf8.decode(resp.bodyBytes));
          if (data['apps'] != null) {
            return (data['apps'] as List).map((i) => AppItem.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // Compatibilidade com método antigo
  Future<List<AppItem>> loadCatalog() async {
    final local = await loadLocalCatalog();
    if (local.isNotEmpty) return local;
    final remote = await fetchRemoteCatalog();
    return remote ?? [];
  }
}