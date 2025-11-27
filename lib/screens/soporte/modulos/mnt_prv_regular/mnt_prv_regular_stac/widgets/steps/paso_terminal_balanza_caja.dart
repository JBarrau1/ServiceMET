import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_regular_stac_controller.dart';
import '../../models/mnt_prv_regular_stac_model.dart';
import '../campo_inspeccion_widget.dart';

// ============================================
// PASO 2: TERMINAL DE PESAJE
// ============================================
class PasoTerminal extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final VoidCallback onChanged;

  const PasoTerminal({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final campos = [
      'Carcasa',
      'Teclado Fisico',
      'Display Fisico',
      'Fuente de poder',
      'Bateria operacional',
      'Bracket',
      'Teclado Operativo',
      'Display Operativo',
      'Contector de celda',
      'Bateria de memoria',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            title: 'TERMINAL DE PESAJE',
            subtitle: 'Inspeccione el estado físico y operacional del terminal',
            icon: Icons.computer_outlined,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: model.camposEstado[campo]!,
              controller: controller,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
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

// ============================================
// PASO 3: ESTADO DE BALANZA
// ============================================
class PasoBalanza extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final VoidCallback onChanged;

  const PasoBalanza({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final campos = [
      'Limpieza general',
      'Golpes al terminal',
      'Nivelacion',
      'Limpieza receptor',
      'Golpes al receptor de carga',
      'Encendido',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            title: 'ESTADO GENERAL DE LA BALANZA',
            subtitle: 'Inspeccione el estado general del instrumento',
            icon: Icons.balance_outlined,
            color: Colors.teal,
          ),
          const SizedBox(height: 24),
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: model.camposEstado[campo]!,
              controller: controller,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
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

// ============================================
// PASO 4: CAJA SUMADORA
// ============================================
class PasoCajaSumadora extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final VoidCallback onChanged;

  const PasoCajaSumadora({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final camposPlataforma = [
      'Limitador de movimiento',
      'Suspensión',
      'Limitador de carga',
      'Celda de carga',
    ];

    final camposCajaSumadora = [
      'Tapa de caja sumadora',
      'Humedad Interna',
      'Estado de prensacables',
      'Estado de borneas',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            title: 'BALANZA | PLATAFORMA',
            subtitle: 'Inspeccione los componentes de la plataforma',
            icon: Icons.square_outlined,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          ...camposPlataforma.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: model.camposEstado[campo]!,
              controller: controller,
              onChanged: onChanged,
            );
          }),
          const SizedBox(height: 32),
          _buildHeader(
            context,
            title: 'CAJA SUMADORA',
            subtitle: 'Inspeccione el estado de la caja sumadora',
            icon: Icons.electrical_services_outlined,
            color: Colors.amber[700]!,
          ),
          const SizedBox(height: 16),
          ...camposCajaSumadora.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: model.camposEstado[campo]!,
              controller: controller,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
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
