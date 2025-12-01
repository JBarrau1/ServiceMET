import 'package:flutter/material.dart';
import '../../models/relevamiento_de_datos_model.dart';
import '../../controllers/relevamiento_de_datos_controller.dart';
import '../pruebas_metrologicas_widget.dart';

class PasoPruebasFinales extends StatelessWidget {
  final RelevamientoDeDatosModel model;
  final RelevamientoDeDatosController controller;
  final Future<double> Function() getD1FromDatabase;
  final VoidCallback onChanged;

  const PasoPruebasFinales({
    super.key,
    required this.model,
    required this.controller,
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

          // Info box explicando que solo hay pruebas finales
          _buildInfoBox(
            'En el relevamiento de datos solo se realizan pruebas metrológicas finales, no iniciales.',
            Colors.blue,
          ),
          const SizedBox(height: 24),

          // Pruebas Metrológicas FINALES
          PruebasMetrologicasWidget(
            pruebas: model.pruebasFinales,
            onChanged: onChanged,
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
                  'Realice las pruebas metrológicas del relevamiento',
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
