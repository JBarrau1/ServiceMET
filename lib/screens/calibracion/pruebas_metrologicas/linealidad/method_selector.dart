import 'package:flutter/material.dart';
import 'linealidad_controller.dart';

class MethodSelector extends StatelessWidget {
  final LinealidadController controller;

  const MethodSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. ELIJA EL MÉTODO A APLICAR:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10.0),
        _buildMethodDropdown(controller, theme),
        const SizedBox(height: 20.0),
        Text(
          '2. SELECCIONE EL MÉTODO DE CARGAS SUSTITUTIVAS:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10.0),
        _buildMethodInfo(isDarkMode),
        const SizedBox(height: 20.0),
        _buildLoadMethodDropdown(controller, theme),
      ],
    );
  }

  Widget _buildMethodDropdown(LinealidadController controller,
      ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: controller.metodoOptions.contains(controller.selectedMetodo)
          ? controller.selectedMetodo
          : null,
      decoration: buildInputDecoration(
        'Método',
      ),
      items: controller.metodoOptions.map((String metodo) {
        return DropdownMenuItem<String>(
          value: metodo,
          child: Text(
            metodo,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        controller.updateMetodo(value);
        (controller.onUpdate != null) ? controller.onUpdate!() : null;
      },
      style: theme.textTheme.bodyMedium,
      dropdownColor: theme.cardColor,
      validator: (value) => value == null ? 'Seleccione un método' : null,
    );
  }

  Widget _buildLoadMethodDropdown(LinealidadController controller,
      ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: controller.metodocargaOptions.contains(
          controller.selectedMetodoCarga)
          ? controller.selectedMetodoCarga
          : null,
      decoration: buildInputDecoration(
        'Método de Carga',
      ),
      items: controller.metodocargaOptions.map((String metodo) {
        return DropdownMenuItem<String>(
          value: metodo,
          child: Text(
            metodo,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        controller.updateMetodoCarga(value);
        (controller.onUpdate != null) ? controller.onUpdate!() : null;
      },
      style: theme.textTheme.bodyMedium,
      dropdownColor: theme.cardColor,
    );
  }

  Widget _buildMethodInfo(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info,
          size: 16,
          color: isDarkMode ? Colors.amber.shade200 : Colors.blue.shade800,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Puede seleccionar el método 1 o 2 según el criterio del Técnico responsable. '
                'Si no selecciona un método y solo ingresa las cargas, podrá guardar los datos con normalidad.',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration buildInputDecoration(String labelText, {
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }
}
