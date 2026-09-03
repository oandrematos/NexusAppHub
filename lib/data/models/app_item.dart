
class AppItem {
  final String id;
  final String name;
  final String title;
  final String category;
  final String categoryName;
  final String icon;
  final String badge;
  final bool featured;
  final String description;
  final String shortDescription;
  final List<String> platformsSupported;
  final PlatformConfig? windows;
  final PlatformConfig? android;
  final List<String>? latestChangelog;
  final List<String>? screenshots;

  AppItem({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.categoryName,
    required this.icon,
    required this.badge,
    required this.featured,
    required this.description,
    required this.shortDescription,
    required this.platformsSupported,
    this.windows,
    this.android,
    this.latestChangelog,
    this.screenshots,
  });

  bool isAvailableOn(bool isAndroid) {
    if (isAndroid) {
      return platformsSupported.contains('android') && android != null;
    } else {
      return platformsSupported.contains('windows') && windows != null;
    }
  }

  String? getFilename(bool isAndroid) {
    return isAndroid ? android?.filename : windows?.filename;
  }

  double? getSizeMb(bool isAndroid) {
    return isAndroid ? android?.sizeMb : windows?.sizeMb;
  }

  String? getVersion(bool isAndroid) {
    return isAndroid ? android?.version : windows?.version;
  }

  String getActionText(bool isAndroid, bool isInstalled) {
    if (!isAvailableOn(isAndroid)) {
      return isAndroid ? 'Indisponível no Celular' : 'Apenas para Celular';
    }
    return isInstalled ? 'Abrir' : 'Instalar';
  }

  factory AppItem.fromJson(Map<String, dynamic> json) {
    List<String> parsePlatforms(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().toLowerCase()).toList();
      } else if (val is String) {
        return val.toLowerCase().split(' ');
      }
      return ['windows'];
    }

    return AppItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'tools',
      categoryName: json['category_name'] ?? 'Utilitários',
      icon: json['icon'] ?? '📦',
      badge: json['badge'] ?? '',
      featured: json['featured'] ?? false,
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      platformsSupported: parsePlatforms(json['platforms_supported']),
      windows: json['windows'] != null ? PlatformConfig.fromJson(json['windows']) : null,
      android: json['android'] != null ? PlatformConfig.fromJson(json['android']) : null,
      latestChangelog: json['latest_changelog'] != null
          ? List<String>.from(json['latest_changelog'])
          : null,
      screenshots: json['screenshots'] != null
          ? List<String>.from(json['screenshots'])
          : null,
    );
  }
}

class PlatformConfig {
  final String filename;
  final double sizeMb;
  final String version;
  final String? executable;
  final String? packageName;

  PlatformConfig({
    required this.filename,
    required this.sizeMb,
    required this.version,
    this.executable,
    this.packageName,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      filename: json['filename'] ?? '',
      sizeMb: (json['size_mb'] is num) ? (json['size_mb'] as num).toDouble() : 0.0,
      version: json['version'] ?? '',
      executable: json['executable'],
      packageName: json['package_name'],
    );
  }
}