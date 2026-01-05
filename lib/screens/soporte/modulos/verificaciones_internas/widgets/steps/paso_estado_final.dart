import 'package:flutter/material.dart';
import '../../models/verificaciones_internas_model.dart';
import '../../controllers/verificaciones_internas_controller.dart';

class PasoEstadoFinal extends StatelessWidget {
  final VerificacionesInternasModel model;
  final VerificacionesInternasController controller;

  const PasoEstadoFinal({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: isDarkMode ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Resumen del Servicio',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSummaryCard(context, isDarkMode),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Presione FINALIZAR para completar el servicio y exportar los datos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDarkMode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow('Hora Inicio', model.horaInicio),
            const Divider(),
            _buildSummaryRow('Reporte',
                model.reporteFalla.isNotEmpty ? 'Completado' : 'Vacío'),
            const Divider(),
            _buildSummaryRow('Evaluación',
                model.evaluacion.isNotEmpty ? 'Completado' : 'Vacío'),
            const Divider(),
            _buildSummaryRow(
                'Comentarios', '${model.comentarios.length} agregados'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
