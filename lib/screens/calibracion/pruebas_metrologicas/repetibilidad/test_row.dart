import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';
import '../decimal_helper.dart';

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
  Map<String, double> _dValues = {};
  bool _isLoading = true;
  String _lastCargaValue = '';

  @override
  void initState() {
    super.initState();
    _loadDValues();
    // ✅ AÑADIDO: Listener para detectar cambios en la carga
    widget.controller.cargaControllers[widget.cargaIndex]
        .addListener(_onCargaChanged);
  }

  @override
  void dispose() {
    // ✅ AÑADIDO: Remover el listener
    widget.controller.cargaControllers[widget.cargaIndex]
        .removeListener(_onCargaChanged);
    super.dispose();
  }

  // ✅ NUEVO: Método para manejar cambios en la carga
  void _onCargaChanged() {
    final currentCargaValue =
        widget.controller.cargaControllers[widget.cargaIndex].text;

    // Solo recargar si el valor realmente cambió
    if (currentCargaValue != _lastCargaValue) {
      _lastCargaValue = currentCargaValue;
      _loadDValues();
    }
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
  void didUpdateWidget(TestRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ MEJORADO: Verificar si cambió el índice de carga
    if (oldWidget.cargaIndex != widget.cargaIndex) {
      // Remover listener del controlador anterior
      oldWidget.controller.cargaControllers[oldWidget.cargaIndex]
          .removeListener(_onCargaChanged);
      // Añadir listener al nuevo controlador
      widget.controller.cargaControllers[widget.cargaIndex]
          .addListener(_onCargaChanged);
      _loadDValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller
                    .indicacionControllers[widget.cargaIndex][widget.testIndex],
                decoration: buildInputDecoration(
                  'Indicación ${widget.testIndex + 1}',
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      widget
                          .controller
                          .indicacionControllers[widget.cargaIndex]
                              [widget.testIndex]
                          .text = value;
                    },
                    itemBuilder: (context) {
                      // Usar la carga como base si el campo está vacío
                      final currentText = widget
                          .controller
                          .indicacionControllers[widget.cargaIndex]
                              [widget.testIndex]
                          .text
                          .trim();
                      final baseValue = double.tryParse((currentText.isEmpty
                                  ? widget.controller
                                      .cargaControllers[widget.cargaIndex].text
                                  : currentText)
                              .replaceAll(',', '.')) ??
                          0.0;

                      // Get dynamic decimal step based on the value
                      final dValue =
                          DecimalHelper.getDecimalForValue(baseValue, _dValues);
                      final decimalPlaces =
                          DecimalHelper.getDecimalPlaces(dValue);

                      // Generar 11 sugerencias (5 abajo, actual, 5 arriba)
                      return List.generate(11, (i) {
                        final value = baseValue + ((i - 5) * dValue);
                        final formattedValue =
                            value.toStringAsFixed(decimalPlaces);

                        return PopupMenuItem<String>(
                          value: formattedValue,
                          child: Text(
                            formattedValue,
                            style: i == 5
                                ? const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)
                                : null,
                          ),
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
                controller: widget.controller
                    .retornoControllers[widget.cargaIndex][widget.testIndex],
                decoration: buildInputDecoration(
                  'Retorno ${widget.testIndex + 1}',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) {
                    widget
                        .controller
                        .retornoControllers[widget.cargaIndex][widget.testIndex]
                        .text = '0';
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
