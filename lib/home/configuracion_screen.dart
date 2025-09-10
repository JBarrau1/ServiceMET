import 'package:flutter/material.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionScreen extends StatefulWidget {
  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
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
    // Aquí deberías implementar la lógica para cambiar el tema globalmente
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
        title: const Text('CONFIGURACIÓN'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Modo oscuro
          Card(
            child: SwitchListTile(
              title: const Text('Modo Oscuro'),
              subtitle: const Text('Activar tema oscuro'),
              value: isDarkMode,
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
    );
  }
}