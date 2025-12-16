import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../controllers/mnt_correctivo_controller.dart';

class PasoInformacionGeneral extends StatelessWidget {
  final MntCorrectivoModel model;
  final MntCorrectivoController controller;
  final VoidCallback onUpdate; // Para refrescar UI tras importar

  const PasoInformacionGeneral({
    super.key,
    required this.model,
    required this.controller,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón Importar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () =>
                  controller.importDiagnosticoCsv(context, onUpdate),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('IMPORTAR DIAGNÓSTICO (CSV)',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),

          _buildHeader(context),
          const SizedBox(height: 24),
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

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          Icon(
            Icons.info_outlined,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INFORMACIÓN GENERAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Datos iniciales del mantenimiento correctivo',
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
