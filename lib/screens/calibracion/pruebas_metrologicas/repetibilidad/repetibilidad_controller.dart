import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:service_met/provider/balanza_provider.dart';

import '../../../../database/app_database.dart';

class RepetibilidadController {
  final CalibrationProvider provider;
  final String codMetrica;
  final String secaValue;
  final BuildContext context;
  final String sessionId;

  int selectedRepetibilityCount = 3;
  int selectedRowCount = 3;

  final List<TextEditingController> cargaControllers = [];
  final List<List<TextEditingController>> indicacionControllers = [];
  final List<List<TextEditingController>> retornoControllers = [];
  final TextEditingController notaController = TextEditingController();
  final TextEditingController comentarioController = TextEditingController();
  final TextEditingController pmax1Controller = TextEditingController();
  final TextEditingController fiftyPercentPmax1Controller = TextEditingController();
  final bool loadExisting;

  double d1 = 0.1;

  RepetibilidadController({
    required this.provider,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.context,
    this.loadExisting = true,
  });

  Future<double> getD1Value() async {
    return d1;
  }


  Future<void> initialize() async {
    final balanzaProvider = Provider.of<BalanzaProvider>(context, listen: false);
    d1 = balanzaProvider.selectedBalanza?.d1 ?? 0.1;

    // Obtener pmax1 de la base de datos
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['cap_max1'] != null) {
        double pmax1 = double.tryParse(existingRecord['cap_max1'].toString()) ?? 0.0;
        double fiftyPercentPmax1 = pmax1 * 0.5;
        pmax1Controller.text = pmax1.toStringAsFixed(2);
        fiftyPercentPmax1Controller.text = fiftyPercentPmax1.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error al obtener pmax1: $e');
    }

    _initializeControllers(loadExisting);
  }

  void loadFromDatabase(Map<String, dynamic> data) {
    for (int i = 1; i <= selectedRepetibilityCount; i++) {
      if (data['repetibilidad$i'] != null && cargaControllers.length >= i) {
        cargaControllers[i - 1].text = data['repetibilidad$i'].toString();
        for (int j = 1; j <= selectedRowCount; j++) {
          if (indicacionControllers[i - 1].length >= j) {
            indicacionControllers[i - 1][j - 1].text = data['indicacion${i}_$j'].toString();
            retornoControllers[i - 1][j - 1].text =
                data['retorno${i}_$j']?.toString() ?? '0';
          }
        }
      }
    }
    notaController.text = data['repetibilidad_comentario'] ?? '';
  }

  void _initializeControllers(bool loadExisting, [VoidCallback? onUpdated]) {
    _disposeControllers();

    for (int i = 0; i < selectedRepetibilityCount; i++) {
      final cargaController = TextEditingController();
      cargaControllers.add(cargaController);
      indicacionControllers.add([]);
      retornoControllers.add([]);

      cargaController.addListener(() {
        final value = cargaController.text;
        for (var indicacion in indicacionControllers[i]) {
          if (indicacion.text.isEmpty) {
            indicacion.text = value;
          }
        }
      });

      for (int j = 0; j < selectedRowCount; j++) {
        final indicacion = TextEditingController();
        final retorno = TextEditingController(text: '0');
        indicacionControllers[i].add(indicacion);
        retornoControllers[i].add(retorno);
      }
    }

    if (loadExisting) {
      _loadExistingData();
    }

    if (onUpdated != null) {
      onUpdated();
    }
  }


  Future<void> _loadExistingData() async {
    final dbHelper = AppDatabase();
    final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);
    if (existingRecord != null) {
      for (int i = 1; i <= selectedRepetibilityCount; i++) {
        if (existingRecord['repetibilidad$i'] != null && cargaControllers.length >= i) {
          cargaControllers[i - 1].text = existingRecord['repetibilidad$i'].toString();
          for (int j = 1; j <= selectedRowCount; j++) {
            if (indicacionControllers[i - 1].length >= j) {
              indicacionControllers[i - 1][j - 1].text = existingRecord['indicacion${i}_$j'].toString();
              retornoControllers[i - 1][j - 1].text = existingRecord['retorno${i}_$j'].toString();
            }
          }
        }
      }
      notaController.text = existingRecord['repetibilidad_comentario'] ?? '';
    }
  }

  void updateRepetibilityCount(int? value, VoidCallback onUpdateUI) {
    if (value != null) {
      selectedRepetibilityCount = value;
      _initializeControllers(loadExisting);
      onUpdateUI(); // fuerza rebuild
    }
  }

  void updateRowCount(int? value, VoidCallback onUpdateUI) {
    if (value != null) {
      selectedRowCount = value;
      _initializeControllers(loadExisting);
      onUpdateUI(); // fuerza rebuild
    }
  }

  Future<void> saveDataToDatabase() async {
    final Map<String, dynamic> registro = {};
    for (int i = 0; i < selectedRepetibilityCount; i++) {
      registro['repetibilidad${i + 1}'] = cargaControllers[i].text;
      for (int j = 0; j < selectedRowCount; j++) {
        registro['indicacion${i + 1}_${j + 1}'] = indicacionControllers[i][j].text;
        registro['retorno${i + 1}_${j + 1}'] = retornoControllers[i][j].text;
      }
    }
    registro['repetibilidad_comentario'] = notaController.text;
    registro['seca'] = secaValue;
    registro['session_id'] = sessionId;

    final dbHelper = AppDatabase();
    final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);
    if (existingRecord != null) {
      await dbHelper.upsertRegistroCalibracion(registro);
    } else {
      await dbHelper.insertRegistroCalibracion(registro);
    }
  }

  void _disposeControllers() {
    for (var c in cargaControllers) {
      c.dispose();
    }
    for (var list in indicacionControllers) {
      for (var c in list) {
        c.dispose();
      }
    }
    for (var list in retornoControllers) {
      for (var c in list) {
        c.dispose();
      }
    }
    cargaControllers.clear();
    indicacionControllers.clear();
    retornoControllers.clear();
  }

  void dispose() {
    _disposeControllers();
    notaController.dispose();
    comentarioController.dispose();
    pmax1Controller.dispose(); // ← Nuevo
    fiftyPercentPmax1Controller.dispose(); // ← Nuevo
  }

  void clearAllFields() {
    for (var c in cargaControllers) c.clear();
    for (var list in indicacionControllers) {
      for (var c in list) c.clear();
    }
    for (var list in retornoControllers) {
      for (var c in list) c.clear();
    }
    notaController.clear();
    comentarioController.clear();
  }

}
