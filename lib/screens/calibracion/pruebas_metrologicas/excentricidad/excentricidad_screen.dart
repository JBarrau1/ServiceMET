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

      if (existingRecord != null) {
        final continuar = await _showContinueDialog(context);
        if (continuar == true) {

          _controller.loadFromDatabase(existingRecord);
        } else {

          _controller.clearData();
        }
        setState(() {});
      }
    });

    _controller.masaController.addListener(() {
      _controller.autoFillIndicationsFromMasa();
    });
  }

  Future<bool?> _showContinueDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "DATOS PREVIOS ENCONTRADOS",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
              "Se encontraron datos registrados anteriormente. ¿Desea continuar con ellos o empezar un nuevo registro?\n SI CAMBIO DE BALANZA, INGRESE NUEVOS, DE LO CONTRARIO VISULIZARA LOS DATOS DE LA ANTERIOR BALANZA"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Ingresar nuevos"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Usar últimos"),
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExcentricidadForm(controller: _controller),
    );
  }
}
