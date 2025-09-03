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

    final dbHelper = AppDatabase();
    final existingRecord =
    await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

    bool useExisting = false;

    if (existingRecord != null) {
      useExisting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'DATOS PREVIOS ENCONTRADOS',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
              "Se encontraron datos registrados anteriormente. ¿Desea continuar con ellos o empezar un nuevo registro?\n SI CAMBIO DE BALANZA, INGRESE NUEVOS, DE LO CONTRARIO VISULIZARA LOS DATOS DE LA ANTERIOR BALANZA"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ingresar nuevos'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Usar últimos'),
            ),
          ],
        ),
      ) ??
          false;
    }

    if (useExisting && existingRecord != null) {
      // cargar datos previos
      _controller.loadFromDatabase(existingRecord);
    } else {
      // iniciar limpio
      await _controller.initialize();
      _controller.clearAllFields();
    }


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
