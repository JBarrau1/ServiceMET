import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';
import '../../../../models/balanza_model.dart';
import 'excentricidad_controller.dart';

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
  double _dValue = 0.1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDValue();
  }

  Future<void> _loadDValue() async {
    final carga = double.tryParse(
      widget.controller.cargaController.text.replaceAll(',', '.'),
    ) ?? 0.0;

    try {
      final dValue = await widget.controller.getDForCarga(carga);
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
  void didUpdateWidget(PositionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar D value cuando cambie la carga
    if (oldWidget.controller.cargaController.text !=
        widget.controller.cargaController.text) {
      _loadDValue();
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
                dValue: _dValue, // Pasamos el valor ya obtenido
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller.returnControllers[widget.index],
                decoration: _buildInputDecoration('Retorno'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obligatorio';
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
    required this.dValue,
  });

  final ExcentricidadController controller;
  final int index;
  final double dValue; // Ahora recibe double directamente

  @override
  Widget build(BuildContext context) {
    final decimalPlaces = _decimalPlacesForStep(dValue);

    return TextFormField(
      controller: controller.indicationControllers[index],
      decoration: _buildInputDecoration(
        'Indicación',
        suffixIcon: (dValue <= 0)
            ? null
            : PopupMenuButton<String>(
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

  int _decimalPlacesForStep(double step) {
    if (step <= 0) return 0;
    final s = step.toString();
    if (!s.contains('.')) return 0;
    final frac = s.split('.').last.replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? 0 : frac.length;
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