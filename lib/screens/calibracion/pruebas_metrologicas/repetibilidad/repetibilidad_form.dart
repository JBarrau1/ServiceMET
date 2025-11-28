import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/test_row.dart';

class RepetibilidadForm extends StatefulWidget {
  final RepetibilidadController controller;

  const RepetibilidadForm({super.key, required this.controller});

  @override
  State<RepetibilidadForm> createState() => _RepetibilidadFormState();
}

class _RepetibilidadFormState extends State<RepetibilidadForm> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        child: Column(
          children: [
            const Text(
              'PRUEBAS DE REPETIBILIDAD',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: controller.selectedRepetibilityCount,
              decoration: buildInputDecoration('Cantidad de Cargas'),
              items: [1, 2, 3].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (value) {
                controller.updateRepetibilityCount(value, () {
                  setState(() {});
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: controller.selectedRowCount,
              decoration: buildInputDecoration('Pruebas por Carga'),
              items: [3, 5, 10].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (value) {
                controller.updateRowCount(value, () {
                  setState(() {});
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.pmax1Controller,
                    decoration: buildInputDecoration(
                      'Capacidad máxima',
                    ).copyWith(
                      labelStyle: const TextStyle(color: Color(0xFF4ECFBA)),
                      floatingLabelStyle:
                          const TextStyle(color: Color(0xFF4ECFBA)),
                    ),
                    style: const TextStyle(color: Color(0xFF4ECFBA)),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller.fiftyPercentPmax1Controller,
                    decoration: buildInputDecoration(
                      '50% Capacidad máxima',
                    ).copyWith(
                      labelStyle: const TextStyle(color: Color(0xFF92B6C9)),
                      floatingLabelStyle:
                          const TextStyle(color: Color(0xFF92B6C9)),
                    ),
                    style: const TextStyle(color: Color(0xFF92B6C9)),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ...List.generate(
              controller.selectedRepetibilityCount,
              (cargaIndex) => Column(
                children: [
                  Text(
                    'CARGA ${cargaIndex + 1}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: controller.cargaControllers[cargaIndex],
                    decoration: buildInputDecoration(
                      'Valor de Carga',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    controller.selectedRowCount,
                    (testIndex) => TestRow(
                      controller: controller,
                      cargaIndex: cargaIndex,
                      testIndex: testIndex,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E8833),
              ),
              onPressed: () async {
                try {
                  await controller.saveDataToDatabase();
                  _showSnackBar(context, 'Datos guardados correctamente');
                } catch (e) {
                  _showSnackBar(context, 'Error al guardar: $e', isError: true);
                }
              },
              child: const Text('GUARDAR DATOS DE REPETIBILIDAD'),
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // color del texto
        ),
        // Usa `SnackBarTheme` o personaliza aquí:
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // esto aún funciona en versiones actuales
        behavior: SnackBarBehavior.floating,
      ),
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
