// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/fin_servicio.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/widgets/steps/paso_entorno.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/widgets/steps/paso_estado_final.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/widgets/steps/paso_pruebas_finales.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/widgets/steps/paso_terminal_plataforma_celdas.dart';
import 'controllers/relevamiento_de_datos_controller.dart';
import 'models/relevamiento_de_datos_model.dart';
import 'utils/modelo_helper.dart';

class RelevamientoDeDatosScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;

  const RelevamientoDeDatosScreen({
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
  _RelevamientoDeDatosScreenState createState() =>
      _RelevamientoDeDatosScreenState();
}

class _RelevamientoDeDatosScreenState extends State<RelevamientoDeDatosScreen> {
  late RelevamientoDeDatosModel _model;
  late RelevamientoDeDatosController _controller;

  int _currentStep = 0;
  bool _isSaving = false;
  DateTime? _lastPressedTime;
  double? _cachedD1;

  // Definición de pasos (4 pasos en total)
  final List<RelevamientoStepData> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _controller = RelevamientoDeDatosController(model: _model);
    _actualizarHora();
    _loadD1Value();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps.addAll([
      RelevamientoStepData(
        title: 'Entorno',
        subtitle: 'Condiciones de instalación',
        icon: Icons.domain_outlined,
      ),
      RelevamientoStepData(
        title: 'Inspección',
        subtitle: 'Terminal, Plataforma, Celdas',
        icon: Icons.checklist_outlined,
      ),
      RelevamientoStepData(
        title: 'Pruebas Finales',
        subtitle: 'Pruebas metrológicas',
        icon: Icons.task_alt_outlined,
      ),
      RelevamientoStepData(
        title: 'Estado Final',
        subtitle: 'Conclusión del servicio',
        icon: Icons.assignment_turned_in_outlined,
      ),
    ]);
  }

  void _initializeModel() {
    _model = ModeloHelper.inicializarModelo(
      codMetrica: widget.codMetrica,
      sessionId: widget.sessionId,
      secaValue: widget.secaValue,
    );
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    _model.horaInicio = DateFormat('HH:mm:ss').format(ahora);
  }

  Future<void> _loadD1Value() async {
    _cachedD1 = await _controller.getD1FromDatabase();
    setState(() {});
  }

  Future<double> _getD1FromDatabase() async {
    return _cachedD1 ?? 0.1;
  }

  void _onModelChanged() {
    setState(() {});
  }

  Future<void> _saveCurrentStep() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _controller.saveDataToDatabase(context, showMessage: false);
    } catch (e) {
      debugPrint('Error al guardar paso $_currentStep: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validateCurrentStep() {
    // Validación básica por paso
    switch (_currentStep) {
      case 0: // Entorno
        return true; // Los campos de entorno siempre tienen valor por defecto
      case 1: // Inspección
        return true; // Campos opcionales
      case 2: // Pruebas Finales
        return true; // Pruebas opcionales
      case 3: // Estado Final
        // Validar campos obligatorios
        if (_model.comentarioGeneral.isEmpty) {
          _showSnackBar('Por favor complete el comentario general');
          return false;
        }
        if (_model.recomendacion.isEmpty) {
          _showSnackBar('Por favor seleccione una recomendación');
          return false;
        }
        if (_model.fechaProxServicio.isEmpty) {
          _showSnackBar('Por favor seleccione la fecha del próximo servicio');
          return false;
        }
        if (_model.estadoFisico.isEmpty ||
            _model.estadoOperacional.isEmpty ||
            _model.estadoMetrologico.isEmpty) {
          _showSnackBar('Por favor complete todos los estados finales');
          return false;
        }
        if (_model.horaFin.isEmpty) {
          _showSnackBar('Por favor registre la hora final del servicio');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    await _saveCurrentStep();

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _previousStep() async {
    await _saveCurrentStep();

    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finalizarServicio() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSaving = true);

    try {
      await _controller.saveData(context);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinServicioScreen(
              sessionId: widget.sessionId,
              secaValue: widget.secaValue,
              nReca: widget.nReca,
              codMetrica: widget.codMetrica,
              userName: widget.userName,
              clienteId: widget.clienteId,
              plantaCodigo: widget.plantaCodigo,
              tableName: 'relevamiento_de_datos',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al finalizar el servicio: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastPressedTime == null ||
            now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
          _lastPressedTime = now;
          _showSnackBar('Presione nuevamente para salir sin guardar');
          return;
        }

        await _saveCurrentStep();
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'RELEVAMIENTO DE DATOS',
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
            // Barra de progreso
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
        return PasoEntorno(
          model: _model,
          controller: _controller,
          onChanged: _onModelChanged,
        );
      case 1:
        return PasoTerminalPlataformaCeldas(
          model: _model,
          controller: _controller,
          onChanged: _onModelChanged,
        );
      case 2:
        return PasoPruebasFinales(
          model: _model,
          controller: _controller,
          getD1FromDatabase: _getD1FromDatabase,
          onChanged: _onModelChanged,
        );
      case 3:
        return PasoEstadoFinal(
          model: _model,
          onChanged: _onModelChanged,
        );
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
                onPressed: _isSaving ? null : _previousStep,
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

          // Botón Siguiente o Finalizar
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : (_currentStep < _steps.length - 1
                      ? _nextStep
                      : _finalizarServicio),
              icon: Icon(
                _currentStep < _steps.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
              ),
              label: Text(
                _currentStep < _steps.length - 1 ? 'SIGUIENTE' : 'FINALIZAR',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < _steps.length - 1
                    ? const Color(0xFF195375)
                    : const Color(0xFF167D1D),
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

class RelevamientoStepData {
  final String title;
  final String subtitle;
  final IconData icon;

  RelevamientoStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
