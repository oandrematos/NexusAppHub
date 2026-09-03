class ClusterUrlService {
  static const String githubRawBase =
      'https://raw.githubusercontent.com/oandrematos/NexusAppHub/main/assets/showcase';

  /// Normaliza URLs de imagens. Se a URL contiver IPs privados ou VPNs (100.84 ou 192.168),
  /// mapeia transparentemente para o CDN Global do GitHub, permitindo carregamento veloz em
  /// redes móveis (4G/5G) e Wi-Fi sem dependência de VPN ativa.
  static String? resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    if (clean.startsWith('https://') &&
        !clean.contains('100.84.') &&
        !clean.contains('192.168.')) {
      return clean;
    }

    final uri = Uri.tryParse(clean);
    if (uri != null) {
      String path = uri.path;
      if (path.startsWith('/installers/assets/')) {
        path = path.substring('/installers/assets/'.length);
      } else if (path.startsWith('/assets/')) {
        path = path.substring('/assets/'.length);
      } else if (path.startsWith('/')) {
        path = path.substring(1);
      }
      return '/';
    }

    return clean;
  }
}