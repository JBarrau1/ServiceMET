import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';

class TestRow extends StatefulWidget {
  final RepetibilidadController controller;
  final int cargaIndex;
  final int testIndex;

  const TestRow({
    super.key,
    required this.controller,
    required this.cargaIndex,
    required this.testIndex,
  });

  @override
  State<TestRow> createState() => _TestRowState();
}

class _TestRowState extends State<TestRow> {
  double _dValue = 0.1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDValue();
  }

  Future<void> _loadDValue() async {
    try {
      final dValue = await widget.controller.getDValueForCargaController(widget.cargaIndex);
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
  void didUpdateWidget(TestRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar D value cuando cambie la carga
    if (oldWidget.controller.cargaControllers[widget.cargaIndex].text !=
        widget.controller.cargaControllers[widget.cargaIndex].text) {
      _loadDValue();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex],
                decoration: buildInputDecoration(
                  'Indicación ${widget.testIndex + 1}',
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex].text = value;
                    },
                    itemBuilder: (context) {
                      // CORREGIDO: Usar _dValue que ya está cargado
                      final dValue = _dValue;

                      // CORREGIDO: Calcular decimales basado en el valor D
                      int decimalPlaces = 1; // por defecto
                      if (dValue >= 1) {
                        decimalPlaces = 0;
                      } else if (dValue >= 0.1) {
                        decimalPlaces = 1;
                      } else if (dValue >= 0.01) {
                        decimalPlaces = 2;
                      } else if (dValue >= 0.001) {
                        decimalPlaces = 3;
                      }

                      // ✅ CORREGIDO: Usar la carga como base si el campo está vacío
                      final currentText = widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex].text.trim();
                      final baseValue = double.tryParse(
                          (currentText.isEmpty
                              ? widget.controller.cargaControllers[widget.cargaIndex].text
                              : currentText).replaceAll(',', '.')
                      ) ?? 0.0;

                      // ✅ CORREGIDO: Usar _dValue en lugar de d1
                      return List.generate(11, (i) {
                        final value = baseValue + ((i - 5) * dValue);
                        return PopupMenuItem<String>(
                          value: value.toStringAsFixed(decimalPlaces),
                          child: Text(value.toStringAsFixed(decimalPlaces)),
                        );
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller.retornoControllers[widget.cargaIndex][widget.testIndex],
                decoration: buildInputDecoration(
                  'Retorno ${widget.testIndex + 1}',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) {
                    widget.controller.retornoControllers[widget.cargaIndex][widget.testIndex].text = '0';
                  }
                },
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
        const SizedBox(height: 10),
      ],
    );
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