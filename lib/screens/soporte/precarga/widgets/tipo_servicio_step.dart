// widgets/tipo_servicio_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class TipoServicioStep extends StatelessWidget {
  const TipoServicioStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaControllerSop>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
            Text(
              'SELECCIÓN DE TIPO DE SERVICIO',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Grid de servicios
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildServiceCard(
                  context,
                  controller,
                  'Relevamiento de Datos',
                  'relevamiento_de_datos',
                  Icons.assignment,
                  Color(0xFF3D705B),
                ),
                _buildServiceCard(
                  context,
                  controller,
                  'Ajustes Metrológicos',
                  'ajustes_metrologicos',
                  Icons.tune,
                  Color(0xFF3D6270),
                ),
                _buildServiceCard(context, controller, 'Diagnóstico',
                    'diagnostico', Icons.search, Color(0xFF6E703D)),
                _buildServiceCard(
                  context,
                  controller,
                  'Mnt. Prev. Regular',
                  'mnt_prv_regular',
                  Icons.build,
                  Color(0xFF70463D),
                  hasSubtypes: true,
                ),
                _buildServiceCard(
                  context,
                  controller,
                  'Mnt. Prev. Avanzado',
                  'mnt_prv_avanzado',
                  Icons.engineering,
                  Color(0xFF70643D),
                  hasSubtypes: true,
                ),
                _buildServiceCard(
                  context,
                  controller,
                  'Mnt. Correctivo',
                  'mnt_correctivo',
                  Icons.handyman,
                  Colors.teal,
                ),
                _buildServiceCard(
                  context,
                  controller,
                  'Instalación',
                  'instalacion',
                  Icons.settings,
                  Colors.indigo,
                ),
                _buildServiceCard(
                  context,
                  controller,
                  'Verificaciones Internas',
                  'verificaciones_internas',
                  Icons.verified,
                  Colors.cyan,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Mostrar selección actual
            if (controller.selectedTipoServicio != null)
              _buildSelectedServiceInfo(controller),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    PrecargaControllerSop controller,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool hasSubtypes = false,
  }) {
    final isSelected = controller.selectedTipoServicio == value ||
        (hasSubtypes &&
            (controller.selectedTipoServicio == '${value}_stac' ||
                controller.selectedTipoServicio == '${value}_stil'));

    return GestureDetector(
      onTap: () {
        if (hasSubtypes) {
          _showSubtypeDialog(context, controller, label, value, color);
        } else {
          controller.selectTipoServicio(value, null);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12), // Reducido de 16 a 12
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF317833)
              : Colors.white, // Color 2E2E2E cuando está seleccionado
          borderRadius: BorderRadius.circular(
              12), // Aumentado de 16 a 12 (más cuadrado pero con buen border radius)
          border: Border.all(
            color: isSelected ? const Color(0xFF317833) : Colors.grey[300]!,
            width: isSelected
                ? 2
                : 1, // Reducido de 3 a 2 para hacerlo más pequeño
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6, // Reducido de 8 a 6
              offset: const Offset(0, 3), // Reducido de 4 a 3
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Reducido de 12 a 10
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF2E2E2E).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28, // Reducido de 32 a 28
                color: isSelected ? const Color(0xFF2E2E2E) : color,
              ),
            ),
            const SizedBox(height: 10), // Reducido de 12 a 10
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12, // Reducido de 13 a 12
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : Colors.grey[800], // Texto blanco cuando está seleccionado
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSubtypes)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFF317833).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STAC/STIL',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF317833),
                  ),
                ),
              ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 6), // Reducido de 8 a 6
                child: Icon(
                  Icons.check_circle,
                  color: Colors
                      .white, // Icono blanco para contrastar con el fondo oscuro
                  size: 18, // Reducido de 20 a 18
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: (100 * _getCardIndex(value)).ms).fadeIn().scale();
  }

  void _showSubtypeDialog(
    BuildContext context,
    PrecargaControllerSop controller,
    String label,
    String baseValue,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Seleccionar Categoría',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _buildSubtypeButton(
                context,
                controller,
                'STAC',
                '${baseValue}_stac',
                color,
              ),
              const SizedBox(height: 12),
              _buildSubtypeButton(
                context,
                controller,
                'STIL',
                '${baseValue}_stil',
                color,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtypeButton(
    BuildContext context,
    PrecargaControllerSop controller,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          controller.selectTipoServicio(value, label);
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServiceInfo(PrecargaControllerSop controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servicio Seleccionado',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  controller.selectedTipoServicioLabel ?? 'No especificado',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3);
  }

  int _getCardIndex(String value) {
    final services = [
      'relevamiento_de_datos',
      'ajustes_metrologicos',
      'diagnostico',
      'mnt_prv_regular',
      'mnt_prv_avanzado',
      'mnt_correctivo',
      'instalacion',
      'verificaciones_internas',
    ];
    return services.indexOf(value);
  }
}
