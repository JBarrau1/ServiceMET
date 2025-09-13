import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Paquete para obtener información de la app

class ConfiguracionScreen extends StatefulWidget {
  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool isDarkMode = false;
  String appVersion = '9.1.1_4_12925';
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

  Future<void> _cerrarSesion(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CERRAR SESIÓN'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Sesión'),
              onPressed: () async {
                // Implementar lógica de cerrar sesión aquí
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'CONFIGURACIÓN',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
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
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        )
            : null,
        centerTitle: true,
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
                    value: isDarkMode, // Usamos el estado guardado, no el del contexto
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
                        MaterialPageRoute(builder: (context) => RespaldoScreen()),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Cerrar sesión
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cerrar Sesión'),
                    subtitle: const Text('Salir de la aplicación'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _cerrarSesion(context),
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