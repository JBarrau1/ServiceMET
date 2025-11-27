// widgets/seca_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class SecaStep extends StatefulWidget {
  final String userName;
  final String fechaServicio;

  const SecaStep({
    super.key,
    required this.userName,
    required this.fechaServicio,
  });

  @override
  State<SecaStep> createState() => _SecaStepState();
}

class _SecaStepState extends State<SecaStep> {
  late TextEditingController _cotizacionController;

  @override
  void initState() {
    super.initState();
    _cotizacionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCotizacion();
    });
  }

  @override
  void dispose() {
    _cotizacionController.dispose();
    super.dispose();
  }

  void _initializeCotizacion() {
    final controller =
        Provider.of<PrecargaControllerSop>(context, listen: false);
    _cotizacionController.text = _getCotizacionPart(controller);
  }

  String _getFixedOtstPart(PrecargaControllerSop controller) {
    final otst = controller.generatedSeca ??
        ''; // Internamente sigue siendo _generatedSeca
    final parts = otst.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}-${parts[2]}-';
    }
    return '';
  }

  String _getCotizacionPart(PrecargaControllerSop controller) {
    final otst = controller.generatedSeca ?? '';
    final parts = otst.split('-');
    if (parts.length >= 4) {
      return parts[3];
    }
    return 'S01';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaControllerSop>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título - CAMBIAR A OTST
            Text(
              'CÓDIGO OTST GENERADO',
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

            // Card principal del OTST
            _buildOtstCard(controller, context),

            const SizedBox(height: 30),

            // Información adicional
            _buildAdditionalInfo(controller, context),
          ],
        );
      },
    );
  }

  Widget _buildInfoSummary(
      PrecargaControllerSop controller, BuildContext context) {
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
          _buildSummaryRow('Tipo de Servicio',
              controller.selectedTipoServicioLabel ?? 'N/A'),
          const SizedBox(height: 8),
          _buildSummaryRow('Cliente', controller.selectedClienteName ?? 'N/A'),
          const SizedBox(height: 8),
          _buildSummaryRow(
              'Código Planta', controller.selectedPlantaCodigo ?? 'N/A'),
          const SizedBox(height: 8),
          _buildSummaryRow('Técnico', widget.userName),
          const SizedBox(height: 8),
          _buildSummaryRow('Fecha', widget.fechaServicio),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3);
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
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

  Widget _buildOtstCard(
      PrecargaControllerSop controller, BuildContext context) {
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
          color:
              controller.secaConfirmed ? Colors.green[300]! : Colors.blue[300]!,
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
          // Etiqueta - CAMBIAR A OTST
          Text(
            controller.secaConfirmed ? 'OTST Confirmado:' : 'OTST Sugerido:',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: controller.secaConfirmed
                  ? Colors.green[700]
                  : Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Código OTST - Confirmado (solo lectura)
          if (controller.secaConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                controller.generatedSeca ?? 'Generando...',
                style: GoogleFonts.robotoMono(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate(delay: 300.ms).fadeIn()
          else
            // Código OTST - No confirmado (editable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Parte fija
                  Text(
                    _getFixedOtstPart(controller),
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      letterSpacing: 2,
                    ),
                  ),
                  // Campo editable
                  SizedBox(
                    width: 85,
                    child: TextField(
                      controller: _cotizacionController,
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintText: 'S01',
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
                        if (value.isEmpty) return;

                        // Forzar que empiece con 'S'
                        if (!value.startsWith('S')) {
                          _cotizacionController.text = 'S';
                          _cotizacionController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: 1),
                          );
                          return;
                        }

                        // Solo permitir S seguido de dígitos
                        if (value.length > 1 &&
                            !RegExp(r'^S\d{0,2}$').hasMatch(value)) {
                          final previousText = _cotizacionController.text;
                          if (previousText.isNotEmpty) {
                            _cotizacionController.text = previousText.substring(
                                0, previousText.length - 1);
                            _cotizacionController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _cotizacionController.text.length),
                            );
                          }
                          return;
                        }

                        // Si se completó el formato S##, actualizar el OTST
                        if (RegExp(r'^S\d{2}$').hasMatch(value)) {
                          final numero = int.tryParse(value.substring(1));

                          if (numero == null || numero < 1 || numero > 99) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('El número debe estar entre 01 y 99'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          try {
                            final ctrl = Provider.of<PrecargaControllerSop>(
                              context,
                              listen: false,
                            );
                            ctrl.updateNumeroCotizacion(value);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'OTST actualizado: ${ctrl.generatedSeca}'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 24),

          // Estado de confirmación
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
            ).animate(delay: 400.ms).fadeIn().scale(
                  begin: const Offset(0.8, 0.8),
                ),

          // ID Sesión
          if (controller.secaConfirmed &&
              controller.generatedSessionId != null) ...[
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
                  Flexible(
                    child: Text(
                      'ID Sesión: ${controller.generatedSessionId}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildAdditionalInfo(
      PrecargaControllerSop controller, BuildContext context) {
    return Column(
      children: [
        // Información sobre formato OTST
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
                      'Formato del Código OTST',
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
                      '• Numeración correlativa (S01, S02...)\n'
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

        // Siguiente paso
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
                        'Procederá a la identificación de la balanza para el servicio de soporte técnico.',
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

        // Datos guardados
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
                      'La información del servicio, cliente, planta y OTST se ha guardado en el sistema.',
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
