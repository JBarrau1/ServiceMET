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
  String _lastCargaValue = '';

  @override
  void initState() {
    super.initState();
    _loadDValue();
    // ✅ AÑADIDO: Listener para detectar cambios en la carga
    widget.controller.cargaControllers[widget.cargaIndex].addListener(_onCargaChanged);
  }

  @override
  void dispose() {
    // ✅ AÑADIDO: Remover el listener
    widget.controller.cargaControllers[widget.cargaIndex].removeListener(_onCargaChanged);
    super.dispose();
  }

  // ✅ NUEVO: Método para manejar cambios en la carga
  void _onCargaChanged() {
    final currentCargaValue = widget.controller.cargaControllers[widget.cargaIndex].text;

    // Solo recargar si el valor realmente cambió
    if (currentCargaValue != _lastCargaValue) {
      _lastCargaValue = currentCargaValue;
      _loadDValue();
    }
  }

  Future<void> _loadDValue() async {
    try {
      final dValue = await widget.controller.getDValueForCargaController(widget.cargaIndex);
      if (mounted) {
        setState(() {
          _dValue = dValue;
          _isLoading = false;
        });
        debugPrint('✅ D Value cargado para carga ${widget.cargaIndex}: $_dValue');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dValue = 0.1;
          _isLoading = false;
        });
      }
      debugPrint('❌ Error al cargar D Value: $e');
    }
  }

  @override
  void didUpdateWidget(TestRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ MEJORADO: Verificar si cambió el índice de carga
    if (oldWidget.cargaIndex != widget.cargaIndex) {
      // Remover listener del controlador anterior
      oldWidget.controller.cargaControllers[oldWidget.cargaIndex].removeListener(_onCargaChanged);
      // Añadir listener al nuevo controlador
      widget.controller.cargaControllers[widget.cargaIndex].addListener(_onCargaChanged);
      _loadDValue();
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
                controller: widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex],
                decoration: buildInputDecoration(
                  'Indicación ${widget.testIndex + 1}',
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex].text = value;
                    },
                    itemBuilder: (context) {
                      // ✅ USAR _dValue que ya está actualizado
                      final dValue = _dValue;

                      debugPrint('📊 Generando sugerencias con D=$dValue');

                      // Calcular decimales basado en el valor D
                      int decimalPlaces = 1;
                      if (dValue >= 1) {
                        decimalPlaces = 0;
                      } else if (dValue >= 0.1) {
                        decimalPlaces = 1;
                      } else if (dValue >= 0.01) {
                        decimalPlaces = 2;
                      } else if (dValue >= 0.001) {
                        decimalPlaces = 3;
                      }

                      // Usar la carga como base si el campo está vacío
                      final currentText = widget.controller.indicacionControllers[widget.cargaIndex][widget.testIndex].text.trim();
                      final baseValue = double.tryParse(
                          (currentText.isEmpty
                              ? widget.controller.cargaControllers[widget.cargaIndex].text
                              : currentText).replaceAll(',', '.')
                      ) ?? 0.0;

                      debugPrint('📊 Valor base: $baseValue, Decimales: $decimalPlaces');

                      // Generar 11 sugerencias (5 abajo, actual, 5 arriba)
                      return List.generate(11, (i) {
                        final value = baseValue + ((i - 5) * dValue);
                        final formattedValue = value.toStringAsFixed(decimalPlaces);

                        return PopupMenuItem<String>(
                          value: formattedValue,
                          child: Text(
                            formattedValue,
                            style: i == 5
                                ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
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