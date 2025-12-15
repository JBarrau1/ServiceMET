import 'package:flutter/material.dart';
import '../models/diagnostico_model.dart';

class PasoInformacionGeneral extends StatelessWidget {
  final DiagnosticoModel model;

  const PasoInformacionGeneral({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMACIÓN GENERAL',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Reporte de Falla
          TextFormField(
            initialValue: model.reporteFalla,
            decoration: InputDecoration(
              labelText: 'Reporte de falla:',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              alignLabelWithHint: true,
            ),
            maxLength: 800,
            maxLines: 8,
            minLines: 4,
            onChanged: (value) => model.reporteFalla = value,
          ),
          const SizedBox(height: 20),
          // Evaluación
          TextFormField(
            initialValue: model.evaluacion,
            decoration: InputDecoration(
              labelText: 'Evaluación y análisis técnico de fallas:',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              alignLabelWithHint: true,
            ),
            maxLength: 800,
            maxLines: 8,
            minLines: 4,
            onChanged: (value) => model.evaluacion = value,
          ),
        ],
      ),
    );
  }
}
