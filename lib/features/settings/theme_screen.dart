import 'package:flutter/material.dart';
import '../../main.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (_, current, __) => ListView(
          children: [
            _ThemeOption(
              label: 'System default',
              icon: Icons.brightness_auto,
              value: ThemeMode.system,
              current: current,
            ),
            _ThemeOption(
              label: 'Light',
              icon: Icons.light_mode_outlined,
              value: ThemeMode.light,
              current: current,
            ),
            _ThemeOption(
              label: 'Dark',
              icon: Icons.dark_mode_outlined,
              value: ThemeMode.dark,
              current: current,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode current;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: Colors.black)
          : null,
      onTap: () => themeModeNotifier.value = value,
    );
  }
}
