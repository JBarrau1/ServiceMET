import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Modelos y Controladores propios
import 'models/verificaciones_internas_model.dart';
import 'controllers/verificaciones_internas_controller.dart';

// Widgets de pasos
import 'widgets/steps/paso_pruebas_iniciales.dart';
import 'widgets/steps/paso_reporte_evaluacion.dart';
import 'widgets/steps/paso_comentarios.dart';
import 'widgets/steps/paso_pruebas_finales.dart';
import 'widgets/steps/paso_estado_final.dart';

// Pantalla final
import 'fin_servicio_vinternas.dart';

class StacVerificacionesInternasScreen extends StatefulWidget {
  final String otst;
  final String codMetrica;
  final String sessionId;
  final String nReca;
  final String userName;
  final int clienteId;
  final String plantaCodigo;

  const StacVerificacionesInternasScreen({
    super.key,
    required this.otst,
    required this.codMetrica,
    required this.sessionId,
    required this.nReca,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
  });

  @override
  State<StacVerificacionesInternasScreen> createState() =>
      _StacVerificacionesInternasScreenState();
}

class _StacVerificacionesInternasScreenState
    extends State<StacVerificacionesInternasScreen> {
  late VerificacionesInternasModel _model;
  late VerificacionesInternasController _controller;
  int _currentStep = 0;
  bool _isSaving = false;
  DateTime? _lastPressedTime;

  final List<StepData> _steps = [
    StepData(
      title: 'Pruebas Iniciales',
      subtitle: 'Excentricidad, Repetibilidad, Linealidad',
      icon: Icons.science_outlined,
    ),
    StepData(
      title: 'Reporte y Evaluación',
      subtitle: 'Descripción del trabajo y estados',
      icon: Icons.article_outlined,
    ),
    StepData(
      title: 'Comentarios',
      subtitle: 'Observaciones y fotos',
      icon: Icons.comment_outlined,
    ),
    StepData(
      title: 'Pruebas Finales',
      subtitle: 'Verificación post-mantenimiento',
      icon: Icons.task_alt_outlined,
    ),
    StepData(
      title: 'Finalizar',
      subtitle: 'Resumen y cierre de servicio',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _controller = VerificacionesInternasController(model: _model);
    _actualizarHora();
  }

  void _initializeModel() {
    _model = VerificacionesInternasModel(
      codMetrica: widget.codMetrica,
      sessionId: widget.sessionId,
      secaValue: widget.otst,
      horaInicio: DateFormat('HH:mm').format(DateTime.now()),
    );
  }

  void _actualizarHora() {
    if (mounted) {
      setState(() {
        _model.horaFin = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  Future<void> _saveCurrentStep() async {
    setState(() {
      _isSaving = true;
    });

    try {
      _actualizarHora();
      await _controller.saveDataToDatabase(context, showMessage: false);
    } catch (e) {
      debugPrint('Error saving step: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _validateCurrentStep() {
    // Implementar validaciones específicas si es necesario
    return true;
  }

  Future<void> _goToStep(int step) async {
    if (step > _currentStep && !_validateCurrentStep()) {
      return;
    }

    await _saveCurrentStep();

    setState(() {
      _currentStep = step;
    });

    // Si llegamos al paso final, asegurar actualizar hora fin
    if (step == _steps.length - 1) {
      _actualizarHora();
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Presione nuevamente para salir. Los datos se guardarán automáticamente.'),
          duration: Duration(seconds: 2),
        ),
      );
      await _saveCurrentStep();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'VERIFICACIONES INTERNAS',
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
            _buildProgressBar(isDarkMode),
            Expanded(
              child: _buildStepContent(),
            ),
            _buildNavigationButtons(isDarkMode),
          ],
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
        return PasoPruebasIniciales(
          model: _model,
          controller: _controller,
          getIndicationSuggestions: _controller.getIndicationSuggestions,
          getD1FromDatabase: _controller.getD1FromDatabase,
          onChanged: () => setState(() {}),
        );
      case 1:
        return PasoReporteEvaluacion(
          model: _model,
          onChanged: () => setState(() {}),
        );
      case 2:
        return PasoComentarios(
          model: _model,
          onChanged: () => setState(() {}),
        );
      case 3:
        return PasoPruebasFinales(
          model: _model,
          controller: _controller,
          getIndicationSuggestions: _controller.getIndicationSuggestions,
          getD1FromDatabase: _controller.getD1FromDatabase,
          onChanged: () => setState(() {}),
        );
      case 4:
        return PasoEstadoFinal(
          model: _model,
          controller: _controller,
        );
      default:
        return const Center(child: Text('Paso no encontrado'));
    }
  }

  Widget _buildNavigationButtons(bool isDarkMode) {
    bool isLastStep = _currentStep == _steps.length - 1;

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
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_currentStep < _steps.length - 1) {
                        await _goToStep(_currentStep + 1);
                      } else {
                        // Último paso: finalizar
                        await _saveCurrentStep();
                        if (!mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FinServicioVinternasScreen(
                              sessionId: widget.sessionId,
                              secaValue: widget.otst,
                              codMetrica: widget.codMetrica,
                              nReca: widget.nReca,
                              userName: widget.userName,
                              clienteId: widget.clienteId.toString(),
                              plantaCodigo: widget.plantaCodigo,
                              tableName: 'verificaciones_internas',
                            ),
                          ),
                        );
                      }
                    },
              icon: Icon(
                isLastStep ? Icons.check_circle : Icons.arrow_forward,
              ),
              label: Text(
                isLastStep ? 'FINALIZAR' : 'SIGUIENTE',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep
                    ? const Color(0xFF167D1D)
                    : const Color(0xFF195375),
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

class StepData {
  final String title;
  final String subtitle;
  final IconData icon;

  StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
