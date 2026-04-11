import 'package:flutter/material.dart';

/// Reusable menu button with icon + label, styled for the dark game theme.
class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.blueGrey.shade200;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 280,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: effectiveColor, size: 22),
          label: Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900.withAlpha(220),
            disabledBackgroundColor: Colors.blueGrey.shade900.withAlpha(100),
            side: BorderSide(color: effectiveColor.withAlpha(120), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }
}
