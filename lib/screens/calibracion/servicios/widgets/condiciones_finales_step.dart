import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../servicio_controller.dart';

class CondicionesFinalesStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;
  final String sessionId;

  const CondicionesFinalesStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<CondicionesFinalesStep> createState() => _CondicionesFinalesStepState();
}

class _CondicionesFinalesStepState extends State<CondicionesFinalesStep> {
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _hriController = TextEditingController();
  final TextEditingController _tiController = TextEditingController();
  final TextEditingController _patmiController = TextEditingController();
  final TextEditingController _mantenimientoController = TextEditingController();
  final TextEditingController _ventaPesasController = TextEditingController();
  final TextEditingController _reemplazoController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _empController = TextEditingController();
  final TextEditingController _indicarController = TextEditingController();
  final TextEditingController _factorController = TextEditingController();
  final TextEditingController _reglaController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<File> _fotosFinales = [];

  @override
  void initState() {
    super.initState();
    _setHoraActual();
  }

  void _setHoraActual() {
    final now = DateTime.now();
    _horaController.text = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _horaController.dispose();
    _hriController.dispose();
    _tiController.dispose();
    _patmiController.dispose();
    _mantenimientoController.dispose();
    _ventaPesasController.dispose();
    _reemplazoController.dispose();
    _observacionesController.dispose();
    _empController.dispose();
    _indicarController.dispose();
    _factorController.dispose();
    _reglaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicioController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Título
              Text(
                'CONDICIONES FINALES DEL SERVICIO',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2C3E50),
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 30),

              // Sección de fotos finales
              _buildFotosSection(controller),

              const SizedBox(height: 30),

              // Condiciones ambientales finales
              _buildCondicionesAmbientalesSection(controller),

              const SizedBox(height: 30),

              // Recomendaciones
              _buildRecomendacionesSection(controller),

              const SizedBox(height: 30),

              // Observaciones finales
              _buildObservacionesSection(controller),

              const SizedBox(height: 30),

              // Datos adicionales
              _buildDatosAdicionalesSection(controller),

              const SizedBox(height: 30),

              // Botón para finalizar
              _buildFinalizeButton(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotosSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'FOTOGRAFÍAS FINALES DEL SERVICIO',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 10),

        Text(
          'Máximo 5 fotos (${_fotosFinales.length}/5)',
          style: const TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _takePhoto(controller),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: const Color(0xFFc0101a),
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.camera_alt),
              ),
              ..._fotosFinales.map((photo) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _showFullScreenPhoto(photo),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(photo, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _fotosFinales.remove(photo);
                                controller.condicionesFinalesPhotos['final']?.remove(photo);
                              });
                            },
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
    ).animate(delay: 300.ms).fadeIn().slideY(begin: -0.3);
  }

  Future<void> _takePhoto(ServicioController controller) async {
    if (_fotosFinales.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo de 5 fotos alcanzado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _fotosFinales.add(File(photo.path));
        controller.condicionesFinalesPhotos['final'] = _fotosFinales;
        controller.condicionesFinalesPhotosTomadas = true;
      });
    }
  }

  void _showFullScreenPhoto(File photo) {
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

  Widget _buildCondicionesAmbientalesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'CONDICIONES AMBIENTALES FINALES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _horaController,
              readOnly: true,
              decoration: _buildInputDecoration(
                'Hora Final',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _setHoraActual,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: 16.0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Hora obtenida automáticamente del sistema',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _hriController,
          decoration: _buildInputDecoration('HRi Final (%)', suffixText: '%'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            controller.setCondicionFinal('hri_fin', value);
          },
        ).animate(delay: 600.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _tiController,
          decoration: _buildInputDecoration('ti Final (°C)', suffixText: '°C'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            controller.setCondicionFinal('ti_fin', value);
          },
        ).animate(delay: 700.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _patmiController,
          decoration: _buildInputDecoration('Patmi Final (hPa)', suffixText: 'hPa'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            controller.setCondicionFinal('patmi_fin', value);
          },
        ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildRecomendacionesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'RECOMENDACIONES FINALES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 900.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Mantenimiento con Soporte Técnico'),
          items: ['Sí', 'No'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _mantenimientoController.text = newValue ?? '';
            controller.setCondicionFinal('mantenimiento', newValue ?? '');
          },
        ).animate(delay: 1000.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Venta de Pesas'),
          items: ['Sí', 'No'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _ventaPesasController.text = newValue ?? '';
            controller.setCondicionFinal('venta_pesas', newValue ?? '');
          },
        ).animate(delay: 1100.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Reemplazo de Equipo'),
          items: ['Sí', 'No'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _reemplazoController.text = newValue ?? '';
            controller.setCondicionFinal('reemplazo', newValue ?? '');
          },
        ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildObservacionesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'OBSERVACIONES Y COMENTARIOS FINALES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 1300.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _observacionesController,
          decoration: _buildInputDecoration('Observaciones Finales'),
          maxLines: 5,
          onChanged: (value) {
            controller.setCondicionFinal('observaciones', value);
          },
        ).animate(delay: 1400.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildDatosAdicionalesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'DATOS ADICIONALES DEL SERVICIO',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 1500.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('EMP NB 23001'),
          items: ['Sí', 'No'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _empController.text = newValue ?? '';
            controller.setCondicionFinal('emp', newValue ?? '');
          },
        ).animate(delay: 1600.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _indicarController,
          decoration: _buildInputDecoration('Indicar (%)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            controller.setCondicionFinal('indicar', value);
          },
        ).animate(delay: 1700.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _factorController,
          decoration: _buildInputDecoration('Factor de Seguridad'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            controller.setCondicionFinal('factor_seguridad', value);
          },
        ).animate(delay: 1800.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Regla de Aceptación'),
          items: ['Ninguna', 'Simple', 'Conservadora'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            _reglaController.text = newValue ?? '';
            controller.setCondicionFinal('regla_aceptacion', newValue ?? '');
          },
        ).animate(delay: 1900.ms).fadeIn().slideX(begin: -0.3),
      ],
    );
  }

  Widget _buildFinalizeButton(ServicioController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await controller.saveCurrentStepData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Condiciones finales guardadas correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'GUARDAR CONDICIONES FINALES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate(delay: 2000.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (!controller.validateCurrentStep()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete todos los campos antes de finalizar'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('FINALIZAR SERVICIO'),
                    content: const Text('¿Está seguro de que desea finalizar el servicio?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Finalizar'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                try {
                  await controller.finalizeServicio();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Servicio finalizado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navegar a pantalla de fin de servicio
                  // Navigator.pushReplacement(...);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al finalizar servicio: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'FINALIZAR SERVICIO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate(delay: 2100.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }
}