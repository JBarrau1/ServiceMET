import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../database/app_database.dart';

class ExcentricidadController {
  final TextEditingController pmax1Controller = TextEditingController();
  final TextEditingController oneThirdPmax1Controller = TextEditingController();

  DateTime? _lastPressedTime;
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
  final VoidCallback? onUpdate;

  ExcentricidadController({
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    this.onUpdate,
  }) {
    _setupCargaListener();
  }

  // Método para obtener la ruta de precarga_database
  Future<String> _getPrecargaDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'precarga_database.db');
  }

  // Cargar valor de "Carga" desde precarga_database (columna exc)
  Future<void> _loadCargaFromPrecarga() async {
    try {
      final dbPath = await _getPrecargaDatabasePath();
      final db = await openDatabase(dbPath, readOnly: true);

      final result = await db.query(
        'servicios',
        columns: ['exc'],
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
        orderBy: 'reg_fecha DESC',
        limit: 1,
      );

      await db.close();

      if (result.isNotEmpty) {
        final excValue = result.first['exc'];
        if (excValue != null && excValue.toString().trim().isNotEmpty) {
          cargaController.text = excValue.toString();
          debugPrint('Carga cargada desde precarga_database: $excValue');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar carga desde precarga_database: $e');
    }
  }

  void _setupCargaListener() {
    cargaController.addListener(() {
      final value = cargaController.text;
      if (value.isNotEmpty) {
        for (final controller in indicationControllers) {
          controller.text = value;
        }
        onUpdate?.call();
      }
    });
  }

  Future<void> initialize() async {
    try {
      final dbHelper = AppDatabase();

      // Cargar pmax1 y 1/3 pmax1
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['cap_max1'] != null) {
        double pmax1 = double.tryParse(existingRecord['cap_max1'].toString()) ?? 0.0;
        double oneThirdPmax1 = pmax1 / 3;
        pmax1Controller.text = pmax1.toStringAsFixed(2);
        oneThirdPmax1Controller.text = oneThirdPmax1.toStringAsFixed(2);
      }

      // Intentar cargar datos existentes de AppDatabase primero
      if (existingRecord != null && _hasExcentricidadData(existingRecord)) {
        loadFromDatabase(existingRecord);
        debugPrint('Datos de excentricidad cargados desde AppDatabase');
      } else {
        // Si no hay datos guardados, intentar cargar Carga desde precarga
        await _loadCargaFromPrecarga();
        debugPrint('No hay datos previos de excentricidad, Carga cargada desde precarga');
      }
    } catch (e) {
      debugPrint('Error al inicializar excentricidad: $e');
    }

    onUpdate?.call();
  }

  // Verificar si existen datos de excentricidad guardados
  bool _hasExcentricidadData(Map<String, dynamic> data) {
    return (data['tipo_plataforma'] != null && data['tipo_plataforma'].toString().isNotEmpty) ||
        (data['puntos_ind'] != null && data['puntos_ind'].toString().isNotEmpty) ||
        (data['carga'] != null && data['carga'].toString().isNotEmpty);
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

  void loadFromDatabase(Map<String, dynamic> data) {
    selectedPlatform = data['tipo_plataforma'];
    selectedOption = data['puntos_ind'];
    cargaController.text = data['carga']?.toString() ?? '';
    notaController.text = data['observaciones']?.toString() ?? '';

    updatePositionsFromOption();

    for (int i = 0; i < positionControllers.length; i++) {
      positionControllers[i].text = data['posicion${i + 1}']?.toString() ?? '';
      indicationControllers[i].text = data['indicacion${i + 1}']?.toString() ?? '';
      returnControllers[i].text = data['retorno${i + 1}']?.toString() ?? '0';
    }
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

  Future<double> getDForCarga(double carga) async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord == null) {
        return 0.1;
      }

      final pmax1 = double.tryParse(existingRecord['cap_max1']?.toString() ?? '0') ?? 0.0;
      final pmax2 = double.tryParse(existingRecord['cap_max2']?.toString() ?? '0') ?? 0.0;
      final pmax3 = double.tryParse(existingRecord['cap_max3']?.toString() ?? '0') ?? 0.0;

      final d1 = double.tryParse(existingRecord['d1']?.toString() ?? '0.1') ?? 0.1;
      final d2 = double.tryParse(existingRecord['d2']?.toString() ?? '0.1') ?? 0.1;
      final d3 = double.tryParse(existingRecord['d3']?.toString() ?? '0.1') ?? 0.1;

      if (carga <= pmax1) return d1;
      if (carga <= pmax2) return d2;
      if (carga <= pmax3) return d3;
      return d3;
    } catch (e) {
      debugPrint('Error al obtener D de la base de datos: $e');
      return 0.1;
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