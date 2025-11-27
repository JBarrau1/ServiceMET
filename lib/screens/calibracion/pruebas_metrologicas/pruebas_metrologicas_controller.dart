import 'package:flutter/material.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/excentricidad_controller.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/linealidad/linealidad_controller.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:provider/provider.dart';

class PruebasMetrologicasController extends ChangeNotifier {
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final BuildContext context;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  late ExcentricidadController excentricidadController;
  late RepetibilidadController repetibilidadController;
  late LinealidadController linealidadController;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  PruebasMetrologicasController({
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.context,
  }) {
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    _isLoading = true;
    notifyListeners();

    // Initialize ExcentricidadController
    excentricidadController = ExcentricidadController(
      codMetrica: codMetrica,
      secaValue: secaValue,
      sessionId: sessionId,
      onUpdate: notifyListeners,
    );
    await excentricidadController.initialize();

    // Initialize RepetibilidadController
    final calibrationProvider =
        Provider.of<CalibrationProvider>(context, listen: false);
    repetibilidadController = RepetibilidadController(
      provider: calibrationProvider,
      codMetrica: codMetrica,
      secaValue: secaValue,
      sessionId: sessionId,
      context: context,
      onUpdate: notifyListeners,
    );
    // Note: RepetibilidadController might need a way to notify listeners if it doesn't accept a callback.
    // Assuming it works similarly or we might need to modify it.
    await repetibilidadController.initialize();

    // Initialize LinealidadController
    linealidadController = LinealidadController(
      context: context,
      provider: calibrationProvider,
      codMetrica: codMetrica,
      secaValue: secaValue,
      sessionId: sessionId,
      onUpdate: notifyListeners,
    );
    // Linealidad initialization logic (loading from DB etc) might need to be called here or handled within its constructor/init.
    // Based on LinealidadScreen, it has logic to ask user about existing data.
    // For now, we'll assume standard loading or we might need to replicate that logic here.
    // We'll call a load method if available.
    await linealidadController
        .loadLinFromPrecargaOrDatabase(); // Assuming this method exists and is public

    _isLoading = false;
    notifyListeners();
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    excentricidadController.dispose();
    repetibilidadController.dispose();
    linealidadController.dispose();
    super.dispose();
  }
}
