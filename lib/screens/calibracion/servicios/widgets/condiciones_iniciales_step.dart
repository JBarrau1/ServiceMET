// widgets/condiciones_iniciales_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../servicio_controller.dart';

class CondicionesInicialesStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;

  const CondicionesInicialesStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
  }) : super(key: key);

  @override
  State<CondicionesInicialesStep> createState() => _CondicionesInicialesStepState();
}

class _CondicionesInicialesStepState extends State<CondicionesInicialesStep> {
  final Map<String, TextEditingController> _comentarioControllers = {};
  bool _setAllToGood = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final entornoOptions = Provider.of<ServicioController>(context, listen: false).entornoOptions;
    entornoOptions.forEach((key, _) {
      _comentarioControllers[key] = TextEditingController(text: 'Sin Comentario');
    });
  }

  @override
  void dispose() {
    _comentarioControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicioController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
            Text(
              'CONDICIONES INICIALES DEL EQUIPO',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Datos básicos de tiempo
            _buildTimeSection(controller),

            const SizedBox(height: 30),

            // Entorno de instalación
            _buildEntornoSection(controller),

            const SizedBox(height: 30),

            // Estado general de la balanza
            _buildEstadoBalanzaSection(controller),

            const SizedBox(height: 30),

            // Botón para guardar datos
            _buildSaveButton(controller),
          ],
        );
      },
    );
  }

  Widget _buildTimeSection(ServicioController controller) {
    return Column(
      children: [
        TextFormField(
          initialValue: controller.horaInicio,
          decoration: _buildInputDecoration('Hora de inicio de la Calibración:'),
          readOnly: true,
          onTap: () {
            controller.setHoraInicio(controller.getCurrentTime());
          },
        ),
        const SizedBox(height: 8.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
              size: 16.0,
            ),
            const SizedBox(width: 5.0),
            Expanded(
              child: Text(
                'Hora obtenida automáticamente del sistema',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        DropdownButtonFormField<String>(
          value: controller.tiempoEstabilizacion,
          decoration: _buildInputDecoration('Tiempo de estabilización de Pesas (en Minutos):'),
          items: controller.tiemposOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            controller.setTiempoEstabilizacion(newValue!);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione una opción';
            }
            return null;
          },
        ),
        const SizedBox(height: 20.0),
        DropdownButtonFormField<String>(
          value: controller.tiempoBalanza,
          decoration: _buildInputDecoration('Tiempo previo a operación de Balanza:'),
          items: controller.tiemposOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            controller.setTiempoBalanza(newValue!);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione una opción';
            }
            return null;
          },
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3);
  }

  Widget _buildEntornoSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'ENTORNO DE INSTALACIÓN',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20.0),

        SwitchListTile(
          title: const Text('Establecer todo en Buen Estado'),
          value: _setAllToGood,
          onChanged: (value) {
            setState(() {
              _setAllToGood = value;
            });
            if (value) {
              controller.setAllCondicionesToGood();
            }
          },
          activeColor: Colors.green,
          secondary: Icon(
            _setAllToGood ? Icons.check_circle : Icons.circle_outlined,
            color: _setAllToGood ? Colors.green : Colors.grey,
          ),
        ).animate(delay: 400.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: 20.0),

        // Campos de entorno
        ...controller.entornoOptions.entries.take(8).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildDropdownFieldWithComment(
              context,
              entry.key,
              entry.value,
              _comentarioControllers[entry.key]!,
              controller,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEstadoBalanzaSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'ESTADO GENERAL DE LA BALANZA',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 500.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20.0),

        // Campos restantes del entorno
        ...controller.entornoOptions.entries.skip(8).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildDropdownFieldWithComment(
              context,
              entry.key,
              entry.value,
              _comentarioControllers[entry.key]!,
              controller,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDropdownFieldWithComment(
      BuildContext context,
      String label,
      List<String> items,
      TextEditingController commentController,
      ServicioController controller,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: _setAllToGood ? _getDefaultGoodValue(label) : controller.condicionesEntorno[label],
                decoration: _buildInputDecoration(label),
                items: items.map((String value) {
                  Color textColor;
                  switch (value) {
                    case 'Inexistente':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Dañado':
                      textColor = Colors.red;
                      break;
                    case 'Malo':
                      textColor = Colors.red;
                      break;
                    case 'Aceptable':
                      textColor = Colors.orange;
                      break;
                    case 'Bueno':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Sin Daños':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Existente':
                      textColor = Colors.red;
                      break;
                    case 'Daños Leves':
                      textColor = Colors.orange;
                      break;
                    case 'No aplica':
                      textColor = Colors.grey;
                      break;
                    default:
                      textColor = Colors.black;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: textColor),
                    ),
                  );
                }).toList(),
                onChanged: _setAllToGood
                    ? null
                    : (newValue) {
                  controller.setCondicionEntorno(label, newValue!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _showPhotoDialog(context, label, controller),
              icon: Icon(
                (controller.condicionesPhotos[label]?.isNotEmpty ?? false)
                    ? Icons.check_circle
                    : Icons.camera_alt_rounded,
                color: (controller.condicionesPhotos[label]?.isNotEmpty ?? false)
                    ? Colors.green
                    : null,
              ),
              tooltip: 'Agregar Fotografía',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: commentController,
                decoration: _buildInputDecoration('Comentario $label'),
                onTap: () {
                  if (commentController.text == 'Sin Comentario') {
                    commentController.clear();
                  }
                },
                readOnly: _setAllToGood,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ],
    ).animate(delay: (controller.entornoOptions.keys.toList().indexOf(label) * 100 + 600).ms)
        .fadeIn().slideX(begin: label.hashCode % 2 == 0 ? -0.3 : 0.3);
  }

  String _getDefaultGoodValue(String label) {
    switch (label) {
      case 'Vibración':
      case 'Polvo':
      case 'Humedad':
      case 'Limpieza Receptor':
        return 'Inexistente';
      case 'Golpes al Terminal':
      case 'Golpes al receptor de Carga':
        return 'Sin Daños';
      default:
        return 'Bueno';
    }
  }

  Future<void> _showPhotoDialog(BuildContext context, String label, ServicioController controller) async {
    final ImagePicker picker = ImagePicker();
    List<File> photos = controller.condicionesPhotos[label] ?? [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'AGREGAR FOTOGRAFÍA PARA: $label',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
                          setState(() {
                            photos.add(File(photo.path));
                            // Actualizar en el controller
                            if (controller.condicionesPhotos[label] == null) {
                              controller.condicionesPhotos[label] = [];
                            }
                            controller.condicionesPhotos[label]!.add(File(photo.path));
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt),
                          const SizedBox(width: 8),
                          Text(photos.isEmpty ? 'TOMAR FOTO' : 'TOMAR OTRA FOTO'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (photos.isNotEmpty)
                      Wrap(
                        children: photos.map((photo) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(photo, width: 100, height: 100),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      photos.remove(photo);
                                      controller.condicionesPhotos[label]?.remove(photo);
                                      if (controller.condicionesPhotos[label]?.isEmpty ?? true) {
                                        controller.condicionesPhotos.remove(label);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Actualizar el estado global del controller
                    controller.condicionesPhotos[label] = photos;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton(ServicioController controller) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await controller.saveCurrentStepData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Datos guardados correctamente'),
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
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'GUARDAR CONDICIONES INICIALES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3);
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }
}