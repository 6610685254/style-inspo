import 'package:flutter/material.dart';

class StyleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const StyleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: foreground),
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        side: BorderSide(color: foreground.withOpacity(0.5), width: 1.5),
        shape: const StadiumBorder(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

// --- Implementation Example ---

// For "Style Labs" (Blue)
// StyleButton(
//   label: 'Style Labs',
//   icon: Icons.checkroom_outlined, 
//   color: const Color(0xFF4A7C8C),
//   onPressed: () => Navigator.pushNamed(context, '/style-labs'),
// )

// For "Styles Planner" (Dark Brown/Black)
// StyleButton(
//   label: 'Styles Planner',
//   icon: Icons.calendar_month_outlined,
//   color: const Color(0xFF2D2926),
//   onPressed: () => Navigator.pushNamed(context, '/planner'),
// )