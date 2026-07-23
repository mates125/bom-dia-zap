import 'package:flutter/material.dart';
import '../models/category.dart';

// Mesma paleta usada na composição das imagens no backend, pra manter a
// identidade visual consistente entre o app e o conteúdo gerado.
const Map<String, Color> categoryColors = {
  'bom-dia': Color(0xFFFFD166),
  'boa-tarde': Color(0xFFFF8C42),
  'boa-noite': Color(0xFF7C9EFF),
  'cristao': Color(0xFFC9A7EB),
  'motivacional': Color(0xFF6EE7B7),
  'amor': Color(0xFFFF7A9C),
};

const Map<String, IconData> categoryIcons = {
  'bom-dia': Icons.wb_sunny_rounded,
  'boa-tarde': Icons.brightness_6_rounded,
  'boa-noite': Icons.nights_stay_rounded,
  'cristao': Icons.self_improvement_rounded,
  'motivacional': Icons.rocket_launch_rounded,
  'amor': Icons.favorite_rounded,
};

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[category.slug] ?? Theme.of(context).colorScheme.primary;
    final icon = categoryIcons[category.slug] ?? Icons.image_rounded;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: color.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
