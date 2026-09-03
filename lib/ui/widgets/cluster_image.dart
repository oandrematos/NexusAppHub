import 'package:flutter/material.dart';
import '../../data/services/cluster_url_service.dart';
import '../core/app_colors.dart';

class ClusterImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final resolved = ClusterUrlService.resolveImageUrl(url);
    if (resolved == null) return fallback ?? const SizedBox.shrink();

    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Se a URL resolvida do CDN falhar e a original era diferente, tenta a original
        if (url != null && url != resolved) {
          return Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
          );
        }
        return fallback ?? const SizedBox.shrink();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return fallback != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  fallback!,
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
}