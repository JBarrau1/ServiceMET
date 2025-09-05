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
  });

  @override
  _RepetibilidadScreenState createState() => _RepetibilidadScreenState();
}

class _RepetibilidadScreenState extends State<RepetibilidadScreen> {
  late RepetibilidadController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    _controller = RepetibilidadController(
      provider: provider,
      codMetrica: widget.codMetrica,
      secaValue: widget.secaValue,
      sessionId: widget.sessionId,
      context: context,
    );
    await _controller.initialize();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RepetibilidadForm(controller: _controller),
    );
  }
}
