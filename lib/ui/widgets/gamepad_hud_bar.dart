import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class GamepadPromptItem {
  final String assetName;
  final String label;

  const GamepadPromptItem({
    required this.assetName,
    required this.label,
  });
}

/// Barra inferior estilo console com dicas visuais de botões do Gamepad
class GamepadHudBar extends StatelessWidget {
  final List<GamepadPromptItem> prompts;

  const GamepadHudBar({
    super.key,
    this.prompts = const [
      GamepadPromptItem(assetName: 'xbox_a.png', label: 'Selecionar'),
      GamepadPromptItem(assetName: 'xbox_b.png', label: 'Voltar / Sair'),
      GamepadPromptItem(assetName: 'xbox_x.png', label: 'Detalhes'),
      GamepadPromptItem(assetName: 'xbox_lb.png', label: 'Aba Anterior'),
      GamepadPromptItem(assetName: 'xbox_rb.png', label: 'Próxima Aba'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: prompts.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/gamepad/${item.assetName}',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.gamepad,
                        size: 18,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
