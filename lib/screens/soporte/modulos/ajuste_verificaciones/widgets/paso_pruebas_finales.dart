import 'package:flutter/material.dart';
import 'pruebas_metrologicas_widget.dart';
import '../models/ajuste_verificaciones_model.dart';
import '../controllers/ajuste_verificaciones_controller.dart';

class PasoPruebasFinales extends StatelessWidget {
  final AjusteVerificacionesModel model;
  final AjusteVerificacionesController controller;
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

          // Botón Copiar
          _buildCopyButton(context),
          const SizedBox(height: 24),

          PruebasMetrologicasWidget(
            pruebas: model.pruebasFinales,
            isInicial: false,
            onChanged: onChanged,
            getIndicationSuggestions: controller.getIndicationSuggestions,
            getD1FromDatabase: controller.getD1FromDatabase,
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
          const Icon(Icons.task_alt_outlined, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRUEBAS METROLÓGICAS FINALES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Realice las pruebas metrológicas finales'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          controller.copiarPruebasInicialesAFinales();
          onChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos copiados exitosamente')),
          );
        },
        icon: const Icon(Icons.content_copy, color: Colors.white),
        label: const Text('COPIAR PRUEBAS INICIALES'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
