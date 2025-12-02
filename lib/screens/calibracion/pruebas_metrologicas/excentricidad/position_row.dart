import 'package:flutter/material.dart';
import 'excentricidad_controller.dart';
import '../decimal_helper.dart';

class PositionRow extends StatefulWidget {
  final ExcentricidadController controller;
  final int index;

  const PositionRow({
    super.key,
    required this.controller,
    required this.index,
  });

  @override
  State<PositionRow> createState() => _PositionRowState();
}

class _PositionRowState extends State<PositionRow> {
  Map<String, double> _dValues = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDValues();
  }

  Future<void> _loadDValues() async {
    try {
      final dValues = await widget.controller.getDValues();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto de la posición
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Text(
            "Posición: ${widget.controller.positionControllers[widget.index].text}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20.0),

        // Fila con Indicación y Retorno
        Row(
          children: [
            // Indicación
            Expanded(
              child: _IndicationField(
                controller: widget.controller,
                index: widget.index,
                dValues: _dValues,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller.returnControllers[widget.index],
                decoration: _buildInputDecoration('Retorno'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IndicationField extends StatelessWidget {
  const _IndicationField({
    required this.controller,
    required this.index,
    required this.dValues,
  });

  final ExcentricidadController controller;
  final int index;
  final Map<String, double> dValues;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.indicationControllers[index],
      decoration: _buildInputDecoration(
        'Indicación',
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (value) {
            controller.indicationControllers[index].text = value;
          },
          itemBuilder: (context) {
            final currentText =
                controller.indicationControllers[index].text.trim();
            // Si está vacío, usa la carga como base
            final baseValue = double.tryParse(
                  (currentText.isEmpty
                          ? controller.cargaController.text
                          : currentText)
                      .replaceAll(',', '.'),
                ) ??
                0.0;

            // Get dynamic decimal step based on the value
            final dValue = DecimalHelper.getDecimalForValue(baseValue, dValues);
            final decimalPlaces = DecimalHelper.getDecimalPlaces(dValue);

            // 11 sugerencias (5 abajo, actual, 5 arriba)
            return List.generate(11, (i) {
              final value = baseValue + ((i - 5) * dValue);
              final txt = value.toStringAsFixed(decimalPlaces);
              return PopupMenuItem<String>(value: txt, child: Text(txt));
            });
          },
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        final v = double.tryParse(value.replaceAll(',', '.'));
        if (v == null) return 'Número inválido';
        return null;
      },
    );
  }
}

// Utilidad local para mantener tu estilo
InputDecoration _buildInputDecoration(
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
