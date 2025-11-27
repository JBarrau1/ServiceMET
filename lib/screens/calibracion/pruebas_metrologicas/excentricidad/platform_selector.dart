import 'package:flutter/material.dart';
import 'excentricidad_controller.dart';

class PlatformSelector extends StatelessWidget {
  final ExcentricidadController controller;
  final VoidCallback onUpdate;

  const PlatformSelector({
    super.key,
    required this.controller,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1: SELECCIONE EL TIPO DE PLATAFORMA',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20.0),
        DropdownButtonFormField<String>(
          initialValue: controller.selectedPlatform != null &&
                  controller.platformOptions
                      .containsKey(controller.selectedPlatform)
              ? controller.selectedPlatform
              : null,
          decoration: buildInputDecoration(
            'Selecciona el tipo de plataforma',
          ),
          items: controller.platformOptions.keys
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) {
            controller.selectedPlatform = value!;
            controller.selectedOption = null; // Reinicia opción seleccionada
            controller.updatePositionsFromOption();
            onUpdate();
          },
        ),
        const SizedBox(height: 20),
        if (controller.selectedPlatform != null &&
            controller.platformOptions[controller.selectedPlatform] !=
                null) ...[
          DropdownButtonFormField<String>(
            initialValue: controller.selectedOption != null &&
                    controller.platformOptions[controller.selectedPlatform]!
                        .contains(controller.selectedOption)
                ? controller.selectedOption
                : null,
            decoration: buildInputDecoration(
              'Puntos e Indicador',
            ),
            items: controller.platformOptions[controller.selectedPlatform]!
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              controller.selectedOption = value!;
              controller.updatePositionsFromOption();
              onUpdate();
            },
          ),
          const SizedBox(height: 20),
          if (controller.optionImages[controller.selectedOption] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14), // Bordes redondeados
                  child: Image.asset(
                    controller.optionImages[controller.selectedOption]!,
                    height: 130, // Tamaño más pequeño
                    fit: BoxFit
                        .cover, // Para que llene el espacio manteniendo proporciones
                  ),
                ),
              ),
            ),
        ]
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
