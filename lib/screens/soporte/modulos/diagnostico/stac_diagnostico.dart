import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/diagnostico_model.dart';
import 'controllers/diagnostico_controller.dart';
import 'widgets/paso_informacion_general.dart';
import 'widgets/paso_pruebas_iniciales.dart';
import 'widgets/paso_comentarios_cierre.dart';

class StacDiagnosticoScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;

  const StacDiagnosticoScreen({
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
  State<StacDiagnosticoScreen> createState() => _StacDiagnosticoScreenState();
}

class _StacDiagnosticoScreenState extends State<StacDiagnosticoScreen> {
  late DiagnosticoModel _model;
  late DiagnosticoController _controller;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _controller = DiagnosticoController(model: _model);
    _controller.init();
    _actualizarHoraInicio();
  }

  void _initializeModel() {
    _model = DiagnosticoModel(
      sessionId: widget.sessionId,
      secaValue: widget.secaValue,
      nReca: widget.nReca,
      codMetrica: widget.codMetrica,
      userName: widget.userName,
      clienteId: widget.clienteId,
      plantaCodigo: widget.plantaCodigo,
    );
  }

  void _actualizarHoraInicio() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _model.horaInicio = horaFormateada;
    // Forzar rebuild si es necesario para mostrar hora en UI, aunque el paso 1 lo lee del modelo
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('SOPORTE TÉCNICO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('DIAGNÓSTICO - ${widget.codMetrica}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Indicador de Pasos
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Navegación controlada por botones
              children: [
                PasoInformacionGeneral(model: _model),
                PasoPruebasIniciales(model: _model, controller: _controller),
                PasoComentariosCierre(model: _model, controller: _controller),
              ],
            ),
          ),
          // Botones de Navegación Globales (excepto en el último paso que tiene su propia lógica)
          if (_currentStep < 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('ANTERIOR'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: const Text('SIGUIENTE'),
                    ),
                  ),
                ],
              ),
            ),
          // Botón 'Anterior' para el último paso (ya que los botones de guardar estan dentro del widget)
          if (_currentStep == 2)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('ANTERIOR'),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, '1', 'General'),
          _buildLine(0),
          _buildStepCircle(1, '2', 'Pruebas'),
          _buildLine(1),
          _buildStepCircle(2, '3', 'Cierre'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, String title) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;
    Color color =
        isActive ? Colors.orange : (isCompleted ? Colors.green : Colors.grey);

    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
      ],
    );
  }

  Widget _buildLine(int index) {
    return Container(
      width: 40,
      height: 2,
      color: _currentStep > index ? Colors.green : Colors.grey[300],
      margin: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 15), // Ajustado para alinear con círculos
    );
  }
}
