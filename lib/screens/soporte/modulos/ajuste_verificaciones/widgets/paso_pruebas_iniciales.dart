import 'package:flutter/material.dart';
import 'pruebas_metrologicas_widget.dart';
import '../models/ajuste_verificaciones_model.dart';
import '../controllers/ajuste_verificaciones_controller.dart';

class PasoPruebasIniciales extends StatelessWidget {
  final AjusteVerificacionesModel model;
  final AjusteVerificacionesController controller;
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

          PruebasMetrologicasWidget(
            pruebas: model.pruebasIniciales,
            isInicial: true,
            onChanged: onChanged,
            // Usamos las funciones pasadas por parámetro
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
          const Icon(Icons.science_outlined, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRUEBAS METROLÓGICAS INICIALES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Realice las pruebas metrológicas iniciales'),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
      ),
      controller: TextEditingController(text: value),
    );
  }
}
