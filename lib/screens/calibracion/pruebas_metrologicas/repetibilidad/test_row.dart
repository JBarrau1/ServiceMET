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
              child: FutureBuilder<double>(
                future: controller.getD1Value(),
                builder: (context, snapshot) {
                  final d1 = snapshot.data ?? 0.1;
                  final decimalPlaces = d1.toString().split('.').last.length;

                  return TextFormField(
                    controller: controller
                        .indicacionControllers[cargaIndex][testIndex],
                    decoration: buildInputDecoration(
                      'Indicación ${testIndex + 1}',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) {
                          controller.indicacionControllers[cargaIndex][testIndex]
                              .text = value;
                        },
                        itemBuilder: (context) {
                          final baseValue = double.tryParse(controller
                              .indicacionControllers[cargaIndex][testIndex]
                              .text) ??
                              0.0;
                          return List.generate(11, (i) {
                            final value = baseValue + ((i - 5) * d1);
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
                  );
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