import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../controllers/mnt_correctivo_controller.dart';
import 'pruebas_metrologicas_widget.dart';

class PasoPruebasIniciales extends StatefulWidget {
  final MntCorrectivoModel model;
  final MntCorrectivoController controller;

  const PasoPruebasIniciales({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  State<PasoPruebasIniciales> createState() => _PasoPruebasInicialesState();
}

class _PasoPruebasInicialesState extends State<PasoPruebasIniciales> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          PruebasMetrologicasWidget(
            pruebas: widget.model.pruebasIniciales,
            tipoPrueba: 'Inicial',
            onChanged: () => setState(() {}),
            getIndicationSuggestions:
                (String cargaStr, String currentIndication) async {
              double carga = double.tryParse(cargaStr) ?? 0;
              double d = await widget.controller.getD1FromDatabase();
              if (d == 0) d = 0.1;
              return widget.controller.getIndicationSuggestions(carga, d);
            },
            getD1FromDatabase: widget.controller.getD1FromDatabase,
            // Pasamos controller si queremos fotos, aunque PruebasMetrologicasWidget debe soportarlo
            // No lo añadí al PruebasMetrologicasWidget de MntCorrectivo aún, lo haré.
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
