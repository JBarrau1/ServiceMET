import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AreaSeleccionScreen extends StatelessWidget {
  final String userName;

  const AreaSeleccionScreen({
    required this.userName,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'SELECCIÓN DE ÁREA',
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título principal
            Text(
              'Seleccione el área de trabajo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            // Sección CALIBRACIÓN
            _buildAreaCard(
              context: context,
              title: 'CALIBRACIÓN',
              subtitle: 'Servicios de calibración de balanzas',
              icon: Icons.scale,
              color: const Color(0xFF007195),
              onTap: () {
                // Navegar a la pantalla de calibración
                Navigator.pushNamed(context, '/calibracion');
              },
            ),

            const SizedBox(height: 24),

            // Sección SOPORTE TÉCNICO
            _buildAreaCard(
              context: context,
              title: 'SOPORTE TÉCNICO',
              subtitle: 'Mantenimiento y reparaciones',
              icon: Icons.build,
              color: const Color(0xFF478b3a),
              onTap: () {
                // Navegar a la pantalla de soporte técnico
                Navigator.pushNamed(context, '/soporte_tecnico');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),

              const SizedBox(height: 16),

              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}