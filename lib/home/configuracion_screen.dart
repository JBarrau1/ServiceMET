// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/settings_provider.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String appVersion = '1.1.050126';
  String appName = 'METRICA LTDA';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      appName = packageInfo.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'CONFIGURACIÓN',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: isDark ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDark
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        centerTitle: true,
        actions: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Modo oscuro
                Card(
                  child: SwitchListTile(
                    title: const Text('Modo Oscuro'),
                    subtitle: const Text('Activar tema oscuro'),
                    value: settings.themeMode == ThemeMode.dark ||
                        (settings.themeMode == ThemeMode.system && isDark),
                    onChanged: (value) {
                      settings.toggleTheme(value);
                    },
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ),

                const SizedBox(height: 16),

                // Tamaño de texto
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.text_fields),
                            const SizedBox(width: 16),
                            Text(
                              'Tamaño de Texto',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('A', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: settings.textScaleFactor,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                label:
                                    settings.textScaleFactor.toStringAsFixed(1),
                                onChanged: (value) {
                                  settings.setTextScale(value);
                                },
                              ),
                            ),
                            const Text('A', style: TextStyle(fontSize: 24)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Respaldo
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Respaldo de Datos'),
                    subtitle: const Text('Crear respaldo de la aplicación'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RespaldoScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Información de copyright y versión
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '© 2025 $appName. Todos los derechos reservados.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión $appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
