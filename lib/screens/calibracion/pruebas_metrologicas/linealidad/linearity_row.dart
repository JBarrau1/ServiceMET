import 'package:flutter/material.dart';
import 'linealidad_controller.dart';

class LinearityRow extends StatelessWidget {
  final int index;
  final VoidCallback onRemove;
  final LinealidadController controller; // Agregar esto

  const LinearityRow({
    super.key,
    required this.index,
    required this.onRemove,
    required this.controller, // ← Y guardarlo aquí
  });

  @override
  Widget build(BuildContext context) {
    final row = controller.rows[index];
    final d1 = controller.getD1Value();
    final decimalPlaces = d1.toString().split('.').last.length;

    return Column(
      children: [
        _buildLtField(context, controller, row, index, decimalPlaces),
        const SizedBox(height: 10),
        _buildIndicacionRetornoFields(row, d1, decimalPlaces),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildLtField(
    BuildContext context,
    LinealidadController controller,
    Map<String, TextEditingController> row,
    int index,
    int decimalPlaces,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: row['lt'],
            decoration: buildInputDecoration(
              'LT ${index + 1}',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateLt(value, controller, index),
            onChanged: (value) {
              final indicacion = row['indicacion'];
              // Siempre que el valor de LT no esté vacío, actualiza 'indicacion'
              if (value.isNotEmpty) {
                indicacion?.text = value;
              }
              // Opcional: Si quieres que 'indicacion' se vacíe si 'LT' se vacía:
              else {
                indicacion?.text = '';
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: row['difference'],
            decoration: buildInputDecoration(
              'Diferencia',
            ),
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicacionRetornoFields(
    Map<String, TextEditingController> row,
    double d1,
    int decimalPlaces,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: row['indicacion'],
            decoration: buildInputDecoration(
              'Indicación ${index + 1}',
              suffixIcon: _buildPopupMenu(row, d1, decimalPlaces),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateRequired(value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: row['retorno'],
            decoration: buildInputDecoration(
              'Retorno ${index + 1}',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateRequired(value),
          ),
        ),
      ],
    );
  }

  PopupMenuButton<String> _buildPopupMenu(
    Map<String, TextEditingController> row,
    double d1,
    int decimalPlaces,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      onSelected: (value) => row['indicacion']?.text = value,
      itemBuilder: (context) {
        final baseValue = double.tryParse(row['indicacion']?.text ?? '') ?? 0.0;
        return List.generate(11, (i) {
          final value = baseValue + ((i - 5) * d1);
          return PopupMenuItem<String>(
            value: value.toStringAsFixed(decimalPlaces),
            child: Text(value.toStringAsFixed(decimalPlaces)),
          );
        });
      },
    );
  }

  String? _validateLt(String? value, LinealidadController controller, int index) {
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    }
    final ltValue = double.tryParse(value.replaceAll(',', '.'));
    if (ltValue == null || ltValue < 0) {
      return 'Valor LT inválido';
    }

    // Calcular diferencia automáticamente
    final indicacion = controller.rows[index]['indicacion']?.text;
    if (indicacion != null && indicacion.isNotEmpty) {
      final indValue = double.tryParse(indicacion.replaceAll(',', '.'));
      if (indValue != null) {
        final difference = indValue - ltValue;
        final decimalPlaces = controller.getD1Value().toString().split('.').last.length;
        controller.rows[index]['difference']?.text = difference.toStringAsFixed(decimalPlaces);
      }
    }

    return null;
  }

  String? _validateRequired(String? value) {
    return value == null || value.isEmpty ? 'Campo obligatorio' : null;
  }

  InputDecoration buildInputDecoration(
    String labelText, {
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
