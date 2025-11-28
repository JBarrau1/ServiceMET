import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/platform_selector.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/position_row.dart';
import 'excentricidad_controller.dart';

class ExcentricidadForm extends StatefulWidget {
  final ExcentricidadController controller;

  const ExcentricidadForm({super.key, required this.controller});

  @override
  State<ExcentricidadForm> createState() => _ExcentricidadFormState();
}

class _ExcentricidadFormState extends State<ExcentricidadForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'PRUEBAS DE EXCENTRICIDAD',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PlatformSelector(
            controller: widget.controller,
            onUpdate: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller.pmax1Controller,
                  decoration: buildInputDecoration(
                    'Capacidad máxima',
                  ).copyWith(
                    labelStyle: const TextStyle(color: Color(0xFF4ECFBA)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF4ECFBA)),
                  ),
                  style: const TextStyle(color: Color(0xFF4ECFBA)),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller.oneThirdPmax1Controller,
                  decoration: buildInputDecoration(
                    '1/3 Capacidad máxima',
                  ).copyWith(
                    labelStyle: const TextStyle(color: Color(0xFF92B6C9)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF92B6C9)),
                  ),
                  style: const TextStyle(color: Color(0xFF92B6C9)),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.controller.selectedPlatform != null) ...[
            TextFormField(
              controller: widget.controller.cargaController,
              decoration: buildInputDecoration(
                  'Carga'
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ...List.generate(
              widget.controller.positionControllers.length,
                  (index) => PositionRow(
                controller: widget.controller,
                index: index,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E8833),
              ),
              onPressed: () async {
                await widget.controller.saveDataToDatabase(context);
              },
              child: const Text('GUARDAR DATOS DE EXCENTRICIDAD'),
            ),

          ],
        ],
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
