// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../controllers/mnt_correctivo_controller.dart';
import 'campo_inspeccion_widget.dart';

class PasoInspeccionVisual extends StatefulWidget {
  final MntCorrectivoModel model;
  final MntCorrectivoController controller;

  const PasoInspeccionVisual({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  State<PasoInspeccionVisual> createState() => _PasoInspeccionVisualState();
}

class _PasoInspeccionVisualState extends State<PasoInspeccionVisual> {
  bool _isAllGood = false;

  @override
  Widget build(BuildContext context) {
    final campos = widget.model.inspeccionItems.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildAllGoodCheckbox(campos),
          const SizedBox(height: 24),
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.inspeccionItems[campo]!,
              controller: widget.controller,
              onChanged: () => setState(() {}),
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
          final campo = widget.model.inspeccionItems[fieldName];
          if (campo != null) {
            campo.estado = '1 Bueno';
            campo.comentario = 'En buen estado';
            campo.solucion = 'No aplica';
          }
        }
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          Icon(
            Icons.remove_red_eye_outlined,
            color: Colors.purple,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INSPECCIÓN VISUAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspeccione el estado físico y operacional de los componentes',
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
