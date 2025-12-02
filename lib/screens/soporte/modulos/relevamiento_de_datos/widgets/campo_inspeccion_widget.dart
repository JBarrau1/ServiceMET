import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/relevamiento_de_datos_model.dart';
import '../controllers/relevamiento_de_datos_controller.dart';

class CampoInspeccionWidget extends StatefulWidget {
  final String label;
  final CampoEstado campo;
  final RelevamientoDeDatosController controller;
  final VoidCallback onChanged;
  final List<String>? customOptions; // ✅ Nuevo parámetro opcional

  const CampoInspeccionWidget({
    super.key,
    required this.label,
    required this.campo,
    required this.controller,
    required this.onChanged,
    this.customOptions, // ✅ Inicializar
  });

  @override
  State<CampoInspeccionWidget> createState() => _CampoInspeccionWidgetState();
}

class _CampoInspeccionWidgetState extends State<CampoInspeccionWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isExpanded = false;

  // Mapeo de estados a colores e iconos
  static const Map<String, IconData> _iconMap = {
    '1 Bueno': Icons.check_circle,
    '2 Aceptable': Icons.warning,
    '3 Malo': Icons.error,
    '4 No aplica': Icons.block,
  };

  static const Map<String, Color> _colorMap = {
    '1 Bueno': Colors.green,
    '2 Aceptable': Colors.orange,
    '3 Malo': Colors.red,
    '4 No aplica': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final estado = widget.campo.initialValue;

    // ✅ Usar color/icono por defecto si no está en el mapa (para opciones personalizadas)
    final color =
        _colorMap[estado] ?? (isDarkMode ? Colors.blueAccent : Colors.blue);
    final icon = _iconMap[estado] ?? Icons.info_outline;

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  if (widget.campo.fotos.isNotEmpty)
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
                            '${widget.campo.fotos.length}',
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
                  _buildDropdownEstado(),
                  const SizedBox(height: 16),

                  // Campo de comentario
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Comentario',
                      hintText: 'Agregue observaciones...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.comment_outlined),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      widget.campo.comentario = value;
                      widget.onChanged();
                    },
                    controller:
                        TextEditingController(text: widget.campo.comentario)
                          ..selection = TextSelection.collapsed(
                            offset: widget.campo.comentario.length,
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Sección de fotos
                  _buildFotosSection(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownEstado() {
    // ✅ Usar opciones personalizadas si existen, sino las por defecto
    final opciones = widget.customOptions ??
        ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'];

    // ✅ Validar que el valor inicial esté en las opciones
    String initialValue = widget.campo.initialValue;
    if (initialValue.isEmpty || !opciones.contains(initialValue)) {
      initialValue = opciones.first;
      // Actualizar el modelo si el valor cambió forzosamente
      if (initialValue != widget.campo.initialValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              widget.campo.initialValue = initialValue;
              widget.onChanged();
            });
          }
        });
      }
    }

    return DropdownButtonFormField<String>(
      value:
          initialValue, // ✅ Usar value en lugar de initialValue para control reactivo
      decoration: InputDecoration(
        labelText: widget.customOptions != null
            ? 'Selección'
            : 'Estado', // Etiqueta dinámica
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(
          _iconMap[initialValue] ??
              Icons.check_circle_outline, // Icono por defecto
          color: _colorMap[initialValue] ?? Colors.blue, // Color por defecto
        ),
      ),
      items: opciones.map((String value) {
        final color = _colorMap[value] ?? Colors.black87;
        final icon = _iconMap[value] ?? Icons.circle_outlined;

        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              if (widget.customOptions == null) ...[
                // Solo mostrar iconos si son opciones estándar
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: TextStyle(
                    color: widget.customOptions != null ? null : color,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            widget.campo.initialValue = newValue;
            widget.onChanged();
          });
        }
      },
    );
  }

  Widget _buildFotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotografías (${widget.campo.fotos.length}/5)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  widget.campo.fotos.length < 5 ? () => _tomarFoto() : null,
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
        if (widget.campo.fotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.campo.fotos.length,
              itemBuilder: (context, index) {
                return _buildFotoThumbnail(widget.campo.fotos[index], index);
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

  Widget _buildFotoThumbnail(File foto, int index) {
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
                setState(() {
                  widget.controller.eliminarFoto(widget.label, index);
                  widget.onChanged();
                });
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

  Future<void> _tomarFoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // Comprimir automáticamente
      );

      if (photo != null) {
        setState(() {
          widget.controller.agregarFoto(widget.label, File(photo.path));
          widget.onChanged();
        });
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
