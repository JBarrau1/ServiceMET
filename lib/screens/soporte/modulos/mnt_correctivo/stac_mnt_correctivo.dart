import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mantenimiento Correctivo'),
          backgroundColor: const Color(0xFF002A52),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Confirmación antes de salir
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Salir?'),
                  content: const Text(
                      'Si sales ahora, podrías perder los cambios no guardados.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () =>
                            Navigator.popUntil(ctx, (route) => route.isFirst),
                        child: const Text('Salir')),
                  ],
                ),
              );
            },
          ),
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  PasoInformacionGeneral(
                    model: _model,
                    controller: _controller,
                    onUpdate: () => setState(() {}), // Refrescar UI al importar
                  ),
                  PasoInspeccionVisual(model: _model, controller: _controller),
                  PasoPruebasIniciales(model: _model, controller: _controller),
                  PasoPruebasFinales(model: _model, controller: _controller),
                  PasoComentariosCierre(model: _model, controller: _controller),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: const Color(0xFF002A52),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          bool isActive = index == _currentStep;
          bool isCompleted = index < _currentStep;
          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFFDECD00)
                      : (isCompleted ? Colors.green : Colors.grey),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < _totalSteps - 1)
                Container(
                  width: 30,
                  height: 2,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002A52),
              ),
              child:
                  const Text('Anterior', style: TextStyle(color: Colors.white)),
            )
          else
            const SizedBox(),
          if (_currentStep < _totalSteps - 1)
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002A52),
              ),
              child: const Text('Siguiente',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
