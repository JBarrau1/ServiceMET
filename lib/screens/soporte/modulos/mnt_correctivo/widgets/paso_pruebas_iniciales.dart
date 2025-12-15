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
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blue.shade100,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Estas pruebas se realizan ANTES de cualquier ajuste o reparación.')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PruebasMetrologicasWidget(
            pruebas: widget.model.pruebasIniciales,
            tipoPrueba: 'Inicial',
            onChanged: () => setState(() {}),
            getIndicationSuggestions:
                (String cargaStr, String currentIndication) async {
              double carga = double.tryParse(cargaStr) ?? 0;
              double d = await widget.controller.getD1FromDatabase();
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
}
