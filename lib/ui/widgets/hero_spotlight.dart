import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../core/app_colors.dart';

class HeroSpotlight extends StatelessWidget {
  final AppItem app;
  final VoidCallback onTap;
  final VoidCallback onInstall;

  const HeroSpotlight({
    super.key,
    required this.app,
    required this.onTap,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isAvailable = app.isAvailableOn(isAndroid);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCyan, AppColors.accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DESTAQUE DA SEMANA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                app.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            app.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            app.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isAvailable ? onInstall : null,
                icon: const Icon(Icons.download, size: 18),
                label: Text(app.getActionText(isAndroid, false)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Ver Detalhes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}