import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../fin_servicios_controller.dart';

class CondicionesFinalesStep extends StatelessWidget {
  const CondicionesFinalesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FinServiciosController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10.0),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'REGISTRO DE CONDICIONES FINALES',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                Column(
                  children: [
                    const Text(
                      'FOTOGRAFÍAS FINALES DEL SERVICIO',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Máximo 5 fotos (${controller.finalPhotos['final']?.length ?? 0}/5)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => controller.takePhoto(),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(20),
                              backgroundColor: const Color(0xFFc0101a),
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.camera_alt),
                          ),
                          if (controller.finalPhotos['final'] != null)
                            ...controller.finalPhotos['final']!.map((photo) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () =>
                                      _showFullScreenPhoto(context, photo),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Image.file(photo,
                                            fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon:
                                              const Icon(Icons.close, size: 16),
                                          onPressed: () =>
                                              controller.removePhoto(photo),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Text(
            '1. INGRESE LAS CONDICIONES AMBIENTALES FINALES:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controller.horaController,
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        'Hora',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => controller.setHora(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Haga clic en el icono del reloj para ingresar la hora, la hora es obtenida automáticamente del sistema, no es editable.',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20.0),
                _buildValidatedField(
                  controller: controller.hrifinController,
                  label: 'HRi (%)',
                  suffix: '%',
                  initialValue: controller.hriInicial,
                ),
                const SizedBox(height: 20.0),
                _buildValidatedField(
                  controller: controller.tifinController,
                  label: 'ti (°C)',
                  suffix: '°C',
                  initialValue: controller.tiInicial,
                ),
                const SizedBox(height: 20.0),
                _buildValidatedField(
                  controller: controller.patmifinController,
                  label: 'Patmi (hPa)',
                  suffix: 'hPa',
                  initialValue: controller.patmiInicial,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Text(
            '2. REGISTRO DE RECOMENDACIONES:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                    'Mantenimiento con ST',
                  ),
                  items: ['Sí', 'No'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.mantenimientoController.text = newValue ?? '';
                  },
                  validator: (value) =>
                      value == null ? 'Por favor seleccione una opción' : null,
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                    'Venta de Pesas',
                  ),
                  items: ['Sí', 'No'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.ventaPesasController.text = newValue ?? '';
                  },
                  validator: (value) =>
                      value == null ? 'Por favor seleccione una opción' : null,
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                    'Reemplazo',
                  ),
                  items: ['Sí', 'No'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.reemplazoController.text = newValue ?? '';
                  },
                  validator: (value) =>
                      value == null ? 'Por favor seleccione una opción' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Text(
            '3. OBSERVACIONES / COMENTARIOS:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextFormField(
              controller: controller.obscomController,
              maxLines: 3,
              decoration: _buildInputDecoration('Observaciones'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    double? initialValue,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final borderColor = _getValidationColor(initialValue, value.text);
        return TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          controller: controller,
          decoration: _buildInputDecoration(
            label,
            suffixText: suffix,
          ).copyWith(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: borderColor, width: 2.5),
            ),
            prefixIcon: Icon(
              borderColor == Colors.green
                  ? Icons.check_circle
                  : (borderColor == Colors.red ? Icons.warning : Icons.info),
              color: borderColor,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un valor';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor ingrese un número válido';
            }
            return null;
          },
        );
      },
    );
  }

  Color _getValidationColor(double? initialValue, String currentText) {
    if (initialValue == null || currentText.isEmpty) {
      return Colors.grey;
    }

    final currentValue = double.tryParse(currentText);
    if (currentValue == null) return Colors.grey;

    final difference = (currentValue - initialValue).abs();

    if (difference <= 4) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    Widget? suffixIcon,
    String? suffixText,
    TextStyle? errorStyle,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      errorStyle: errorStyle,
    );
  }

  void _showFullScreenPhoto(BuildContext context, File photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: Stack(
              children: [
                Center(
                  child: Image.file(
                    photo,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
