// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_regular_stac_controller.dart';
import '../../models/mnt_prv_regular_stac_model.dart';
import '../campo_inspeccion_widget.dart';

class PasoGenerico extends StatefulWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final VoidCallback onChanged;
  final List<String> campos;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const PasoGenerico({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
    required this.campos,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  @override
  State<PasoGenerico> createState() => _PasoGenericoState();
}

class _PasoGenericoState extends State<PasoGenerico> {
  bool _isAllGood = false;

  @override
  void didUpdateWidget(PasoGenerico oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resetear el checkbox cuando cambian los campos (cambio de paso)
    if (oldWidget.campos != widget.campos) {
      _isAllGood = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildAllGoodCheckbox(widget.campos),
          const SizedBox(height: 24),

          // Lista de campos
          ...widget.campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllGoodCheckbox(List<String> campos) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isAllGood
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAllGood
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Marcar todo como "Buen Estado"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isAllGood
              ? 'Todos los campos están en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos',
          style: TextStyle(
            fontSize: 12,
            color: _isAllGood ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        value: _isAllGood,
        onChanged: (bool? value) {
          _toggleAllGood(value ?? false, campos);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleAllGood(bool isGood, List<String> campos) {
    setState(() {
      _isAllGood = isGood;

      if (isGood) {
        for (final fieldName in campos) {
          final campo = widget.model.camposEstado[fieldName];
          if (campo != null) {
            campo.initialValue = '1 Bueno';
            campo.comentario = 'En buen estado';
            campo.solutionValue = 'No aplica';
          }
        }
        widget.onChanged();
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? widget.color.withOpacity(0.1)
            : widget.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.icono,
            color: widget.color,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitulo,
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
}
