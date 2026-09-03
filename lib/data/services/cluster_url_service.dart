class ClusterUrlService {
  static const String githubRawBase =
      'https://raw.githubusercontent.com/oandrematos/NexusAppHub/main/assets/showcase';

  /// Mapeia URLs para o caminho correspondente dos assets locais embutidos (0ms de carregamento).
  static String? getLocalAssetPath(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    // Se já for um caminho relativo de asset local
    if (clean.startsWith('assets/')) return clean;

    // Se for URL remota (GitHub, S1, S2), extrai a chave a partir de /showcase/
    if (clean.contains('assets/showcase/')) {
      final idx = clean.indexOf('assets/showcase/');
      return clean.substring(idx);
    }
    if (clean.contains('showcase/')) {
      final idx = clean.indexOf('showcase/');
      return 'assets/${clean.substring(idx)}';
    }

    return null;
  }

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
      if (path.startsWith('/installers/assets/showcase/')) {
        path = path.substring('/installers/assets/showcase/'.length);
      } else if (path.startsWith('/installers/assets/')) {
        path = path.substring('/installers/assets/'.length);
      } else if (path.startsWith('/assets/showcase/')) {
        path = path.substring('/assets/showcase/'.length);
      } else if (path.startsWith('/assets/')) {
        path = path.substring('/assets/'.length);
      } else if (path.startsWith('/')) {
        path = path.substring(1);
      }
      return '$githubRawBase/$path';
    }

    return clean;
  }
}