import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Color restaurantColor(String name) {
  const colors = [
    urucum,
    couve,
    cafe,
    Color(0xFF7B4FA6),
    Color(0xFF1976D2),
  ];
  return colors[name.codeUnitAt(0) % colors.length];
}

class DishThumb extends StatelessWidget {
  final String name;
  final double size;

  const DishThumb({super.key, required this.name, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final color = restaurantColor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
