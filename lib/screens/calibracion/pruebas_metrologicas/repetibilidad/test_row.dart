import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';

class TestRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.indicacionControllers[cargaIndex][testIndex],
                decoration: buildInputDecoration(
                  'Indicación ${testIndex + 1}',
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      controller.indicacionControllers[cargaIndex][testIndex].text = value;
                    },
                    itemBuilder: (context) {
                      // 🔥 CAMBIO 1: Usar el método que selecciona el D correcto según la carga
                      final dValue = controller.getDValueForCargaController(cargaIndex);

                      // 🔥 CAMBIO 2: Calcular decimales basado en el valor D
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

                      // 🔥 CAMBIO 3: Usar la carga como base si el campo está vacío
                      final currentText = controller.indicacionControllers[cargaIndex][testIndex].text.trim();
                      final baseValue = double.tryParse(
                          (currentText.isEmpty
                              ? controller.cargaControllers[cargaIndex].text
                              : currentText).replaceAll(',', '.')
                      ) ?? 0.0;

                      // 🔥 CAMBIO 4: Usar dValue en lugar de d1
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
                controller: controller.retornoControllers[cargaIndex][testIndex],
                decoration: buildInputDecoration(
                  'Retorno ${testIndex + 1}',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) {
                    controller.retornoControllers[cargaIndex][testIndex].text = '0';
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