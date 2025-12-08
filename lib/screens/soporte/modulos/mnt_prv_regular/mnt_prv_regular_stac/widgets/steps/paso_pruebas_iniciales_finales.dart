import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_regular_stac_controller.dart';
import '../../models/mnt_prv_regular_stac_model.dart';
import '../pruebas_metrologicas_widget.dart';

// ============================================
// PASO 0: PRUEBAS METROLÓGICAS INICIALES
// ============================================
class PasoPruebasIniciales extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final Future<List<String>> Function(String, String) getIndicationSuggestions;
  final Future<double> Function() getD1FromDatabase;
  final VoidCallback onChanged;

  const PasoPruebasIniciales({
    super.key,
    required this.model,
    required this.controller,
    required this.getIndicationSuggestions,
    required this.getD1FromDatabase,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDarkMode),
          const SizedBox(height: 24),

          // Hora de inicio
          _buildReadOnlyField(
            label: 'Hora de Inicio',
            value: model.horaInicio,
            icon: Icons.access_time,
            context: context,
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'La hora se extrae automáticamente del sistema y no es editable.',
            Colors.blue,
          ),
          const SizedBox(height: 24),

          // Pruebas Metrológicas
          PruebasMetrologicasWidget(
            pruebas: model.pruebasIniciales,
            isInicial: true,
            onChanged: onChanged,
            getIndicationSuggestions: getIndicationSuggestions,
            getD1FromDatabase: getD1FromDatabase,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRUEBAS METROLÓGICAS INICIALES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Realice las pruebas metrológicas antes del mantenimiento',
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required BuildContext context,
  }) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
      ),
      controller: TextEditingController(text: value),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PASO 5: PRUEBAS METROLÓGICAS FINALES
// ============================================
class PasoPruebasFinales extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final Future<List<String>> Function(String, String) getIndicationSuggestions;
  final Future<double> Function() getD1FromDatabase;
  final VoidCallback onChanged;

  const PasoPruebasFinales({
    super.key,
    required this.model,
    required this.controller,
    required this.getIndicationSuggestions,
    required this.getD1FromDatabase,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDarkMode),
          const SizedBox(height: 24),

          // Botón para copiar pruebas iniciales
          _buildCopyButton(context),
          const SizedBox(height: 24),

          // Pruebas Metrológicas
          PruebasMetrologicasWidget(
            pruebas: model.pruebasFinales,
            isInicial: false,
            onChanged: onChanged,
            getIndicationSuggestions: getIndicationSuggestions,
            getD1FromDatabase: getD1FromDatabase,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.green.withOpacity(0.1)
            : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.task_alt_outlined,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRUEBAS METROLÓGICAS FINALES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Realice las pruebas metrológicas después del mantenimiento',
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

  Widget _buildCopyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Si las pruebas finales son iguales a las iniciales, puede copiarlas automáticamente',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.copiarPruebasInicialesAFinales();
                onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Datos copiados de pruebas iniciales a finales',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.content_copy, color: Colors.white),
              label: const Text('COPIAR PRUEBAS INICIALES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
