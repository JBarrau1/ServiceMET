import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/screens/calibracion/precarga.dart';
import 'package:service_met/screens/soporte/soporte_screen.dart';
import 'package:service_met/screens_new/area_selection/area_seleccion.dart';

class ServiciosScreen extends StatelessWidget {
  final String userName;

  const ServiciosScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'AREAS DE TRABAJO',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDarkMode
            ? ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        )
            : null,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 40,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        children: [
          _buildServiceCard(
            context,
            icon: Icons.build,
            title: 'Calibración',
            subtitle: 'Procesos de calibración de equipos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrecargaScreen(userName: userName,)),
              );
            },
            color: Colors.blue,
          ),
          _buildServiceCard(
            context,
            icon: Icons.support_agent,
            title: 'Soporte Técnico',
            subtitle: 'Soporte y mantenimiento',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SoporteScreen(userName: userName,)),
              );
            },
            color: Colors.green,
          ),
          _buildServiceCard(
            context,
            icon: Icons.area_chart,
            title: 'Selección de Área',
            subtitle: 'Gestión de áreas de trabajo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AreaSeleccionScreen(userName: userName,)),
              );
            },
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {
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