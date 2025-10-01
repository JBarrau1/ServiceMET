import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../database/app_database.dart';
import '../../../../models/balanza_model.dart';
import '../../../../provider/balanza_provider.dart';

class ExcentricidadController {
  final TextEditingController pmax1Controller = TextEditingController();
  final TextEditingController oneThirdPmax1Controller = TextEditingController();

  DateTime? _lastPressedTime;
  final CalibrationProvider provider;
  final String codMetrica;
  final String secaValue;
  final String sessionId;

  final Map<String, List<String>> platformOptions = {
    'Rectangular': [
      'Rectangular 3D',
      'Rectangular 3I',
      'Rectangular 3F',
      'Rectangular 3A',
      'Rectangular 5D',
      'Rectangular 5I',
      'Rectangular 5F',
      'Rectangular 5A'
    ],
    'Circular': [
      'Circular 5D',
      'Circular 5I',
      'Circular 5F',
      'Circular 5A',
      'Circular 4D',
      'Circular 4I',
      'Circular 4F',
      'Circular 4A'
    ],
    'Cuadrada': ['Cuadrada D', 'Cuadrada I', 'Cuadrada F', 'Cuadrada A'],
    'Triangular': [
      'Triangular I',
      'Triangular F',
      'Triangular A',
      'Triangular D'
    ],
  };

  final Map<String, String> optionImages = {
    'Rectangular 3D': 'images/Rectangular_3D.png',
    'Rectangular 3I': 'images/Rectangular_3I.png',
    'Rectangular 3F': 'images/Rectangular_3F.png',
    'Rectangular 3A': 'images/Rectangular_3A.png',
    'Rectangular 5D': 'images/Rectangular_5D.png',
    'Rectangular 5I': 'images/Rectangular_5I.png',
    'Rectangular 5F': 'images/Rectangular_5F.png',
    'Rectangular 5A': 'images/Rectangular_5A.png',
    'Circular 5D': 'images/Circular_5D.png',
    'Circular 5I': 'images/Circular_5I.png',
    'Circular 5F': 'images/Circular_5F.png',
    'Circular 5A': 'images/Circular_5A.png',
    'Circular 4D': 'images/Circular_4D.png',
    'Circular 4I': 'images/Circular_4I.png',
    'Circular 4F': 'images/Circular_4F.png',
    'Circular 4A': 'images/Circular_4A.png',
    'Cuadrada D': 'images/Cuadrada_D.png',
    'Cuadrada I': 'images/Cuadrada_I.png',
    'Cuadrada F': 'images/Cuadrada_F.png',
    'Cuadrada A': 'images/Cuadrada_A.png',
    'Triangular I': 'images/Triangular_I.png',
    'Triangular F': 'images/Triangular_F.png',
    'Triangular A': 'images/Triangular_A.png',
    'Triangular D': 'images/Triangular_D.png',
  };

  String? selectedPlatform;
  String? selectedOption;
  List<TextEditingController> positionControllers = [];
  List<TextEditingController> indicationControllers = [];
  List<TextEditingController> returnControllers = [];
  final TextEditingController cargaController = TextEditingController();
  final TextEditingController notaController = TextEditingController();
  final TextEditingController masaController = TextEditingController();
  final List<TextEditingController> _indicationControllers = [];
  final VoidCallback? onUpdate;

  ExcentricidadController({
    required this.provider,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    this.onUpdate,
  }) {
    _setupCargaListener();
  }

  void loadFromDatabase(Map<String, dynamic> data) {
    selectedPlatform = data['tipo_plataforma'];
    selectedOption = data['puntos_ind'];
    cargaController.text = data['carga']?.toString() ?? '';

    updatePositionsFromOption();

    for (int i = 0; i < positionControllers.length; i++) {
      positionControllers[i].text = data['posicion${i + 1}']?.toString() ?? '';
      indicationControllers[i].text = data['indicacion${i + 1}']?.toString() ?? '';
      returnControllers[i].text = data['retorno${i + 1}']?.toString() ?? '0';
    }

    notaController.text = data['observaciones']?.toString() ?? '';
  }

  void clearData() {
    selectedPlatform = null;
    selectedOption = null;
    cargaController.clear();
    notaController.clear();
    positionControllers.clear();
    indicationControllers.clear();
    returnControllers.clear();
  }

  void autoFillIndicationsFromMasa() {
    final value = masaController.text;
    for (final controller in _indicationControllers) {
      controller.text = value;
    }
  }

  void _setupCargaListener() {
    cargaController.addListener(() {
      final value = cargaController.text;
      final numValue = double.tryParse(value);

      if (numValue != null) {
        for (final controller in indicationControllers) {
          controller.text = value;
        }
        onUpdate?.call(); // fuerza la reconstrucción si es necesario
      }
    });
  }

  Future<void> initialize() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['cap_max1'] != null) {
        double pmax1 = double.tryParse(existingRecord['cap_max1'].toString()) ?? 0.0;
        double oneThirdPmax1 = pmax1 / 3;
        pmax1Controller.text = pmax1.toStringAsFixed(2);
        oneThirdPmax1Controller.text = oneThirdPmax1.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error al obtener pmax1: $e');
    }

    _loadInitialData();
    _loadTempData();
    _setupTempListeners();
  }

  Future<void> fetchPmax1FromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['cap_max1'] != null) {
        double pmax1 = double.tryParse(existingRecord['cap_max1'].toString()) ?? 0.0;
        double oneThirdPmax1 = pmax1 / 3;
        pmax1Controller.text = pmax1.toStringAsFixed(2);
        oneThirdPmax1Controller.text = oneThirdPmax1.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error al obtener pmax1: $e');
    }
  }

  Future<bool> onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presione nuevamente para retroceder')));
      return false;
    }
    return true;
  }

  void _setupTempListeners() {
    cargaController.addListener(_saveTempData);
    for (final c in [...indicationControllers, ...returnControllers]) {
      c.addListener(_saveTempData);
    }
  }

  void _saveTempData() {
    provider.updateTempDataForTest('excentricidad', {
      'carga': cargaController.text,
      'indicaciones': indicationControllers.map((c) => c.text).toList(),
      'retornos': returnControllers.map((c) => c.text).toList(),
    });
  }

  void _loadTempData() {
    final saved = provider.getTempDataForTest('excentricidad');
    if (saved != null) {
      cargaController.text = saved['carga'] ?? '';
      final indicaciones = List<String>.from(saved['indicaciones'] ?? []);
      final retornos = List<String>.from(saved['retornos'] ?? []);

      for (int i = 0; i < indicationControllers.length; i++) {
        if (i < indicaciones.length) {
          indicationControllers[i].text = indicaciones[i];
        }
      }

      for (int i = 0; i < returnControllers.length; i++) {
        if (i < retornos.length) {
          returnControllers[i].text = retornos[i];
        }
      }
    }
  }

  void _loadInitialData() {
    if (provider.currentData != null) {
      final data = provider.currentData!.balanzaData;
      selectedPlatform = data['tipo_plataforma'];
      updatePositionsFromOption();
      selectedOption = data['puntos_ind'];
      cargaController.text = data['carga']?.toString() ?? '';

      // Cargar datos de posición si existen
      for (int i = 1; i <= 6; i++) {
        if (data['posicion$i'] != null) {
          if (positionControllers.length < i) {
            positionControllers.add(TextEditingController());
            indicationControllers.add(TextEditingController());
            returnControllers.add(TextEditingController(text: '0'));
          }
          positionControllers[i - 1].text =
              data['posicion$i']?.toString() ?? '';
          indicationControllers[i - 1].text =
              data['indicacion$i']?.toString() ?? '';
          returnControllers[i - 1].text = data['retorno$i']?.toString() ?? '0';
        }
      }
    }
  }

  Future<double> getDForCarga(double carga) async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord == null) {
        return 0.1; // Valor por defecto si no existe registro
      }

      // Obtener valores de la base de datos
      final pmax1 = double.tryParse(existingRecord['cap_max1']?.toString() ?? '0') ?? 0.0;
      final pmax2 = double.tryParse(existingRecord['cap_max2']?.toString() ?? '0') ?? 0.0;
      final pmax3 = double.tryParse(existingRecord['cap_max3']?.toString() ?? '0') ?? 0.0;

      final d1 = double.tryParse(existingRecord['d1']?.toString() ?? '0.1') ?? 0.1;
      final d2 = double.tryParse(existingRecord['d2']?.toString() ?? '0.1') ?? 0.1;
      final d3 = double.tryParse(existingRecord['d3']?.toString() ?? '0.1') ?? 0.1;

      // Lógica de selección según la carga
      if (carga <= pmax1) return d1;
      if (carga <= pmax2) return d2;
      if (carga <= pmax3) return d3;
      return d3; // fallback
    } catch (e) {
      debugPrint('Error al obtener D de la base de datos: $e');
      return 0.1; // Valor por defecto en caso de error
    }
  }

  Future<Map<String, double>> getDValues() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord == null) {
        return {'d1': 0.1, 'd2': 0.1, 'd3': 0.1};
      }

      return {
        'd1': double.tryParse(existingRecord['d1']?.toString() ?? '0.1') ?? 0.1,
        'd2': double.tryParse(existingRecord['d2']?.toString() ?? '0.1') ?? 0.1,
        'd3': double.tryParse(existingRecord['d3']?.toString() ?? '0.1') ?? 0.1,
        'pmax1': double.tryParse(existingRecord['cap_max1']?.toString() ?? '0') ?? 0.0,
        'pmax2': double.tryParse(existingRecord['cap_max2']?.toString() ?? '0') ?? 0.0,
        'pmax3': double.tryParse(existingRecord['cap_max3']?.toString() ?? '0') ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error al obtener valores D de la BD: $e');
      return {'d1': 0.1, 'd2': 0.1, 'd3': 0.1};
    }
  }

  void updatePlatform(String? platform) {
    selectedPlatform = platform;

    if (platform != null &&
        platformOptions.containsKey(platform) &&
        platformOptions[platform]!.isNotEmpty) {
      selectedOption = platformOptions[platform]!.first;
    } else {
      selectedOption = null;
    }

    updatePositionsFromOption();
  }

  int _getPositionCountForOption(String option) {
    if (option.contains('3')) return 3;
    if (option.contains('4')) return 4;
    if (option.contains('5')) return 5;
    if (option.startsWith('Cuadrada')) return 5;
    if (option.startsWith('Triangular')) return 4;
    return 0;
  }

  void updatePositionsFromOption() {
    final option = selectedOption ?? '';
    final positionCount = _getPositionCountForOption(option);

    positionControllers = List.generate(
        positionCount, (i) => TextEditingController(text: '${i + 1}'));
    indicationControllers =
        List.generate(positionCount, (_) => TextEditingController());
    returnControllers =
        List.generate(positionCount, (_) => TextEditingController(text: '0'));
  }

  Future<void> saveDataToDatabase(BuildContext context) async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      final Map<String, dynamic> registro = {
        'session_id': sessionId,
        'seca': secaValue,
        'tipo_plataforma': selectedPlatform ?? 'No especificado',
        'puntos_ind': selectedOption ?? 'No especificado',
        'carga': cargaController.text.trim().isNotEmpty
            ? cargaController.text.trim()
            : '0',
        'observaciones': notaController.text.trim(),
      };

      for (int i = 0; i < positionControllers.length; i++) {
        registro['posicion${i + 1}'] = positionControllers[i].text.trim().isNotEmpty
            ? positionControllers[i].text.trim()
            : '0';
        registro['indicacion${i + 1}'] = indicationControllers[i].text.trim().isNotEmpty
            ? indicationControllers[i].text.trim()
            : '0';
        registro['retorno${i + 1}'] = returnControllers[i].text.trim().isNotEmpty
            ? returnControllers[i].text.trim()
            : '0';
      }

      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Datos guardados correctamente"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar los datos: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error al guardar excentricidad: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }


  void dispose() {
    pmax1Controller.dispose();
    oneThirdPmax1Controller.dispose();
    cargaController.dispose();
    notaController.dispose();
    for (var c in [
      ...positionControllers,
      ...indicationControllers,
      ...returnControllers
    ]) {
      c.dispose();
    }
  }
}
