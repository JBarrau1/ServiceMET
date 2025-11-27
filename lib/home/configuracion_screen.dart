import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool isDarkMode = false;
  String appVersion = '11.1.1_3_181125';
  String appName = 'METRICA LTDA';

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      appName = packageInfo.appName;
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      isDarkMode = value;
    });

    // Notificar a toda la aplicación sobre el cambio de tema
    // Necesitarías implementar un Provider o otro método de gestión de estado
    // para que esto afecte a toda la aplicación
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
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
                    value:
                        isDarkMode, // Usamos el estado guardado, no el del contexto
                    onChanged: _toggleTheme,
                    secondary: const Icon(Icons.dark_mode),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión $appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
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
