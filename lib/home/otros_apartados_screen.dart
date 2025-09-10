import 'package:flutter/material.dart';
import 'package:service_met/screens/historial/ult_servicios.dart';
import 'package:service_met/screens/precarga/descarga_de_datos.dart';

class OtrosApartadosScreen extends StatelessWidget {
  final String userName;

  const OtrosApartadosScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTROS APARTADOS'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOptionCard(
            context,
            icon: Icons.download,
            title: 'Precarga de Datos',
            subtitle: 'Descarga de información',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DescargaDeDatosScreen(userName: userName,)),
              );
            },
            color: Colors.green,
          ),
          _buildOptionCard(
            context,
            icon: Icons.history,
            title: 'Últimos Servicios',
            subtitle: 'Historial de servicios realizados',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UltServiciosScreen()),
              );
            },
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}