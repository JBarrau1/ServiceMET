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
          const SizedBox(height: 20.0),
          const Text(
            '4. SELECCIÓN DE PESAS PATRÓN:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPesasSelection(context, controller),
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      'Seleccionar Pesas (${controller.selectedPesas.length}/5)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF365666),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (controller.selectedPesas.isNotEmpty)
                  ...controller.selectedPesas.map((pesa) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF365666).withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Color(0xFF365666)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pesa['cod_instrumento'] ?? 'Sin código',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(pesa['instrumento'] ??
                                      'Instrumento desconocido'),
                                  const SizedBox(height: 4),
                                  _buildCertificateStatus(
                                      pesa['cert_fecha']?.toString() ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Text('Cant.',
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(
                                  width: 70,
                                  child: _QuantityInput(
                                    initialValue:
                                        pesa['cantidad']?.toString() ?? '1',
                                    onChanged: (val) =>
                                        controller.updatePesaCantidad(
                                            pesa['cod_instrumento'], val),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => controller
                                  .removePesa(pesa['cod_instrumento']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  void _showPesasSelection(
      BuildContext context, FinServiciosController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Seleccionar Pesas Patrón',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: controller.equiposOptions.length,
                      itemBuilder: (context, index) {
                        final equipo = controller.equiposOptions[index];
                        final isSelected = controller.selectedPesas.any((e) =>
                            e['cod_instrumento'] == equipo['cod_instrumento']);

                        final certFecha =
                            equipo['cert_fecha']?.toString() ?? '';
                        final diasVencidos = _calculateDaysElapsed(certFecha);
                        final isExpired = diasVencidos > 365;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            side: isSelected
                                ? const BorderSide(
                                    color: Color(0xFF365666), width: 2)
                                : BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            activeColor: const Color(0xFF365666),
                            title: Text(
                              equipo['cod_instrumento'] ?? 'Sin código',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipo['instrumento'] ?? 'Sin instrumento',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                _buildCertificateStatus(certFecha),
                              ],
                            ),
                            secondary: isExpired
                                ? const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange)
                                : const Icon(Icons.verified_outlined,
                                    color: Colors.green),
                            value: isSelected,
                            onChanged: (bool? value) {
                              if (value == true) {
                                controller.addPesa(equipo);
                              } else {
                                controller
                                    .removePesa(equipo['cod_instrumento']);
                              }
                              // Rebuild modal manually if needed, but CheckboxListTile handles its state usually?
                              // Actually specific state management might be needed if update doesn't reflect immediately.
                              // For now relying on parent Controller notification.
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF365666),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('LISTO'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _calculateDaysElapsed(String dateStr) {
    if (dateStr.isEmpty) return 0;
    try {
      // Intentar parsear dd-MM-yyyy o yyyy-MM-dd
      DateTime? certDate;
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts[0].length == 4) {
          certDate = DateTime.tryParse(dateStr);
        } else {
          // Asumir dd-MM-yyyy
          certDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      if (certDate == null) return 0;

      final now = DateTime.now();
      return now.difference(certDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildCertificateStatus(String dateStr) {
    if (dateStr.isEmpty) return const Text('Sin fecha de referencia');

    final elapsed = _calculateDaysElapsed(dateStr);
    final remaining = 365 - elapsed;
    final isExpired = remaining < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isExpired ? Colors.red : Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isExpired ? Icons.warning : Icons.check_circle,
              size: 14, color: isExpired ? Colors.red[800] : Colors.green[800]),
          const SizedBox(width: 4),
          Text(
            isExpired
                ? 'Vencido hace ${elapsed - 365} días'
                : 'Días de validez: $remaining',
            style: TextStyle(
              fontSize: 13, // Slightly larger
              fontWeight: FontWeight.w700,
              color: isExpired ? Colors.red[900] : Colors.green[900],
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

class _QuantityInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _QuantityInput({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<_QuantityInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
