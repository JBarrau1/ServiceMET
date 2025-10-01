import 'package:flutter/material.dart';
import 'linealidad_controller.dart';

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
  double _dValue = 0.1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDValue();
  }

  Future<void> _loadDValue() async {
    try {
      // Obtener el valor de LT para calcular el D apropiado
      final ltText = widget.controller.rows[widget.index]['lt']?.text ?? '';
      final ltValue = double.tryParse(ltText.replaceAll(',', '.')) ?? 0.0;

      final dValue = await widget.controller.getDForCarga(ltValue);
      setState(() {
        _dValue = dValue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dValue = 0.1;
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(LinearityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar D value cuando cambie el valor de LT
    final oldLt = oldWidget.controller.rows[widget.index]['lt']?.text ?? '';
    final newLt = widget.controller.rows[widget.index]['lt']?.text ?? '';
    if (oldLt != newLt) {
      _loadDValue();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    final row = widget.controller.rows[widget.index];
    final decimalPlaces = _getDecimalPlaces(_dValue);

    return Column(
      children: [
        _buildLtField(context, row, decimalPlaces),
        const SizedBox(height: 10),
        _buildIndicacionRetornoFields(row, decimalPlaces),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildLtField(
      BuildContext context,
      Map<String, TextEditingController> row,
      int decimalPlaces,
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
            validator: (value) => _validateLt(value, row, decimalPlaces),
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
              // Recalcular D value cuando cambia LT
              _loadDValue();
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
      int decimalPlaces,
      ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: row['indicacion'],
            decoration: buildInputDecoration(
              'Indicación ${widget.index + 1}',
              suffixIcon: _buildPopupMenu(row, decimalPlaces),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _validateRequired(value),
            onChanged: (value) {
              // Recalcular diferencia cuando cambia la indicación
              _calculateDifference(row, decimalPlaces);
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
      int decimalPlaces,
      ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.arrow_drop_down),
      onSelected: (value) {
        row['indicacion']?.text = value;
        _calculateDifference(row, decimalPlaces);
      },
      itemBuilder: (context) {
        final currentText = row['indicacion']?.text ?? '';
        final baseValue = double.tryParse(currentText.replaceAll(',', '.')) ?? 0.0;

        return List.generate(11, (i) {
          final value = baseValue + ((i - 5) * _dValue);
          return PopupMenuItem<String>(
            value: value.toStringAsFixed(decimalPlaces),
            child: Text(value.toStringAsFixed(decimalPlaces)),
          );
        });
      },
    );
  }

  void _calculateDifference(Map<String, TextEditingController> row, int decimalPlaces) {
    final ltText = row['lt']?.text ?? '';
    final indicacionText = row['indicacion']?.text ?? '';

    if (ltText.isNotEmpty && indicacionText.isNotEmpty) {
      final ltValue = double.tryParse(ltText.replaceAll(',', '.')) ?? 0.0;
      final indValue = double.tryParse(indicacionText.replaceAll(',', '.')) ?? 0.0;
      final difference = indValue - ltValue;
      row['difference']?.text = difference.toStringAsFixed(decimalPlaces);
    }
  }

  String? _validateLt(String? value, Map<String, TextEditingController> row, int decimalPlaces) {
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
        row['difference']?.text = difference.toStringAsFixed(decimalPlaces);
      }
    }

    return null;
  }

  String? _validateRequired(String? value) {
    return value == null || value.isEmpty ? 'Campo obligatorio' : null;
  }

  int _getDecimalPlaces(double dValue) {
    if (dValue >= 1) return 0;
    if (dValue >= 0.1) return 1;
    if (dValue >= 0.01) return 2;
    if (dValue >= 0.001) return 3;
    return 1; // por defecto
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