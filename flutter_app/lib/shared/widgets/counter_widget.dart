import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CounterWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const CounterWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: Icons.remove,
          onTap: () => onChanged(value - 1),
          enabled: value > 0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add,
          onTap: () => onChanged(value + 1),
          enabled: true,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? urucum : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
