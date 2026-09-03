import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../data/services/cluster_url_service.dart';
import '../core/app_colors.dart';

class ClusterImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const ClusterImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  @override
  State<ClusterImage> createState() => _ClusterImageState();
}

class _ClusterImageState extends State<ClusterImage> {
  static final Map<String, File> _diskCache = {};
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _checkDiskCache();
  }

  @override
  void didUpdateWidget(covariant ClusterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cachedFile = null;
      _checkDiskCache();
    }
  }

  String _generateCacheKey(String url) {
    return base64Url.encode(utf8.encode(url)).replaceAll('=', '');
  }

  Future<void> _checkDiskCache() async {
    final localAsset = ClusterUrlService.getLocalAssetPath(widget.url);
    if (localAsset != null) {
      // Se for asset local embutido, a prioridade máxima é 0ms via Image.asset
      return;
    }

    final resolved = ClusterUrlService.resolveImageUrl(widget.url);
    if (resolved == null) return;

    final key = _generateCacheKey(resolved);
    if (_diskCache.containsKey(key)) {
      if (mounted) setState(() => _cachedFile = _diskCache[key]);
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/nexus_img_cache');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      final file = File('${cacheDir.path}/$key');
      if (await file.exists() && (await file.length()) > 0) {
        _diskCache[key] = file;
        if (mounted) setState(() => _cachedFile = file);
      }
    } catch (_) {}
  }

  Future<void> _saveToDiskCache(String resolvedUrl, List<int> bytes) async {
    try {
      final key = _generateCacheKey(resolvedUrl);
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/nexus_img_cache');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      final file = File('${cacheDir.path}/$key');
      await file.writeAsBytes(bytes);
      _diskCache[key] = file;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 1. PRIORIDADE ZERO-LATÊNCIA (0ms): Asset Local Embutido no App
    final localAsset = ClusterUrlService.getLocalAssetPath(widget.url);
    if (localAsset != null) {
      return Image.asset(
        localAsset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          // Se o asset local não for encontrado, faz fallback para rede/cache
          return _buildNetworkOrFallback();
        },
      );
    }

    return _buildNetworkOrFallback();
  }

  Widget _buildNetworkOrFallback() {
    // 2. SEGUNDA PRIORIDADE (0ms): Cache persistente em disco
    if (_cachedFile != null && _cachedFile!.existsSync()) {
      return Image.file(
        _cachedFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildNetworkImage(),
      );
    }

    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    final resolved = ClusterUrlService.resolveImageUrl(widget.url);
    if (resolved == null) return widget.fallback ?? const SizedBox.shrink();

    return Image.network(
      resolved,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (widget.url != null && widget.url != resolved) {
          return Image.network(
            widget.url!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => widget.fallback ?? const SizedBox.shrink(),
          );
        }
        return widget.fallback ?? const SizedBox.shrink();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Quando terminar de carregar com sucesso, armazena assincronamente no cache de disco
          _saveNetworkImageToCache(resolved);
          return child;
        }
        return widget.fallback != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  widget.fallback!,
                  Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.accentCyan.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              )
            : child;
      },
    );
  }

  void _saveNetworkImageToCache(String url) async {
    final key = _generateCacheKey(url);
    if (_diskCache.containsKey(key)) return;
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        await _saveToDiskCache(url, resp.bodyBytes);
      }
    } catch (_) {}
  }
}