import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/calibration_provider.dart';
import '../../../../database/app_database.dart';
import '../../../../provider/balanza_provider.dart';
import 'linealidad_controller.dart';
import 'linealidad_form.dart';

class LinealidadScreen extends StatefulWidget {
  final String secaValue;
  final String sessionId;
  final String codMetrica;
  final VoidCallback? onNext; // ← Agregar este parámetro

  const LinealidadScreen({
    super.key,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    this.onNext, // ← Hacerlo opcional
    // REMOVER: required Null Function() onNext, ← Este parámetro no existe
  });

  @override
  State<LinealidadScreen> createState() => _LinealidadScreenState();
}

class _LinealidadScreenState extends State<LinealidadScreen> {
  late LinealidadController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final calibrationProvider = Provider.of<CalibrationProvider>(context, listen: false);
    final balanzaProvider = Provider.of<BalanzaProvider>(context, listen: false);
    final d1 = balanzaProvider.selectedBalanza?.d1 ?? 0.1;

    _controller = LinealidadController(
      context: context,
      provider: calibrationProvider,
      codMetrica: widget.codMetrica,
      secaValue: widget.secaValue,
      sessionId: widget.sessionId,
      getD1Value: () => d1,
      onUpdate: () => setState(() {}),
    );

    // Consultar si hay datos previos
    final dbHelper = AppDatabase();
    final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

    bool useExisting = false;
    if (existingRecord != null && _hasLinealidadData(existingRecord)) {
      useExisting = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'DATOS PREVIOS ENCONTRADOS',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text("Se encontraron datos registrados anteriormente. ¿Desea continuar con ellos o empezar un nuevo registro?\n SI CAMBIO DE BALANZA, INGRESE NUEVOS, DE LO CONTRARIO VISULIZARA LOS DATOS DE LA ANTERIOR BALANZA"),
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
      ) ?? false;
    }

    if (useExisting) {
      _controller.loadFromDatabase(existingRecord!);
    } else {
      await _controller.loadLinFromPrecarga();
    }
    setState(() {
      _isInitialized = true;
    });
  }

  bool _hasLinealidadData(Map<String, dynamic> data) {
    for (int i = 1; i <= 60; i++) {
      if (data['lin$i'] != null && data['lin$i'].toString().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: LinealidadForm(controller: _controller),
    );
  }
}