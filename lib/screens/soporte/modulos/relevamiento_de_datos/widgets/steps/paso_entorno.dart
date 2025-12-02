import 'package:flutter/material.dart';
import '../../models/relevamiento_de_datos_model.dart';
import '../../controllers/relevamiento_de_datos_controller.dart';
import '../../utils/constants.dart';
import '../campo_inspeccion_widget.dart';

class PasoEntorno extends StatefulWidget {
  final RelevamientoDeDatosModel model;
  final RelevamientoDeDatosController controller;
  final VoidCallback onChanged;

  const PasoEntorno({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<PasoEntorno> createState() => _PasoEntornoState();
}

class _PasoEntornoState extends State<PasoEntorno> {
  bool _allGoodState = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          _buildSectorCheckbox(),
          const SizedBox(height: 16),

          // Campos de entorno usando CampoInspeccionWidget
          ...AppConstants.entornoCampos.entries.map((entry) {
            final campo = entry.key;
            final opciones = entry.value;

            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
              customOptions: opciones, // ✅ Pasar opciones personalizadas
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.domain_outlined,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTORNO DE INSTALACIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspeccione las condiciones ambientales y de instalación',
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

  Widget _buildSectorCheckbox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _allGoodState
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _allGoodState
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Marcar todo el sector "ENTORNO" como "Buen Estado"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _allGoodState
              ? 'Todos los campos se establecerán en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos del sector',
          style: TextStyle(
            fontSize: 12,
            color: _allGoodState ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        value: _allGoodState,
        onChanged: (bool? value) {
          _toggleAllGoodState(value ?? false);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleAllGoodState(bool isGood) {
    setState(() {
      _allGoodState = isGood;

      if (isGood) {
        // Aplicar "1 Bueno" a todos los campos de entorno
        for (final campo in AppConstants.entornoCampos.keys) {
          final campoEstado = widget.model.camposEstado[campo];
          if (campoEstado != null) {
            campoEstado.initialValue = '1 Bueno';
            campoEstado.comentario = 'En buen estado';
          }
        }
      }
      // Si se desactiva, los campos mantienen sus valores actuales

      widget.onChanged();
    });
  }
}
