import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/excentricidad_form.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/linealidad/linealidad_form.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_form.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/pruebas_metrologicas_controller.dart';
import 'package:service_met/screens/calibracion/fin_servicios/fin_servicios_screen.dart';
import 'package:service_met/screens/calibracion/precarga/widgets/step_indicator.dart';
import '../../provider/balanza_provider.dart';

class CalibrationFlowScreen extends StatefulWidget {
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final Map<String, dynamic> selectedBalanza;

  const CalibrationFlowScreen({
    super.key,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.selectedBalanza,
  });

  @override
  State<CalibrationFlowScreen> createState() => _CalibrationFlowScreenState();
}

class _CalibrationFlowScreenState extends State<CalibrationFlowScreen> {
  DateTime? _lastPressedTime;

  final List<StepData> _steps = const [
    StepData(
      title: 'Excentricidad',
      subtitle: 'Pruebas de Excentricidad',
      icon: Icons.center_focus_strong,
    ),
    StepData(
      title: 'Repetibilidad',
      subtitle: 'Pruebas de Repetibilidad',
      icon: Icons.repeat,
    ),
    StepData(
      title: 'Linealidad',
      subtitle: 'Pruebas de Linealidad',
      icon: Icons.show_chart,
    ),
  ];

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(
          'Presione nuevamente para salir. Los datos no guardados se perderán.',
          isError: true);
      return false;
    }
    return true;
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                'FINALIZAR PRUEBAS',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas finalizar las pruebas metrológicas?',
            style: GoogleFonts.inter(fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Seguir Editando',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigateToRcaFinalScreen();
              },
              child: Text(
                'Continuar',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _navigateToRcaFinalScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinServiciosScreen(
          selectedBalanza: widget.selectedBalanza,
          secaValue: widget.secaValue,
          sessionId: widget.sessionId,
          codMetrica: widget.codMetrica,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => PruebasMetrologicasController(
        codMetrica: widget.codMetrica,
        secaValue: widget.secaValue,
        sessionId: widget.sessionId,
        context: context,
      ),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: _buildAppBar(isDarkMode),
          body: Consumer<PruebasMetrologicasController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  StepIndicator(
                    currentStep: controller.currentStep,
                    steps: _steps,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildCurrentStepContent(controller),
                    ),
                  ),
                  _buildBottomButtons(context, controller),
                ],
              );
            },
          ),
          floatingActionButton: _buildSpeedDial(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AppBar(
            toolbarHeight: 70,
            title: Column(
              children: [
                Text(
                  'CALIBRACIÓN',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  'Pruebas Metrológicas',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                ),
              ],
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

  Widget _buildCurrentStepContent(PruebasMetrologicasController controller) {
    switch (controller.currentStep) {
      case 0:
        return ExcentricidadForm(
            controller: controller.excentricidadController);
      case 1:
        return RepetibilidadForm(
            controller: controller.repetibilidadController);
      case 2:
        return LinealidadForm(controller: controller.linealidadController);
      default:
        return const Center(child: Text('Paso no disponible'));
    }
  }

  Widget _buildBottomButtons(
      BuildContext context, PruebasMetrologicasController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón Anterior
            if (controller.currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.previousStep,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            if (controller.currentStep > 0) const SizedBox(width: 12),

            // Botón Siguiente o Finalizar
            Expanded(
              child: controller.currentStep < _steps.length - 1
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        // Guardar datos del paso actual antes de avanzar
                        if (controller.currentStep == 0) {
                          await controller.excentricidadController
                              .saveDataToDatabase(context);
                        } else if (controller.currentStep == 1) {
                          await controller.repetibilidadController
                              .saveDataToDatabase();
                        } else if (controller.currentStep == 2) {
                          await controller.linealidadController
                              .saveDataToDatabase();
                        }
                        controller.nextStep();
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Siguiente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        textStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () async {
                        // Guardar último paso
                        await controller.linealidadController
                            .saveDataToDatabase();
                        _showConfirmationDialog();
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        textStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        spacing: 12,
        spaceBetweenChildren: 12,
        iconTheme: const IconThemeData(color: Colors.black87, size: 24),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.black87,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        elevation: 8,
        animationCurve: Curves.easeInOut,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.info_outline, size: 24),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Info de la balanza',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.blue,
            onTap: _showBalanzaInfo,
          ),
          SpeedDialChild(
            child: const Icon(Icons.history, size: 24),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Último servicio',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.orange,
            onTap: _showLastServiceData,
          ),
        ],
      ),
    );
  }

  void _showBalanzaInfo() {
    final balanza =
        Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.scale, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Información de la Balanza',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: balanza != null
                        ? ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            children: [
                              _buildDetailContainer(
                                  'Código Métrica', balanza.cod_metrica),
                              _buildDetailContainer(
                                  'Unidades', balanza.unidad.toString()),
                              _buildSectionHeader('Rango 1'),
                              _buildDetailContainer('pmax1', balanza.cap_max1),
                              _buildDetailContainer(
                                  'd1', balanza.d1.toString()),
                              _buildDetailContainer(
                                  'e1', balanza.e1.toString()),
                              _buildDetailContainer(
                                  'dec1', balanza.dec1.toString()),
                              _buildSectionHeader('Rango 2'),
                              _buildDetailContainer('pmax2', balanza.cap_max2),
                              _buildDetailContainer(
                                  'd2', balanza.d2.toString()),
                              _buildDetailContainer(
                                  'e2', balanza.e2.toString()),
                              _buildDetailContainer(
                                  'dec2', balanza.dec2.toString()),
                              _buildSectionHeader('Rango 3'),
                              _buildDetailContainer('pmax3', balanza.cap_max3),
                              _buildDetailContainer(
                                  'd3', balanza.d3.toString()),
                              _buildDetailContainer(
                                  'e3', balanza.e3.toString()),
                              _buildDetailContainer(
                                  'dec3', balanza.dec3.toString()),
                              const SizedBox(height: 20),
                            ],
                          )
                        : Center(
                            child: Text(
                              'No hay información disponible',
                              style: GoogleFonts.inter(fontSize: 15),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLastServiceData() {
    final lastServiceData =
        Provider.of<BalanzaProvider>(context, listen: false).lastServiceData;

    if (lastServiceData == null) {
      _showSnackBar('No hay datos de servicio disponibles', isError: true);
      return;
    }

    final Map<String, String> fieldLabels = {
      'reg_fecha': 'Fecha del Último Servicio',
      'reg_usuario': 'Técnico Responsable',
      'seca': 'Último SECA',
      'exc': 'Excentricidad',
    };

    for (int i = 1; i <= 30; i++) {
      fieldLabels['rep$i'] = 'Repetibilidad $i';
    }

    for (int i = 1; i <= 60; i++) {
      fieldLabels['lin$i'] = 'Linealidad $i';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Último Servicio',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      children: [
                        ...lastServiceData.entries
                            .where((entry) =>
                                entry.value != null &&
                                fieldLabels.containsKey(entry.key))
                            .map((entry) => _buildDetailContainer(
                                fieldLabels[entry.key]!,
                                entry.key == 'reg_fecha'
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(DateTime.parse(entry.value))
                                    : entry.value.toString())),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF667EEA),
        ),
      ),
    );
  }

  Widget _buildDetailContainer(String label, String value) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.03),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
