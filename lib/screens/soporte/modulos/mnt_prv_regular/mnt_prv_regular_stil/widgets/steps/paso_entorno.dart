import 'package:flutter/material.dart';
import '../../models/mnt_prv_regular_stil_model.dart';
import '../../controllers/mnt_prv_regular_stil_controller.dart';
import '../campo_inspeccion_widget.dart';

class PasoEntorno extends StatefulWidget {
  final MntPrvRegularStilModel model;
  final MntPrvRegularStilController controller;
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
  bool _isAllGood = false;

  @override
  Widget build(BuildContext context) {
    final campos = [
      'Vibración',
      'Polvo',
      'Temperatura',
      'Humedad',
      'Mesada',
      'Iluminación',
      'Limpieza de Fosa',
      'Estado de Drenaje',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildAllGoodCheckbox(campos),
          const SizedBox(height: 24),

          // Lista de campos
          ...campos.map((campo) {
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
          Icon(
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
}
