// widgets/seca_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class SecaStep extends StatelessWidget {
  final String userName;
  final String fechaServicio;

  const SecaStep({
    Key? key,
    required this.userName,
    required this.fechaServicio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
            Text(
              'CÓDIGO SECA GENERADO',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Resumen de la información
            _buildInfoSummary(controller, context),

            const SizedBox(height: 30),

            // Card principal del SECA
            _buildSecaCard(controller, context),

            const SizedBox(height: 30),

            // Información adicional
            _buildAdditionalInfo(controller, context),
          ],
        );
      },
    );
  }

  Widget _buildInfoSummary(PrecargaController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Resumen de la Información',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Cliente', controller.selectedClienteName ?? 'N/A'),
          const SizedBox(height: 8),
          _buildSummaryRow('Código Planta', controller.selectedPlantaCodigo ?? 'N/A'),
          const SizedBox(height: 8),
          _buildSummaryRow('Técnico', userName),
          const SizedBox(height: 8),
          _buildSummaryRow('Fecha', fechaServicio),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3);
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.blue[800],
            ),
          ),
        ),
      ],
    );
  }

  // Obtiene la parte fija del SECA (año-código_planta-)
  String _getFixedSecaPart(PrecargaController controller) {
    final seca = controller.generatedSeca ?? '';
    final parts = seca.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}-${parts[2]}-';
    }
    return '';
  }

// Obtiene solo la parte de cotización (C01, C02, etc.)
  String _getCotizacionPart(PrecargaController controller) {
    final seca = controller.generatedSeca ?? '';
    final parts = seca.split('-');
    if (parts.length >= 4) {
      return parts[3];
    }
    return 'C01';
  }

  Widget _buildSecaCard(PrecargaController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: controller.secaConfirmed
              ? [Colors.green[100]!, Colors.green[50]!]
              : [Colors.blue[100]!, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: controller.secaConfirmed
              ? Colors.green[300]!
              : Colors.blue[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (controller.secaConfirmed ? Colors.green : Colors.blue)
                .withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Etiqueta
          Text(
            controller.secaConfirmed ? 'SECA Confirmado:' : 'SECA Sugerido:',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: controller.secaConfirmed
                  ? Colors.green[700]
                  : Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Código SECA - ÚNICO CAMPO (editable o fijo según estado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.secaConfirmed
                    ? Colors.green[200]!
                    : Colors.blue[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: controller.secaConfirmed
                ? // Si está confirmado, mostrar texto completo fijo
            Text(
              controller.generatedSeca ?? 'Generando...',
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            )
                : // Si no está confirmado, mostrar partes fijas + campo editable
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Parte fija del SECA (año-código_planta-)
                Text(
                  _getFixedSecaPart(controller),
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    letterSpacing: 2,
                  ),
                ),
                // Campo editable para el número de cotización (C01, C02, etc.)
                Container(
                  width: 90,
                  child: TextField(
                    controller: TextEditingController(
                      text: _getCotizacionPart(controller),
                    ),
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue[300]!,
                          width: 2,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      hintText: 'C01',
                      hintStyle: GoogleFonts.robotoMono(
                        fontSize: 20,
                        color: Colors.blue[300],
                        letterSpacing: 2,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 3,
                    buildCounter: (context,
                        {required currentLength,
                          required isFocused,
                          maxLength}) =>
                    null,
                    onChanged: (value) {
                      // Validar formato C + número
                      if (value.isNotEmpty &&
                          !RegExp(r'^C\d{0,2}$').hasMatch(value)) {
                        return; // No permitir caracteres inválidos
                      }
                      controller.updateNumeroCotizacion(
                          value.isEmpty ? 'C01' : value);
                    },
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),

          const SizedBox(height: 24),

          // Estado
          if (controller.secaConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmado y Registrado',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn().scale(
              begin: const Offset(0.8, 0.8),
            ),

          // Información de la sesión
          if (controller.secaConfirmed && controller.generatedSessionId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.key,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID Sesión: ${controller.generatedSessionId}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildAdditionalInfo(PrecargaController controller, BuildContext context) {
    return Column(
      children: [
        // Información sobre el formato SECA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato del Código SECA',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El código se genera automáticamente usando:\n'
                          '• Código de planta seleccionado\n'
                          '• Numeración correlativa (C01, C02...)\n'
                          '• Año actual (${DateTime.now().year.toString().substring(2)})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        // Proceso siguiente
        if (controller.secaConfirmed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siguiente Paso',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Procederá a la identificación de la balanza y selección de equipos de calibración.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

        // Advertencia sobre datos guardados
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.save,
                color: Colors.purple[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos Guardados',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La información del cliente, planta y SECA se ha guardado en el sistema y estará disponible para futuros servicios.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: 700.ms).fadeIn().scale(
          begin: const Offset(0.9, 0.9),
        ),
      ],
    );
  }
}