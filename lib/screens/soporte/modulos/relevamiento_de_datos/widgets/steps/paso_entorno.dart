import 'package:flutter/material.dart';
import '../../models/relevamiento_de_datos_model.dart';
import '../../controllers/relevamiento_de_datos_controller.dart';
import '../../utils/constants.dart';

class PasoEntorno extends StatelessWidget {
  final RelevamientoDeDatosModel model;
  final RelevamientoDeDatosController controller;
  final VoidCallback onChanged;

  const PasoEntorno({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
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

          // Campos de entorno con dropdowns
          ...AppConstants.entornoCampos.entries.map((entry) {
            return _buildEnvironmentField(
              context,
              entry.key,
              entry.value,
            );
          }),
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
          const Icon(
            Icons.domain_outlined,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTORNO DE INSTALACIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspeccione las condiciones ambientales y de instalación',
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

  Widget _buildEnvironmentField(
    BuildContext context,
    String label,
    List<String> options,
  ) {
    final campo = model.camposEstado[label];
    if (campo == null) return const SizedBox.shrink();

    // Asegurar que el valor actual esté en las opciones
    String currentValue = campo.initialValue;
    if (!options.contains(currentValue)) {
      currentValue = options.first;
      campo.initialValue = currentValue;
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              campo.initialValue = newValue;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Comentario $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.comment_outlined),
          ),
          maxLines: 2,
          onChanged: (value) {
            campo.comentario = value;
            onChanged();
          },
          controller: TextEditingController(text: campo.comentario)
            ..selection = TextSelection.collapsed(
              offset: campo.comentario.length,
            ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
