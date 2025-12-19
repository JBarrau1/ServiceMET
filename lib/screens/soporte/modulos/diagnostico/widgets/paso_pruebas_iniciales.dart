import 'package:flutter/material.dart';
import '../models/diagnostico_model.dart';
import 'pruebas_metrologicas_widget.dart';
import '../controllers/diagnostico_controller.dart';

class PasoPruebasIniciales extends StatelessWidget {
  final DiagnosticoModel model;
  final DiagnosticoController controller;

  const PasoPruebasIniciales({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          PruebasMetrologicasWidget(
            pruebas: model.pruebasIniciales,
            tipoPrueba: 'Inicial',
            controller:
                controller, // Pasamos el controller para fotos y sugerencias
            onChanged:
                () {}, // El estado se actualiza por referencia en el modelo
            // Pasamos funciones helper del controlador adaptadas a la firma requerida (Future<List<String>> Function(String, String))
            getIndicationSuggestions:
                (String cargaStr, String currentIndication) async {
              double carga = double.tryParse(cargaStr) ?? 0;
              // Obtenemos d1 asumiendo que ya está cacheado o lo pedimos
              double d = await controller.getD1FromDatabase();
              if (d == 0) d = 0.1;
              return controller.getIndicationSuggestions(carga, d);
            },
            getD1FromDatabase:
                controller.getD1FromDatabase, // Ya devuelve Future<double>
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.orange.withOpacity(0.1)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_outlined,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRUEBAS INICIALES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Excentricidad, Repetibilidad y Linealidad',
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
