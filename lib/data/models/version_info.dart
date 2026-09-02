class VersionInfo {
  final String currentVersion;
  final String? latestVersion;
  final String? updateUrl;
  final List<String> changelog;

  VersionInfo({
    required this.currentVersion,
    this.latestVersion,
    this.updateUrl,
    this.changelog = const [],
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      currentVersion: json['version'] ?? '0.3.0',
      latestVersion: json['latest_version'],
      updateUrl: json['update_url'],
      changelog: json['changelog'] != null
          ? List<String>.from(json['changelog'])
          : const [],
    );
  }
}