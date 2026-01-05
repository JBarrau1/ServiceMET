import 'package:flutter/material.dart';
import '../../models/verificaciones_internas_model.dart';

class PasoReporteEvaluacion extends StatelessWidget {
  final VerificacionesInternasModel model;
  final VoidCallback onChanged;

  const PasoReporteEvaluacion({
    super.key,
    required this.model,
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

          // Reporte de Falla
          _buildSectionTitle('REPORTE DE FALLA O TRABAJO REALIZADO'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: model.reporteFalla,
            maxLines: 5,
            decoration: _buildInputDecoration('Escriba el reporte aquí...'),
            onChanged: (value) {
              model.reporteFalla = value;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // Evaluación
          _buildSectionTitle('EVALUACIÓN'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: model.evaluacion,
            maxLines: 3,
            decoration: _buildInputDecoration('Escriba la evaluación aquí...'),
            onChanged: (value) {
              model.evaluacion = value;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // Estados Generales
          _buildSectionTitle('ESTADOS GENERALES DE PRUEBAS'),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Excentricidad - Estado General',
            value: model.excentricidadEstadoGeneral,
            onChanged: (val) {
              model.excentricidadEstadoGeneral = val!;
              onChanged();
            },
            context: context,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Repetibilidad - Estado General',
            value: model.repetibilidadEstadoGeneral,
            onChanged: (val) {
              model.repetibilidadEstadoGeneral = val!;
              onChanged();
            },
            context: context,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Linealidad - Estado General',
            value: model.linealidadEstadoGeneral,
            onChanged: (val) {
              model.linealidadEstadoGeneral = val!;
              onChanged();
            },
            context: context,
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
          const Icon(
            Icons.article_outlined,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPORTE Y EVALUACIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingrese el detalle del trabajo realizado y la evaluación general',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Function(String?) onChanged,
    required BuildContext context,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: ['Cumple', 'No Cumple', 'No Aplica']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
