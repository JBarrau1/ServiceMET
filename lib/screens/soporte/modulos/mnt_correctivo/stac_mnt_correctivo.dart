import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';

import 'models/mnt_correctivo_model.dart';
import 'controllers/mnt_correctivo_controller.dart';
import 'widgets/paso_informacion_general.dart';
import 'widgets/paso_inspeccion_visual.dart';
import 'widgets/paso_pruebas_iniciales.dart';
import 'widgets/paso_pruebas_finales.dart';
import 'widgets/paso_comentarios_cierre.dart';

class StacMntCorrectivoScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;

  const StacMntCorrectivoScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
  });

  @override
  _StacMntCorrectivoScreenState createState() =>
      _StacMntCorrectivoScreenState();
}

class _StacMntCorrectivoScreenState extends State<StacMntCorrectivoScreen> {
  late MntCorrectivoModel _model;
  late MntCorrectivoController _controller;

  int _currentStep = 0;
  bool _isSaving = false;
  DateTime? _lastPressedTime;

  // Definición de pasos
  final List<MntCorrectivoStepData> _steps = [];

  @override
  void initState() {
    super.initState();
    _model = MntCorrectivoModel(
      sessionId: widget.sessionId,
      secaValue: widget.secaValue,
      nReca: widget.nReca,
      codMetrica: widget.codMetrica,
      userName: widget.userName,
      clienteId: widget.clienteId,
      plantaCodigo: widget.plantaCodigo,
    );
    _model.horaInicio = DateFormat('HH:mm').format(DateTime.now());

    _controller = MntCorrectivoController(model: _model);
    _controller.init();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps.addAll([
      MntCorrectivoStepData(
        title: 'Información General',
        subtitle: 'Datos iniciales del servicio',
        icon: Icons.info_outlined,
      ),
      MntCorrectivoStepData(
        title: 'Inspección Visual',
        subtitle: 'Revisión de componentes',
        icon: Icons.remove_red_eye_outlined,
      ),
      MntCorrectivoStepData(
        title: 'Pruebas Iniciales',
        subtitle: 'Excentricidad y Repetibilidad',
        icon: Icons.science_outlined,
      ),
      MntCorrectivoStepData(
        title: 'Pruebas Finales',
        subtitle: 'Verificación final',
        icon: Icons.task_alt_outlined,
      ),
      MntCorrectivoStepData(
        title: 'Comentarios y Cierre',
        subtitle: 'Conclusión del servicio',
        icon: Icons.assignment_turned_in_outlined,
      ),
    ]);
  }

  // Guardar automáticamente al cambiar de paso
  Future<void> _saveCurrentStep() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _controller.saveData(context);
      debugPrint('✅ Paso $_currentStep guardado automáticamente');
    } catch (e) {
      debugPrint('❌ Error al guardar paso $_currentStep: $e');
      _showSnackBar('Error al guardar: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Validar paso actual antes de avanzar
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Información General
        if (_model.reporteFalla.isEmpty) {
          _showSnackBar('Por favor complete el reporte de falla',
              isError: true);
          return false;
        }
        return true;

      case 1: // Inspección Visual
      case 2: // Pruebas Iniciales
      case 3: // Pruebas Finales
        return true; // Permitir continuar

      case 4: // Comentarios y Cierre
        if (_model.evaluacion.isEmpty) {
          _showSnackBar('Por favor complete la evaluación', isError: true);
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> _goToStep(int step) async {
    // Validar paso actual antes de avanzar
    if (step > _currentStep && !_validateCurrentStep()) {
      return;
    }

    // Guardar antes de cambiar de paso
    await _saveCurrentStep();

    setState(() {
      _currentStep = step;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;

      _showSnackBar(
        'Presione nuevamente para salir. Los datos se guardarán automáticamente.',
        isError: false,
      );

      // Guardar antes de salir
      await _saveCurrentStep();

      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'MANTENIMIENTO CORRECTIVO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'CÓDIGO MET: ${widget.codMetrica}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
            elevation: 0,
            flexibleSpace: isDarkMode
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(color: Colors.black.withOpacity(0.1)),
                    ),
                  )
                : null,
            centerTitle: true,
            actions: [
              // Indicador de guardado automático
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Barra de progreso mejorada
              _buildProgressBar(isDarkMode),

              // Contenido del paso actual
              Expanded(
                child: _buildStepContent(),
              ),

              // Botones de navegación
              _buildNavigationButtons(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título del paso actual
          Row(
            children: [
              Icon(
                _steps[_currentStep].icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${_currentStep + 1} de ${_steps.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      _steps[_currentStep].title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _steps[_currentStep].subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso visual
          Row(
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == _steps.length - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return PasoInformacionGeneral(
          model: _model,
          controller: _controller,
          onUpdate: () => setState(() {}),
        );
      case 1:
        return PasoInspeccionVisual(model: _model, controller: _controller);
      case 2:
        return PasoPruebasIniciales(model: _model, controller: _controller);
      case 3:
        return PasoPruebasFinales(model: _model, controller: _controller);
      case 4:
        return PasoComentariosCierre(model: _model, controller: _controller);
      default:
        return const Center(child: Text('Paso no encontrado'));
    }
  }

  Widget _buildNavigationButtons(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white,
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
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _goToStep(_currentStep - 1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANTERIOR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Botón Siguiente
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_currentStep < _steps.length - 1) {
                        await _goToStep(_currentStep + 1);
                      }
                    },
              icon: Icon(
                _currentStep < _steps.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
              ),
              label: Text(
                _currentStep < _steps.length - 1
                    ? 'SIGUIENTE'
                    : 'EN PASO FINAL',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF195375),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase auxiliar para datos de pasos
class MntCorrectivoStepData {
  final String title;
  final String subtitle;
  final IconData icon;

  MntCorrectivoStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
