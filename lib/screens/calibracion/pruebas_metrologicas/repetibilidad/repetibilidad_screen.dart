import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_controller.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_form.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/calibration_provider.dart';

class RepetibilidadScreen extends StatefulWidget {
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final VoidCallback? onNext;

  const RepetibilidadScreen({
    super.key,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    this.onNext,
    required void Function() onDataSaved,
  });

  @override
  _RepetibilidadScreenState createState() => _RepetibilidadScreenState();
}

class _RepetibilidadScreenState extends State<RepetibilidadScreen> {
  late RepetibilidadController _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final provider = Provider.of<CalibrationProvider>(context, listen: false);
      _controller = RepetibilidadController(
        provider: provider,
        codMetrica: widget.codMetrica,
        secaValue: widget.secaValue,
        sessionId: widget.sessionId,
        context: context,
      );

      // ✅ CRÍTICO: Esperar a que initialize() complete ANTES de marcar como initialized
      await _controller.initialize();

      // ✅ Verificar que los controladores se hayan creado correctamente
      if (_controller.cargaControllers.isEmpty) {
        throw Exception('Los controladores no se inicializaron correctamente');
      }

      debugPrint('✅ Controller inicializado: ${_controller.cargaControllers.length} cargas');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar controller: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isInitialized = true; // Marcar como initialized para mostrar el error
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos de repetibilidad...'),
          ],
        ),
      );
    }

    // ✅ Mostrar error si hubo problemas
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar los datos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _errorMessage = null;
                  });
                  _initializeController();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Verificación adicional antes de renderizar el form
    if (_controller.cargaControllers.isEmpty) {
      return const Center(
        child: Text('No se pudieron inicializar los controladores'),
      );
    }

    return RepetibilidadForm(controller: _controller);
  }
}