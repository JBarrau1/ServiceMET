// servicio_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'servicio_controller.dart';
import 'widgets/servicio_step_indicator.dart';
import 'widgets/condiciones_iniciales_step.dart';
import 'widgets/precargas_step.dart';
import 'widgets/excentricidad_step.dart';
import 'widgets/repetibilidad_step.dart';
import 'widgets/linealidad_step.dart';
import 'widgets/condiciones_finales_step.dart';
import '../fin_servicio.dart';

class ServicioScreen extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;
  final String nReca;
  final String sessionId;

  const ServicioScreen({
    super.key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
    required this.nReca,
    required this.sessionId,
  });

  @override
  _ServicioScreenState createState() => _ServicioScreenState();
}

class _ServicioScreenState extends State<ServicioScreen> {
  late ServicioController controller;
  DateTime? _lastPressedTime;

  @override
  void initState() {
    super.initState();
    controller = ServicioController(
      dbName: widget.dbName,
      secaValue: widget.secaValue,
      codMetrica: widget.codMetrica,
      nReca: widget.nReca,
      sessionId: widget.sessionId,
    );

    // Inicializar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await controller.initializeServicio();
    } catch (e) {
      _showSnackBar('Error al inicializar: $e', isError: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null || now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar('Presione nuevamente para retroceder. Los datos registrados se perderán.');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServicioController>(
      create: (_) => controller,
      child: WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Consumer<ServicioController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  const ServicioStepIndicator(),
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

  Widget _buildCurrentStepContent(ServicioController controller) {
    switch (controller.currentStep) {
      case 0:
        return CondicionesInicialesStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
        );
      case 1:
        return PrecargasStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
        );
      case 2:
        return ExcentricidadStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
        );
      case 3:
        return RepetibilidadStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
        );
      case 4:
        return LinealidadStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
        );
      case 5:
        return CondicionesFinalesStep(
          dbName: widget.dbName,
          secaValue: widget.secaValue,
          codMetrica: widget.codMetrica,
          sessionId: widget.sessionId,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButtons(ServicioController controller) {
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
          // Botón Anterior
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

          // Botón Siguiente/Finalizar
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getNextButtonAction(controller),
              icon: Icon(_getNextButtonIcon(controller)),
              label: Text(_getNextButtonText(controller)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getNextButtonColor(controller),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction(ServicioController controller) {
    if (!controller.validateCurrentStep()) return null;

    switch (controller.currentStep) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
        return () => controller.nextStep();
      case 5:
        return () => _finalizeServicio(controller);
      default:
        return null;
    }
  }

  IconData _getNextButtonIcon(ServicioController controller) {
    switch (controller.currentStep) {
      case 5:
        return Icons.check;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextButtonText(ServicioController controller) {
    switch (controller.currentStep) {
      case 5:
        return 'Finalizar Servicio';
      default:
        return 'Siguiente';
    }
  }

  Color _getNextButtonColor(ServicioController controller) {
    switch (controller.currentStep) {
      case 5:
        return Colors.green;
      default:
        return const Color(0xFF667EEA);
    }
  }

  Future<void> _finalizeServicio(ServicioController controller) async {
    try {
      await controller.finalizeServicio();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinServicioScreen(
              secaValue: widget.secaValue,
              sessionId: widget.sessionId,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error al finalizar servicio: $e', isError: true);
    }
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