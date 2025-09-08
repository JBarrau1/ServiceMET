import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:sqflite/sqflite.dart';
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

  double d1 = 0.1; // valor por defecto
  double d2 = 0.1; // valor por defecto
  double d3 = 0.1; // valor por defecto

  // Información de capacidades para determinar qué d usar
  double capMax1 = 0.0;
  double capMax2 = 0.0;
  double capMax3 = 0.0;

  bool _dataLoadedFromPrecarga = false;
  bool _dataLoadedFromAppDatabase = false;

  RepetibilidadController({
    required this.provider,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.context,
    this.loadExisting = true,
  });

  Future<void> _loadDValuesFromDatabase() async {
    try {
      final dbHelper = AppDatabase();

      // Buscar primero por sessionId y seca
      var balanzaData = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      // Si no encuentra, buscar por codMetrica
      if (balanzaData == null) {
        balanzaData = await dbHelper.getRegistroByCodMetrica(codMetrica);
      }

      if (balanzaData != null) {
        // Cargar valores D - usar 0.1 por defecto si está null o vacío
        d1 = double.tryParse(balanzaData['d1']?.toString() ?? '') ?? 0.1;
        d2 = double.tryParse(balanzaData['d2']?.toString() ?? '') ?? 0.1;
        d3 = double.tryParse(balanzaData['d3']?.toString() ?? '') ?? 0.1;

        // Cargar capacidades máximas
        capMax1 = double.tryParse(balanzaData['cap_max1']?.toString() ?? '') ?? 0.0;
        capMax2 = double.tryParse(balanzaData['cap_max2']?.toString() ?? '') ?? 0.0;
        capMax3 = double.tryParse(balanzaData['cap_max3']?.toString() ?? '') ?? 0.0;

        debugPrint('Valores D cargados desde BD - d1: $d1, d2: $d2, d3: $d3');
        debugPrint('Capacidades cargadas desde BD - cap1: $capMax1, cap2: $capMax2, cap3: $capMax3');
      } else {
        debugPrint('No se encontraron datos de balanza, usando valores por defecto d1=d2=d3=0.1');
      }

    } catch (e) {
      debugPrint('Error al cargar valores D desde la base de datos: $e');
      // Mantener valores por defecto en caso de error
    }
  }

  // Método para obtener el valor D correcto según la carga
  double getDForCarga(double carga) {
    if (carga <= capMax1 && capMax1 > 0) return d1;
    if (carga <= capMax2 && capMax2 > 0) return d2;
    if (carga <= capMax3 && capMax3 > 0) return d3;
    return d1; // fallback al primer rango
  }

  // Actualizar el método getD1Value para que sea síncrono
  double getD1Value() {
    return d1;
  }

  // Nuevo método para obtener todos los valores D
  Map<String, double> getAllDValues() {
    return {
      'd1': d1,
      'd2': d2,
      'd3': d3,
    };
  }

  // Método para obtener el valor D apropiado basado en el texto de carga
  double getDValueForCargaController(int cargaIndex) {
    if (cargaIndex >= cargaControllers.length) return d1;

    final cargaText = cargaControllers[cargaIndex].text.trim();
    if (cargaText.isEmpty) return d1;

    final cargaValue = double.tryParse(cargaText.replaceAll(',', '.')) ?? 0.0;
    return getDForCarga(cargaValue);
  }



  Future<void> loadFromPrecargaOrDatabase() async {
    try {
      _disposeControllers();

      // Paso 1: Buscar en precarga_database.db
      final precargaData = await _loadFromPrecargaDatabase();

      if (precargaData.isNotEmpty) {
        // Si encuentra datos en precarga, los usa
        _createRowsFromPrecargaData(precargaData);
        _dataLoadedFromPrecarga = true;
        _showDataLoadedMessage('Datos de repetibilidad cargados desde servicio anterior');
        debugPrint('Datos de repetibilidad cargados desde precarga_database.db');
        return;
      }

      // Paso 2: Si no hay datos en precarga, buscar en AppDatabase
      final appDatabaseData = await _loadFromAppDatabase();

      if (appDatabaseData.isNotEmpty && _hasRepetibilidadData(appDatabaseData)) {
        // Si encuentra datos en AppDatabase, los usa
        _createRowsFromAppDatabaseData(appDatabaseData);
        _dataLoadedFromAppDatabase = true;
        _showDataLoadedMessage('Datos de repetibilidad cargados desde registro existente');
        debugPrint('Datos de repetibilidad cargados desde AppDatabase');
        return;
      }

      // Paso 3: Si no hay datos en ninguna base de datos
      _showNoDataMessage();
      _createDefaultEmptyRows();

    } catch (e) {
      debugPrint('Error en búsqueda cascada de repetibilidad: $e');
      _handleLoadError(e);
    }
  }

  bool _hasRepetibilidadData(Map<String, dynamic> data) {
    // Verificar si existe al menos una carga de repetibilidad
    for (int i = 1; i <= 3; i++) {
      final cargaKey = 'repetibilidad$i';
      if (data[cargaKey] != null && data[cargaKey].toString().isNotEmpty) {
        return true;
      }
    }

    // También verificar indicaciones
    for (int i = 1; i <= 3; i++) {
      for (int j = 1; j <= 10; j++) {
        final indicacionKey = 'indicacion${i}_$j';
        if (data[indicacionKey] != null && data[indicacionKey].toString().isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  Future<Map<String, dynamic>> _loadFromPrecargaDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'precarga_database.db');
      final db = await openDatabase(path, readOnly: true);

      // Buscar el registro más reciente según cod_metrica
      final result = await db.query(
        'servicios',
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
        orderBy: 'reg_fecha DESC',
        limit: 1,
      );

      await db.close();

      return result.isNotEmpty ? result.first : {};

    } catch (e) {
      debugPrint('Error al cargar repetibilidad desde precarga: $e');
      return {};
    }
  }


  Future<Map<String, dynamic>> _loadFromAppDatabase() async {
    try {
      final dbHelper = AppDatabase();

      // Primero buscar por sessionId y seca (datos más específicos)
      final sessionData = await dbHelper.getRegistroBySeca(secaValue, sessionId);
      if (sessionData != null && _hasRepetibilidadData(sessionData)) {
        return sessionData;
      }

      // Si no encuentra por session, buscar por codMetrica
      final codMetricaData = await dbHelper.getRegistroByCodMetrica(codMetrica);
      if (codMetricaData != null && _hasRepetibilidadData(codMetricaData)) {
        return codMetricaData;
      }

      return {};

    } catch (e) {
      debugPrint('Error al cargar repetibilidad desde AppDatabase: $e');
      return {};
    }
  }


  void _createRowsFromPrecargaData(Map<String, dynamic> data) {
    _initializeControllers(false);

    // Cargar datos de repetibilidad desde precarga (rep1, rep2, rep3)
    for (int i = 1; i <= 3; i++) {
      final cargaValue = data['rep$i']?.toString();
      if (cargaValue != null && cargaValue.isNotEmpty && cargaControllers.length >= i) {
        cargaControllers[i - 1].text = cargaValue;

        // En precarga no hay indicaciones, así que las dejamos vacías
        for (int j = 0; j < selectedRowCount; j++) {
          if (indicacionControllers[i - 1].length > j) {
            indicacionControllers[i - 1][j].text = cargaValue; // Auto-completar con el valor de carga
          }
        }
      }
    }

    // Cargar comentario si existe
    notaController.text = data['repetibilidad_comentario']?.toString() ?? '';
  }

  void _createRowsFromAppDatabaseData(Map<String, dynamic> data) {
    _initializeControllers(false);

    // Cargar datos de AppDatabase (repetibilidad1, repetibilidad2, repetibilidad3)
    for (int i = 1; i <= 3; i++) {
      final cargaValue = data['repetibilidad$i']?.toString();
      if (cargaValue != null && cargaValue.isNotEmpty && cargaControllers.length >= i) {
        cargaControllers[i - 1].text = cargaValue;

        // Cargar indicaciones y retornos desde AppDatabase
        for (int j = 1; j <= 10; j++) {
          final indicacionValue = data['indicacion${i}_$j']?.toString();
          final retornoValue = data['retorno${i}_$j']?.toString();

          if (indicacionValue != null && indicacionValue.isNotEmpty &&
              j <= selectedRowCount && indicacionControllers[i - 1].length >= j) {
            indicacionControllers[i - 1][j - 1].text = indicacionValue;
          }

          if (retornoValue != null && retornoValue.isNotEmpty &&
              j <= selectedRowCount && retornoControllers[i - 1].length >= j) {
            retornoControllers[i - 1][j - 1].text = retornoValue;
          }
        }
      }
    }

    // Cargar comentario si existe
    notaController.text = data['repetibilidad_comentario']?.toString() ?? '';

    // Cargar pmax1 si existe
    if (data['cap_max1'] != null) {
      double pmax1 = double.tryParse(data['cap_max1'].toString()) ?? 0.0;
      double fiftyPercentPmax1 = pmax1 * 0.5;
      pmax1Controller.text = pmax1.toStringAsFixed(2);
      fiftyPercentPmax1Controller.text = fiftyPercentPmax1.toStringAsFixed(2);
    }
  }

  void _createDefaultEmptyRows() {
    _initializeControllers(false);
  }

  // Actualizar los mensajes en RepetibilidadController

  void _showDataLoadedMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showNoDataMessage() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La balanza no tiene registros previos, debe ingresar nuevos datos de repetibilidad',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleLoadError(dynamic error) {
    debugPrint('Error en carga de datos de repetibilidad: $error');
    _createDefaultEmptyRows();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar datos de repetibilidad: ${error.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  @override
  Future<void> initialize() async {
    try {
      // Cargar valores D primero
      await _loadDValuesFromDatabase();

      // Luego la búsqueda en cascada para datos de repetibilidad
      await loadFromPrecargaOrDatabase();

      // Cargar pmax1 desde la base de datos si existe
      await _loadPmax1FromDatabase();

    } catch (e) {
      debugPrint('Error en initialize() de repetibilidad: $e');
      _handleLoadError(e);
    }
  }

  List<String> getIndicationSuggestions(int cargaIndex, String currentValue) {
    final dValue = getDValueForCargaController(cargaIndex);

    // Si está vacío, usa la carga como base
    final baseText = currentValue.trim().isEmpty
        ? cargaControllers[cargaIndex].text
        : currentValue;

    final baseValue = double.tryParse(baseText.replaceAll(',', '.')) ?? 0.0;

    // Determinar decimales basado en dValue
    int decimalPlaces = 1; // por defecto
    if (dValue >= 1) {
      decimalPlaces = 0;
    } else if (dValue >= 0.1) {
      decimalPlaces = 1;
    } else if (dValue >= 0.01) {
      decimalPlaces = 2;
    } else if (dValue >= 0.001) {
      decimalPlaces = 3;
    }

    // 11 sugerencias (5 abajo, actual, 5 arriba)
    return List.generate(11, (i) {
      final value = baseValue + ((i - 5) * dValue);
      return value.toStringAsFixed(decimalPlaces);
    });
  }

// Método separado para cargar pmax1
  Future<void> _loadPmax1FromDatabase() async {
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

      // Primero crear todos los controladores de indicación
      for (int j = 0; j < selectedRowCount; j++) {
        final indicacion = TextEditingController();
        final retorno = TextEditingController(text: '0');
        indicacionControllers[i].add(indicacion);
        retornoControllers[i].add(retorno);
      }

      // Configurar el listener PARA CAMBIOS FUTUROS
      cargaController.addListener(() {
        _onCargaValueChanged(i);
      });

      // EJECUTAR MANUALMENTE POR PRIMERA VEZ si ya hay valor
      if (cargaController.text.isNotEmpty) {
        _replicateCargaToIndicaciones(i, cargaController.text);
      }
    }

    if (onUpdated != null) {
      onUpdated();
    }
  }

// NUEVO MÉTODO: Manejar cambios en el valor de carga
  void _onCargaValueChanged(int cargaIndex) {
    final value = cargaControllers[cargaIndex].text;
    debugPrint('Carga $cargaIndex cambiada a: "$value"');
    _replicateCargaToIndicaciones(cargaIndex, value);
  }

// NUEVO MÉTODO: Replicar valor a todas las indicaciones
  void _replicateCargaToIndicaciones(int cargaIndex, String value) {
    if (value.isEmpty) return;

    for (int j = 0; j < indicacionControllers[cargaIndex].length; j++) {
      final currentValue = indicacionControllers[cargaIndex][j].text;

      if (currentValue.isEmpty ||
          currentValue == '0' ||
          value.startsWith(currentValue) ||
          currentValue.length < value.length) {

        indicacionControllers[cargaIndex][j].text = value;
        debugPrint('Indicación ${cargaIndex + 1}_${j + 1} = "$value"');
      }
    }
  }

  void updateRepetibilityCount(int? value, VoidCallback onUpdateUI) {
    if (value != null) {
      // Preservar datos existentes antes de cambiar
      final existingData = _preserveExistingData();

      selectedRepetibilityCount = value;
      _initializeControllers(false);

      // Restaurar datos preservados
      _restorePreservedData(existingData);

      onUpdateUI();
    }
  }

  void updateRowCount(int? value, VoidCallback onUpdateUI) {
    if (value != null) {
      // Preservar datos existentes antes de cambiar
      final existingData = _preserveExistingData();

      selectedRowCount = value;
      _initializeControllers(false);

      // Restaurar datos preservados
      _restorePreservedData(existingData);

      onUpdateUI();
    }
  }

  Map<String, dynamic> _preserveExistingData() {
    final data = <String, dynamic>{};

    // Preservar datos de carga
    for (int i = 0; i < cargaControllers.length && i < 3; i++) {
      if (cargaControllers[i].text.isNotEmpty) {
        data['repetibilidad${i + 1}'] = cargaControllers[i].text;
      }
    }

    // Preservar datos de indicaciones y retornos
    for (int i = 0; i < indicacionControllers.length && i < 3; i++) {
      for (int j = 0; j < indicacionControllers[i].length && j < 10; j++) {
        if (indicacionControllers[i][j].text.isNotEmpty) {
          data['indicacion${i + 1}_${j + 1}'] = indicacionControllers[i][j].text;
        }
        if (retornoControllers[i][j].text.isNotEmpty) {
          data['retorno${i + 1}_${j + 1}'] = retornoControllers[i][j].text;
        }
      }
    }

    // Preservar comentarios
    if (notaController.text.isNotEmpty) {
      data['repetibilidad_comentario'] = notaController.text;
    }

    // Preservar pmax1 y fiftyPercentPmax1
    if (pmax1Controller.text.isNotEmpty) {
      data['pmax1'] = pmax1Controller.text;
    }
    if (fiftyPercentPmax1Controller.text.isNotEmpty) {
      data['fiftyPercentPmax1'] = fiftyPercentPmax1Controller.text;
    }

    return data;
  }

  // Método para restaurar los datos preservados
  void _restorePreservedData(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    // Restaurar datos de carga
    for (int i = 0; i < selectedRepetibilityCount && i < cargaControllers.length; i++) {
      final cargaKey = 'repetibilidad${i + 1}';
      if (data[cargaKey] != null) {
        cargaControllers[i].text = data[cargaKey].toString();
      }
    }

    // Restaurar datos de indicaciones y retornos
    for (int i = 0; i < selectedRepetibilityCount && i < indicacionControllers.length; i++) {
      for (int j = 0; j < selectedRowCount && j < indicacionControllers[i].length; j++) {
        final indicacionKey = 'indicacion${i + 1}_${j + 1}';
        final retornoKey = 'retorno${i + 1}_${j + 1}';

        if (data[indicacionKey] != null) {
          indicacionControllers[i][j].text = data[indicacionKey].toString();
        }
        if (data[retornoKey] != null) {
          retornoControllers[i][j].text = data[retornoKey].toString();
        }
      }
    }

    // Restaurar comentarios
    if (data['repetibilidad_comentario'] != null) {
      notaController.text = data['repetibilidad_comentario'].toString();
    }

    // Restaurar pmax1 y fiftyPercentPmax1
    if (data['pmax1'] != null) {
      pmax1Controller.text = data['pmax1'].toString();
    }
    if (data['fiftyPercentPmax1'] != null) {
      fiftyPercentPmax1Controller.text = data['fiftyPercentPmax1'].toString();
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
