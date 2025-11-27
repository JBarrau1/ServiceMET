import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mnt_prv_regular_stil_model.dart';
import '../controllers/mnt_prv_regular_stil_controller.dart';

class EstadoGeneralWidget extends StatefulWidget {
  final Map<String, CampoEstado> campos;
  final MntPrvRegularStilController controller;
  final Function onFieldChanged;

  const EstadoGeneralWidget({
    super.key,
    required this.campos,
    required this.controller,
    required this.onFieldChanged,
  });

  @override
  _EstadoGeneralWidgetState createState() => _EstadoGeneralWidgetState();
}

class _EstadoGeneralWidgetState extends State<EstadoGeneralWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  // Función para obtener el ícono según el estado
  IconData _getIconByEstado(String? estado) {
    switch (estado) {
      case '1 Bueno':
        return Icons.check_circle;
      case '2 Aceptable':
        return Icons.warning;
      case '3 Malo':
        return Icons.error;
      case '4 No aplica':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildDropdownFieldWithComment(
    String label,
    CampoEstado campo,
  ) {
    final List<String> initialOptions = [
      '1 Bueno',
      '2 Aceptable',
      '3 Malo',
      '4 No aplica'
    ];
    final List<String> solutionOptions = [
      'Sí',
      'Se intentó',
      'No',
      'No aplica'
    ];

    return Column(
      children: [
        Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconByEstado(campo.initialValue),
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown para estado inicial
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: campo.initialValue,
                decoration: _buildInputDecoration('Estado $label'),
                items: initialOptions.map((String value) {
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case '1 Bueno':
                      textColor = Colors.green;
                      icon =
                          const Icon(Icons.check_circle, color: Colors.green);
                      break;
                    case '2 Aceptable':
                      textColor = Colors.orange;
                      icon = const Icon(Icons.warning, color: Colors.orange);
                      break;
                    case '3 Malo':
                      textColor = Colors.red;
                      icon = const Icon(Icons.error, color: Colors.red);
                      break;
                    case '4 No aplica':
                      textColor = Colors.grey;
                      icon = const Icon(Icons.block, color: Colors.grey);
                      break;
                    default:
                      textColor = Colors.black;
                      icon = null;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (icon != null) icon,
                        if (icon != null) const SizedBox(width: 8),
                        Text(value, style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      campo.initialValue = newValue;
                      widget.onFieldChanged();
                    });
                  }
                },
              ),
            ),

            const SizedBox(width: 10),

            // Dropdown para estado final (solución)
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: campo.solutionValue,
                decoration: _buildInputDecoration('Solución'),
                items: solutionOptions.map((String value) {
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case 'Sí':
                      textColor = Colors.green;
                      icon = const Icon(Icons.check_circle_outline,
                          color: Colors.green);
                      break;
                    case 'Se intentó':
                      textColor = Colors.orange;
                      icon = const Icon(Icons.build_circle_outlined,
                          color: Colors.orange);
                      break;
                    case 'No':
                      textColor = Colors.red;
                      icon =
                          const Icon(Icons.cancel_rounded, color: Colors.red);
                      break;
                    case 'No aplica':
                      textColor = Colors.grey;
                      icon =
                          const Icon(Icons.block_outlined, color: Colors.grey);
                      break;
                    default:
                      textColor = Colors.black;
                      icon = null;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (icon != null) icon,
                        if (icon != null) const SizedBox(width: 8),
                        Text(value, style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      campo.solutionValue = newValue;
                      widget.onFieldChanged();
                    });
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12.0),

        // NUEVA DISTRIBUCIÓN: Comentario + Ícono Cámara en fila
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de comentario
            Expanded(
              flex: 4,
              child: TextFormField(
                onChanged: (value) {
                  campo.comentario = value;
                  widget.onFieldChanged();
                },
                maxLines: 2,
                decoration: _buildInputDecoration('Comentario $label'),
              ),
            ),

            const SizedBox(width: 10),

            // Ícono de cámara
            IconButton(
              onPressed: () => _showCommentDialog(context, label, campo),
              icon: Stack(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: campo.fotos.isNotEmpty
                        ? Colors.green
                        : const Color(0xFFE3D60E),
                  ),
                  if (campo.fotos.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${campo.fotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20.0),
        const Divider(thickness: 1, color: Colors.grey),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Future<void> _showCommentDialog(
      BuildContext context, String label, CampoEstado campo) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'AGREGAR FOTOGRAFÍA PARA: $label',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? photo = await _imagePicker.pickImage(
                            source: ImageSource.camera);
                        if (photo != null) {
                          setState(() {
                            widget.controller
                                .agregarFoto(label, File(photo.path));
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt),
                          const SizedBox(width: 8),
                          Text(campo.fotos.isEmpty
                              ? 'TOMAR FOTO'
                              : 'TOMAR OTRA FOTO'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (campo.fotos.isNotEmpty)
                      Text(
                        'Fotos tomadas: ${campo.fotos.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: campo.fotos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final photo = entry.value;
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
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    widget.controller
                                        .eliminarFoto(label, index);
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ESTADO GENERAL DEL INSTRUMENTO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),

        // Secciones de estado general
        ..._buildSeccionesEstadoGeneral(),
      ],
    );
  }

  List<Widget> _buildSeccionesEstadoGeneral() {
    final secciones = [
      _buildSeccion('ENTORNO DE INSTALACIÓN:', [
        'Vibración',
        'Polvo',
        'Temperatura',
        'Humedad',
        'Mesada',
        'Iluminación',
        'Limpieza de Fosa',
        'Estado de Drenaje'
      ]),
      _buildSeccion('TERMINAL DE PESAJE:', [
        'Carcasa',
        'Teclado Fisico',
        'Display Fisico',
        'Fuente de poder',
        'Bateria operacional',
        'Bracket',
        'Teclado Operativo',
        'Display Operativo',
        'Contector de celda',
        'Bateria de memoria'
      ]),
      _buildSeccion('ESTADO GENERAL DE LA BALANZA:', [
        'Limpieza general',
        'Golpes al terminal',
        'Nivelacion',
        'Limpieza receptor',
        'Golpes al receptor de carga',
        'Encendido'
      ]),
      _buildSeccion('BALANZA | PLATAFORMA:', [
        'Limitador de movimiento',
        'Suspensión',
        'Limitador de carga',
        'Celda de carga'
      ]),
      _buildSeccion('CAJA SUMADORA:', [
        'Tapa de caja sumadora',
        'Humedad Interna',
        'Estado de prensacables',
        'Estado de borneas'
      ]),
    ];

    return secciones;
  }

  Widget _buildSeccion(String titulo, List<String> campos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black54,
          ),
        ),
        const SizedBox(height: 20.0),
        ...campos.map((campo) {
          return _buildDropdownFieldWithComment(campo, widget.campos[campo]!);
        }),
      ],
    );
  }
}
