// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'excentricidad_controller.dart';
import 'excentricidad_form.dart';

class ExcentricidadScreen extends StatefulWidget {
  final Map<String, dynamic> selectedBalanza;
  final String codMetrica;
  final String sessionId;
  final String secaValue;
  final VoidCallback? onNext;
  final VoidCallback? onDataSaved;

  const ExcentricidadScreen({
    super.key,
    required this.selectedBalanza,
    required this.sessionId,
    required this.codMetrica,
    required this.secaValue,
    this.onNext,
    this.onDataSaved,
  });

  @override
  _ExcentricidadScreenState createState() => _ExcentricidadScreenState();
}

class _ExcentricidadScreenState extends State<ExcentricidadScreen> {
  late ExcentricidadController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ExcentricidadController(
      codMetrica: widget.codMetrica,
      secaValue: widget.secaValue,
      sessionId: widget.sessionId,
      onUpdate: () => setState(() {}),
    );

    // Inicializar datos después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.initialize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcentricidadForm(controller: _controller);
  }
}
