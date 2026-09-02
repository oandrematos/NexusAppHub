import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          hintText: 'Buscar jogos, ferramentas e utilitários...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}