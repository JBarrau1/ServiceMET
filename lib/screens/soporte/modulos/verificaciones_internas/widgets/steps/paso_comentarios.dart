import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/verificaciones_internas_model.dart';

class PasoComentarios extends StatefulWidget {
  final VerificacionesInternasModel model;
  final VoidCallback onChanged;

  const PasoComentarios({
    super.key,
    required this.model,
    required this.onChanged,
  });

  @override
  State<PasoComentarios> createState() => _PasoComentariosState();
}

class _PasoComentariosState extends State<PasoComentarios> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (photo != null) {
        setState(() {
          widget.model.comentarios[index].fotos.add(File(photo.path));
          widget.onChanged();
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addComentario() {
    if (widget.model.comentarios.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 10 comentarios permitidos')),
      );
      return;
    }
    setState(() {
      widget.model.comentarios.add(ComentarioData());
      widget.onChanged();
    });
  }

  void _removeComentario(int index) {
    setState(() {
      widget.model.comentarios.removeAt(index);
      widget.onChanged();
    });
  }

  void _removeFoto(int comentarioIndex, int fotoIndex) {
    setState(() {
      widget.model.comentarios[comentarioIndex].fotos.removeAt(fotoIndex);
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDarkMode),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.model.comentarios.length,
            itemBuilder: (context, index) {
              return _buildComentarioCard(index, isDarkMode);
            },
          ),
          const SizedBox(height: 16),
          if (widget.model.comentarios.length < 10)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addComentario,
                icon: const Icon(Icons.add_comment, color: Colors.white),
                label: const Text('AGREGAR COMENTARIO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.purple.withOpacity(0.1)
            : Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.comment_outlined,
            color: Colors.purple,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMENTARIOS Y OBSERVACIONES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agregue comentarios adicionales y fotos de evidencia',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioCard(int index, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comentario ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeComentario(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.model.comentarios[index].comentario,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ingrese su comentario...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                widget.model.comentarios[index].comentario = value;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.model.comentarios[index].fotos.asMap().entries.map(
                      (entry) =>
                          _buildPhotoThumb(index, entry.key, entry.value),
                    ),
                _buildAddPhotoButton(index),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumb(int commentIndex, int photoIndex, File photo) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            photo,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeFoto(commentIndex, photoIndex),
            child: Container(
              color: Colors.black54,
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton(int index) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }
}
