import 'package:flutter/material.dart';
import 'linealidad_controller.dart';
import '../decimal_helper.dart';

class LinearityRow extends StatefulWidget {
  final int index;
  final VoidCallback onRemove;
  final LinealidadController controller;

  const LinearityRow({
    super.key,
    required this.index,
    required this.onRemove,
    required this.controller,
  });

  @override
  State<LinearityRow> createState() => _LinearityRowState();
}

class _LinearityRowState extends State<LinearityRow> {
  Map<String, double> _dValues = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDValues();
  }

  Future<void> _loadDValues() async {
    try {
      final dValues = await widget.controller.getAllDValues();
      if (mounted) {
        setState(() {
          _dValues = dValues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dValues = {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    final row = widget.controller.rows[widget.index];

    return Column(
      children: [
        _buildLtField(context, row),
        const SizedBox(height: 10),
        _buildIndicacionRetornoFields(row),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildLtField(
    BuildContext context,
    Map<String, TextEditingController> row,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: row['lt'],
            decoration: buildInputDecoration(
              'LT ${widget.index + 1}',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateLt(value, row),
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
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: row['indicacion'],
            decoration: buildInputDecoration(
              'Indicación ${widget.index + 1}',
              suffixIcon: _buildPopupMenu(row),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateRequired(value),
            onChanged: (value) {
              // Recalcular diferencia cuando cambia la indicación
              _calculateDifference(row);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: row['retorno'],
            decoration: buildInputDecoration(
              'Retorno ${widget.index + 1}',
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
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      onSelected: (value) {
        row['indicacion']?.text = value;
        _calculateDifference(row);
      },
      itemBuilder: (context) {
        final currentText = row['indicacion']?.text ?? '';
        final baseValue =
            double.tryParse(currentText.replaceAll(',', '.')) ?? 0.0;

        // Get dynamic decimal step based on the value
        final dValue = DecimalHelper.getDecimalForValue(baseValue, _dValues);
        final decimalPlaces = DecimalHelper.getDecimalPlaces(dValue);

        return List.generate(11, (i) {
          final value = baseValue + ((i - 5) * dValue);
          return PopupMenuItem<String>(
            value: value.toStringAsFixed(decimalPlaces),
            child: Text(value.toStringAsFixed(decimalPlaces)),
          );
        });
      },
    );
  }

  void _calculateDifference(Map<String, TextEditingController> row) {
    final ltText = row['lt']?.text ?? '';
    final indicacionText = row['indicacion']?.text ?? '';

    if (ltText.isNotEmpty && indicacionText.isNotEmpty) {
      final ltValue = double.tryParse(ltText.replaceAll(',', '.')) ?? 0.0;
      final indValue =
          double.tryParse(indicacionText.replaceAll(',', '.')) ?? 0.0;
      final difference = indValue - ltValue;

      // Use the decimal places of the indication for the difference
      final dValue = DecimalHelper.getDecimalForValue(ltValue, _dValues);
      final decimalPlaces = DecimalHelper.getDecimalPlaces(dValue);

      row['difference']?.text = difference.toStringAsFixed(decimalPlaces);
    }
  }

  String? _validateLt(String? value, Map<String, TextEditingController> row) {
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    }
    final ltValue = double.tryParse(value.replaceAll(',', '.'));
    if (ltValue == null || ltValue < 0) {
      return 'Valor LT inválido';
    }

    // Calcular diferencia automáticamente
    final indicacion = row['indicacion']?.text;
    if (indicacion != null && indicacion.isNotEmpty) {
      final indValue = double.tryParse(indicacion.replaceAll(',', '.'));
      if (indValue != null) {
        final difference = indValue - ltValue;

        final dValue = DecimalHelper.getDecimalForValue(ltValue, _dValues);
        final decimalPlaces = DecimalHelper.getDecimalPlaces(dValue);

        row['difference']?.text = difference.toStringAsFixed(decimalPlaces);
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
