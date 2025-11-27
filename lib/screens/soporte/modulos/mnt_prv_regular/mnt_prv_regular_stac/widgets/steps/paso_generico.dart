import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_regular_stac_controller.dart';
import '../../models/mnt_prv_regular_stac_model.dart';
import '../campo_inspeccion_widget.dart';

class PasoGenerico extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
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
