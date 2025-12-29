// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/relevamiento_de_datos_model.dart';
import '../../controllers/relevamiento_de_datos_controller.dart';
import '../../utils/constants.dart';
import '../campo_inspeccion_widget.dart';

class PasoTerminalPlataformaCeldas extends StatefulWidget {
  final RelevamientoDeDatosModel model;
  final RelevamientoDeDatosController controller;
  final VoidCallback onChanged;

  const PasoTerminalPlataformaCeldas({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<PasoTerminalPlataformaCeldas> createState() =>
      _PasoTerminalPlataformaCeldasState();
}

class _PasoTerminalPlataformaCeldasState
    extends State<PasoTerminalPlataformaCeldas> {
  // Estado de los checkboxes por sector
  final Map<String, bool> _sectorGoodState = {
    'TERMINAL': false,
    'PLATAFORMA': false,
    'CELDAS DE CARGA': false,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección Terminal
          _buildSectionHeader(
            context,
            title: 'TERMINAL',
            subtitle: 'Inspeccione el estado del terminal de pesaje',
            icon: Icons.computer_outlined,
            color: Colors.purple,
          ),
          _buildSectorCheckbox('TERMINAL'),
          const SizedBox(height: 16),
          ...AppConstants.terminalCampos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),

          const SizedBox(height: 32),

          // Sección Plataforma
          _buildSectionHeader(
            context,
            title: 'PLATAFORMA',
            subtitle: 'Inspeccione el estado de la plataforma',
            icon: Icons.square_outlined,
            color: Colors.teal,
          ),
          _buildSectorCheckbox('PLATAFORMA'),
          const SizedBox(height: 16),
          ...AppConstants.plataformaCampos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),

          const SizedBox(height: 32),

          // Sección Celdas de Carga
          _buildSectionHeader(
            context,
            title: 'CELDAS DE CARGA',
            subtitle: 'Inspeccione el estado de las celdas de carga',
            icon: Icons.sensors_outlined,
            color: Colors.orange,
          ),
          _buildSectorCheckbox('CELDAS DE CARGA'),
          const SizedBox(height: 16),
          ...AppConstants.celdasCargaCampos.map((campo) {
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildSectorCheckbox(String sector) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sectorGoodState[sector] == true
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _sectorGoodState[sector] == true
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          'Marcar todo el sector "$sector" como "Buen Estado"',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _sectorGoodState[sector] == true
              ? 'Todos los campos se establecerán en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos del sector',
          style: TextStyle(
            fontSize: 12,
            color: _sectorGoodState[sector] == true
                ? Colors.green[700]
                : Colors.grey[600],
          ),
        ),
        value: _sectorGoodState[sector],
        onChanged: (bool? value) {
          _toggleSectorGoodState(sector, value ?? false);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleSectorGoodState(String sector, bool isGood) {
    setState(() {
      _sectorGoodState[sector] = isGood;

      // Obtener campos del sector
      List<String> fields = [];
      if (sector == 'TERMINAL') {
        fields = AppConstants.terminalCampos;
      } else if (sector == 'PLATAFORMA') {
        fields = AppConstants.plataformaCampos;
      } else if (sector == 'CELDAS DE CARGA') {
        fields = AppConstants.celdasCargaCampos;
      }

      if (isGood) {
        // Aplicar "1 Bueno" a todos los campos del sector
        for (final field in fields) {
          final campo = widget.model.camposEstado[field];
          if (campo != null) {
            campo.initialValue = '1 Bueno';
            campo.comentario = 'En buen estado';
          }
        }
      }
      // Si se desactiva, los campos mantienen sus valores actuales

      widget.onChanged();
    });
  }
}
