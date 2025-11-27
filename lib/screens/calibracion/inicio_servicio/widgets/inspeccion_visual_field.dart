import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../inicio_servicio_controller.dart';

class InspeccionVisualField extends StatefulWidget {
  final String label;
  final InicioServicioController controller;

  const InspeccionVisualField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<InspeccionVisualField> createState() => _InspeccionVisualFieldState();
}

class _InspeccionVisualFieldState extends State<InspeccionVisualField> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isExpanded = false;

  // Mapeo de estados a colores e iconos
  static const Map<String, IconData> _iconMap = {
    'Bueno': Icons.check_circle,
    'Aceptable': Icons.warning,
    'Malo': Icons.error,
    'No aplica': Icons.block,
    'Inexistente': Icons.check_circle,
    'Existente': Icons.error,
    'Sin Daños': Icons.check_circle,
    'Daños Leves': Icons.warning,
    'Dañado': Icons.error,
  };

  static const Map<String, Color> _colorMap = {
    'Bueno': Colors.green,
    'Aceptable': Colors.orange,
    'Malo': Colors.red,
    'No aplica': Colors.grey,
    'Inexistente': Colors.green,
    'Existente': Colors.red,
    'Sin Daños': Colors.green,
    'Daños Leves': Colors.orange,
    'Dañado': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<InicioServicioController>(
      builder: (context, controller, child) {
        final currentValue = controller.fieldData[widget.label]?['value'] ?? '';
        final commentController = controller.commentControllers[widget.label]!;
        final photos = controller.fieldPhotos[widget.label] ?? [];

        final color = _colorMap[currentValue] ?? Colors.grey;
        final icon = _iconMap[currentValue] ?? Icons.help_outline;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Header del campo
              InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Indicador de fotos
                      if (photos.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${photos.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido expandible
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown de Estado
                      _buildDropdownEstado(controller, currentValue),
                      const SizedBox(height: 16),

                      // Campo de comentario
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          labelText: 'Comentario',
                          hintText: 'Agregue observaciones...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.comment_outlined),
                        ),
                        maxLines: 3,
                        onTap: () {
                          if (commentController.text == 'Sin Comentario') {
                            commentController.clear();
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sección de fotos
                      _buildFotosSection(controller, photos),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownEstado(
      InicioServicioController controller, String currentValue) {
    final opciones = _getOptionsForLabel(widget.label);

    return DropdownButtonFormField<String>(
      value: currentValue.isEmpty ? null : currentValue,
      decoration: InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(
          _iconMap[currentValue] ?? Icons.help_outline,
          color: _colorMap[currentValue] ?? Colors.grey,
        ),
      ),
      items: opciones.map((String value) {
        final color = _colorMap[value] ?? Colors.black;
        final icon = _iconMap[value] ?? Icons.circle;

        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: controller.setAllToGood
          ? null
          : (newValue) {
              if (newValue != null) {
                controller.updateFieldData(widget.label, newValue);
              }
            },
    );
  }

  Widget _buildFotosSection(
      InicioServicioController controller, List<File> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotografías (${photos.length}/5)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  photos.length < 5 ? () => _tomarFoto(controller) : null,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('AGREGAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return _buildFotoThumbnail(controller, photos[index], index);
              },
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay fotografías agregadas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFotoThumbnail(
      InicioServicioController controller, File foto, int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              foto,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                controller.removePhoto(widget.label, foto);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tomarFoto(InicioServicioController controller) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        controller.addPhoto(widget.label, File(photo.path));
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
    }
  }

  List<String> _getOptionsForLabel(String label) {
    switch (label) {
      case 'Vibración':
      case 'Polvo':
      case 'Humedad':
      case 'Limpieza Receptor':
        return ['Inexistente', 'Aceptable', 'Existente', 'No aplica'];
      case 'Golpes al Terminal':
      case 'Golpes al receptor de Carga':
        return ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica'];
      default:
        return ['Bueno', 'Aceptable', 'Malo', 'No aplica'];
    }
  }
}
