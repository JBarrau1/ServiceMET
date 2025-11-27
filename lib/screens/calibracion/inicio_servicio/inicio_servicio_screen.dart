import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/calibration_flow.dart';
import 'package:service_met/screens/calibracion/precarga/widgets/step_indicator.dart';
import '../../../provider/balanza_provider.dart';
import 'inicio_servicio_controller.dart';
import 'widgets/inspeccion_visual_step.dart';
import 'widgets/precargas_ajuste_step.dart';

class InicioServicioScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String codMetrica;
  final String nReca;

  const InicioServicioScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.codMetrica,
    required this.nReca,
  });

  @override
  State<InicioServicioScreen> createState() => _InicioServicioScreenState();
}

class _InicioServicioScreenState extends State<InicioServicioScreen> {
  late InicioServicioController controller;

  @override
  void initState() {
    super.initState();
    controller = InicioServicioController(
      sessionId: widget.sessionId,
      secaValue: widget.secaValue,
      codMetrica: widget.codMetrica,
      nReca: widget.nReca,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<InicioServicioController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                StepIndicator(
                  currentStep: controller.currentStep,
                  steps: const [
                    StepData(
                      title: 'Inspección',
                      subtitle: 'Visual y Ambiental',
                      icon: Icons.visibility,
                    ),
                    StepData(
                      title: 'Pruebas',
                      subtitle: 'Precargas y Ajuste',
                      icon: Icons.build,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentStepContent(controller),
                  ),
                ),
                _buildBottomButtons(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AppBar(
            toolbarHeight: 70,
            title: Text(
              'CALIBRACIÓN',
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16.0,
              ),
            ),
            backgroundColor: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.7),
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(InicioServicioController controller) {
    switch (controller.currentStep) {
      case 0:
        return const InspeccionVisualStep();
      case 1:
        return const PrecargasAjusteStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButtons(InicioServicioController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.currentStep > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.previousStep(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (controller.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleNextButton(controller),
              icon: Icon(controller.currentStep == 1
                  ? Icons.save
                  : Icons.arrow_forward),
              label: Text(controller.currentStep == 1
                  ? 'Finalizar y Continuar'
                  : 'Siguiente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.currentStep == 1
                    ? Colors.green
                    : const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextButton(InicioServicioController controller) async {
    if (controller.currentStep == 0) {
      if (controller.validateStep1()) {
        await controller.saveStep1();
        controller.nextStep();
      } else {
        _showSnackBar('Por favor complete todos los campos requeridos',
            isError: true);
      }
    } else if (controller.currentStep == 1) {
      if (controller.validateStep2()) {
        await controller.saveStep2();
        _navigateToCalibrationFlow();
      } else {
        _showSnackBar('Por favor complete todos los campos requeridos',
            isError: true);
      }
    }
  }

  void _navigateToCalibrationFlow() {
    final balanzaProvider =
        Provider.of<BalanzaProvider>(context, listen: false);
    // Convert Balanza model to Map if necessary, or use what's available
    // CalibrationFlowScreen expects Map<String, dynamic> selectedBalanza
    // Assuming BalanzaProvider has a way to get this or we construct it.
    // The original code passed `widget.selectedBalanza` which came from somewhere.
    // In PrecargaScreen, it navigates to ServicioScreen, which navigates to PruebasScreen.
    // PruebasScreen used Provider to get balanza.

    // We need to construct the map or get it.
    // BalanzaProvider usually has `selectedBalanza` which is a `Balanza` object.
    // We might need to convert it to map.

    final balanza = balanzaProvider.selectedBalanza;
    final balanzaMap = balanza != null
        ? {
            'cod_metrica': balanza.cod_metrica,
            'unidad': balanza.unidad,
            'cap_max1': balanza.cap_max1,
            'd1': balanza.d1,
            'e1': balanza.e1,
            'dec1': balanza.dec1,
            'cap_max2': balanza.cap_max2,
            'd2': balanza.d2,
            'e2': balanza.e2,
            'dec2': balanza.dec2,
            'cap_max3': balanza.cap_max3,
            'd3': balanza.d3,
            'e3': balanza.e3,
            'dec3': balanza.dec3,
            'n_celdas': balanza.n_celdas,
            'exc': balanza.exc,
          }
        : <String, dynamic>{};

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CalibrationFlowScreen(
          codMetrica: widget.codMetrica,
          secaValue: widget.secaValue,
          sessionId: widget.sessionId,
          selectedBalanza: balanzaMap,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
