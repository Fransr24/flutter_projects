import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:primer_parcial/presentation/provider/settings_provider.dart';

enum ColorTheme { white, red, blue, yellow }

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final appSettings = ref.watch(settingsNotifierProvider);
    final List<Color> colorList = ref.watch(colorListProvider);
    final List<String> colorNames = ref.watch(colorNamesProvider);
    bool isDarkMode = appSettings.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Enable Dark mode'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).toggleDarkMode();
            },
          ),
          ExpansionTile(
            title: const Text('Theme Selection'),
            subtitle: Text(
              'Selected Color: ${colorNames[appSettings.selectedColor]}',
            ),
            children: [
              for (var i = 0; i < colorList.length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: appSettings.selectedColor,
                  onChanged: (int? value) {
                    if (value != null) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .changeColorSettings(value);
                    }
                  },
                  title: Text('Color ${colorNames[i]}'),
                  subtitle: Text('Theme for color ${colorNames[i]}'),
                ),
            ],
          ),
          ListTile(
            title: Text('Font Size'),
            subtitle: Slider(
              value: appSettings.fontSize,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: '${appSettings.fontSize.round()}',
              onChanged: (double value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .changeFontSize(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
