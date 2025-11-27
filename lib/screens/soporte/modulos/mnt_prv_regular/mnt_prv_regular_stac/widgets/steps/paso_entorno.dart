import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_regular_stac_controller.dart';
import '../../models/mnt_prv_regular_stac_model.dart';
import '../campo_inspeccion_widget.dart';

class PasoEntorno extends StatelessWidget {
  final MntPrvRegularStacModel model;
  final MntPrvRegularStacController controller;
  final VoidCallback onChanged;

  const PasoEntorno({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

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
          const SizedBox(height: 24),

          // Lista de campos
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: model.camposEstado[campo]!,
              controller: controller,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
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
