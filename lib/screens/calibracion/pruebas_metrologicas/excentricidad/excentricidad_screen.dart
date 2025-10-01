import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/calibration_provider.dart';
import '../../../../database/app_database.dart';
import 'excentricidad_controller.dart';
import 'excentricidad_form.dart';

class ExcentricidadScreen extends StatefulWidget {
  final Map<String, dynamic> selectedBalanza;
  final String codMetrica;
  final String sessionId;
  final String secaValue;
  final VoidCallback? onNext;

  const ExcentricidadScreen({
    super.key,
    required this.selectedBalanza,
    required this.sessionId,
    required this.codMetrica,
    required this.secaValue,
    this.onNext,
    required void Function() onDataSaved,
  });

  @override
  _ExcentricidadScreenState createState() => _ExcentricidadScreenState();
}

class _ExcentricidadScreenState extends State<ExcentricidadScreen> {
  late ExcentricidadController _controller;


  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    _controller = ExcentricidadController(
      provider: provider,
      codMetrica: widget.codMetrica,
      secaValue: widget.secaValue,
      sessionId: widget.sessionId,
      onUpdate: () => setState(() {}),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.initialize();

      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);


    });

    _controller.masaController.addListener(() {
      _controller.autoFillIndicationsFromMasa();
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Elimina el Scaffold, solo devuelve el contenido
    return ExcentricidadForm(controller: _controller);
  }
}
