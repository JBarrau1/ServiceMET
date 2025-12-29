// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:service_met/providers/calibration_provider.dart';
import '../../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LinealidadController {
  List<TextEditingController> cargaControllers = [];
  List<TextEditingController> indicacionControllers = [];
  final ValueNotifier<bool> updateNotifier = ValueNotifier(false);
  final List<VoidCallback> _updateCallbacks = [];
  final CalibrationProvider provider;
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final BuildContext context;
  VoidCallback? onUpdate;

  final List<String> metodoOptions = [
    'Ascenso evaluando ceros',
    'Ascenso continúo por pasos'
  ];
  final List<String> metodocargaOptions = [
    'Sin método de carga',
    'Método 1',
    'Método 2'
  ];
  String? selectedMetodoCarga = 'Sin método de carga'; // Valor por defecto

  String? selectedMetodo = 'Ascenso evaluando ceros';
  final List<Map<String, TextEditingController>> rows = [];
  final TextEditingController notaController = TextEditingController();
  final TextEditingController comentarioController = TextEditingController();

  final TextEditingController iLsubnController = TextEditingController();
  final TextEditingController lsubnController = TextEditingController();
  final TextEditingController ioController = TextEditingController(text: '0');
  final TextEditingController ltnController = TextEditingController();
  final TextEditingController cpController = TextEditingController();
  final TextEditingController iCpController = TextEditingController();

  LinealidadController({
    required this.provider,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.context,
    this.onUpdate,
  });

  // Método para obtener el valor D correcto según la carga desde la BD
  Future<double> getDForCarga(double carga) async {
    try {
      final dbHelper = AppDatabase();

      // Buscar primero por sessionId y seca
      var balanzaData = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      // Si no encuentra, buscar por codMetrica
      balanzaData ??= await dbHelper.getRegistroByCodMetrica(codMetrica);

      if (balanzaData != null) {
        // Obtener valores D de la base de datos
        final d1 = double.tryParse(balanzaData['d1']?.toString() ?? '') ?? 0.1;
        final d2 = double.tryParse(balanzaData['d2']?.toString() ?? '') ?? 0.1;
        final d3 = double.tryParse(balanzaData['d3']?.toString() ?? '') ?? 0.1;

        // Obtener capacidades máximas
        final capMax1 =
            double.tryParse(balanzaData['cap_max1']?.toString() ?? '') ?? 0.0;
        final capMax2 =
            double.tryParse(balanzaData['cap_max2']?.toString() ?? '') ?? 0.0;
        final capMax3 =
            double.tryParse(balanzaData['cap_max3']?.toString() ?? '') ?? 0.0;

        // Lógica de selección según la carga
        if (carga <= capMax1 && capMax1 > 0) return d1;
        if (carga <= capMax2 && capMax2 > 0) return d2;
        if (carga <= capMax3 && capMax3 > 0) return d3;
        return d1; // fallback al primer rango
      } else {
        debugPrint(
            'No se encontraron datos de balanza, usando valor por defecto d=0.1');
        return 0.1;
      }
    } catch (e) {
      debugPrint('Error al obtener D desde la base de datos: $e');
      return 0.1; // Valor por defecto en caso de error
    }
  }

  // Método para obtener todos los valores D desde la BD
  Future<Map<String, double>> getAllDValues() async {
    try {
      final dbHelper = AppDatabase();

      // Buscar primero por sessionId y seca
      var balanzaData = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      // Si no encuentra, buscar por codMetrica
      balanzaData ??= await dbHelper.getRegistroByCodMetrica(codMetrica);

      if (balanzaData != null) {
        return {
          'd1': double.tryParse(balanzaData['d1']?.toString() ?? '') ?? 0.1,
          'd2': double.tryParse(balanzaData['d2']?.toString() ?? '') ?? 0.1,
          'd3': double.tryParse(balanzaData['d3']?.toString() ?? '') ?? 0.1,
          'pmax1':
              double.tryParse(balanzaData['cap_max1']?.toString() ?? '') ?? 0.0,
          'pmax2':
              double.tryParse(balanzaData['cap_max2']?.toString() ?? '') ?? 0.0,
          'pmax3':
              double.tryParse(balanzaData['cap_max3']?.toString() ?? '') ?? 0.0,
        };
      } else {
        debugPrint(
            'No se encontraron datos de balanza, usando valores por defecto');
        return {
          'd1': 0.1,
          'd2': 0.1,
          'd3': 0.1,
          'pmax1': 0.0,
          'pmax2': 0.0,
          'pmax3': 0.0
        };
      }
    } catch (e) {
      debugPrint('Error al obtener valores D desde la BD: $e');
      return {
        'd1': 0.1,
        'd2': 0.1,
        'd3': 0.1,
        'pmax1': 0.0,
        'pmax2': 0.0,
        'pmax3': 0.0
      };
    }
  }

  // Método para obtener el valor D1 (para compatibilidad con código existente)
  Future<double> getD1Value() async {
    final dValues = await getAllDValues();
    return dValues['d1'] ?? 0.1;
  }

  // Método para obtener decimal places basado en el valor D
  Future<int> getDecimalPlacesForCarga(double carga) async {
    final dValue = await getDForCarga(carga);

    if (dValue >= 1) return 0;
    if (dValue >= 0.1) return 1;
    if (dValue >= 0.01) return 2;
    if (dValue >= 0.001) return 3;
    return 1; // por defecto
  }

  void initControllers(int rowCount) {
    cargaControllers = List.generate(rowCount, (_) => TextEditingController());
    indicacionControllers =
        List.generate(rowCount, (_) => TextEditingController());
  }

  Future<String> _getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'precarga_database.db');
  }

  Future<void> loadLinFromPrecargaOrDatabase() async {
    try {
      _disposeRows();

      // PASO 1: Buscar PRIMERO en precarga_database.db (como en el código antiguo)
      final precargaData = await _loadFromPrecargaDatabase();

      if (precargaData.isNotEmpty) {
        _createRowsFromPrecargaData(precargaData);
        debugPrint('Datos cargados desde precarga_database.db');
        await _persistTempDataAndUpdate();
        return;
      }

      // PASO 2: Si no hay datos en precarga, buscar en AppDatabase
      final appDatabaseData = await _loadFromAppDatabase();

      if (appDatabaseData.isNotEmpty) {
        _createRowsFromAppDatabaseData(appDatabaseData);
        debugPrint('Datos cargados desde AppDatabase (históricos)');
        await _persistTempDataAndUpdate();
        return;
      }

      // PASO 3: Si no hay datos en ninguna base de datos
      _showNoDataMessage();
      _createDefaultEmptyRows();
      await _persistTempDataAndUpdate();
    } catch (e) {
      debugPrint('Error en búsqueda cascada: $e');
      _handleLoadError(e);
    }
  }

  Future<Map<String, dynamic>> _loadFromPrecargaDatabase() async {
    try {
      final dbPath = await _getDatabasePath(); // Método mejorado sin hardcode
      final db = await openDatabase(dbPath, readOnly: true);

      final columns = List<String>.generate(60, (i) => 'lin${i + 1}');

      final result = await db.query(
        'servicios',
        columns: columns,
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
        orderBy: 'reg_fecha DESC',
        limit: 1,
      );

      await db.close();

      return result.isNotEmpty ? result.first : {};
    } catch (e) {
      debugPrint('Error cargando desde precarga_database.db: $e');
      return {};
    }
  }

  // Método para cargar desde AppDatabase
  Future<Map<String, dynamic>> _loadFromAppDatabase() async {
    try {
      final dbHelper = AppDatabase();

      // Buscar por codMetrica en la tabla de calibración
      final result = await dbHelper.getRegistroByCodMetrica(codMetrica);

      return result ?? {};
    } catch (e) {
      debugPrint('Error cargando desde AppDatabase: $e');
      return {};
    }
  }

  // Procesar datos de precarga_database.db
  void _createRowsFromPrecargaData(Map<String, dynamic> data) {
    int valoresCargados = 0;

    // Encontrar el último índice con dato (sin límite de 12)
    int lastIndexWithData = 0;
    for (int i = 1; i <= 60; i++) {
      final v = data['lin$i'];
      if (v != null && v.toString().trim().isNotEmpty) {
        lastIndexWithData = i;
      }
    }

    // Crear filas hasta donde hay datos (sin límite)
    if (lastIndexWithData > 0) {
      for (int i = 1; i <= lastIndexWithData; i++) {
        final v = data['lin$i'];
        if (rows.length < i) addRow();

        if (v != null && v.toString().trim().isNotEmpty) {
          rows[i - 1]['lt']?.text = v.toString();
          rows[i - 1]['indicacion']?.text =
              v.toString(); // ← LLENAR TAMBIÉN INDICACIÓN
          valoresCargados++;
        }
      }
    } else {
      // Si no hay datos en precarga, crear 12 vacías
      for (int i = 0; i < 12; i++) {
        addRow();
      }
    }

    debugPrint('Valores cargados desde precarga: $valoresCargados');
  }

  // Procesar datos de AppDatabase
  void _createRowsFromAppDatabaseData(Map<String, dynamic> data) {
    int valoresCargados = 0;

    // Cargar métodos seleccionados
    selectedMetodo = data['metodo'] ?? 'Ascenso evaluando ceros';
    selectedMetodoCarga = data['metodo_carga'] ?? 'Sin método de carga';
    notaController.text = data['linealidad_comentario'] ?? '';

    // Cargar TODAS las filas que tengan datos (sin límite de 12)
    for (int i = 1; i <= 60; i++) {
      final lt = data['lin$i'];
      final ind = data['ind$i'];

      if ((lt != null && lt.toString().isNotEmpty) ||
          (ind != null && ind.toString().isNotEmpty)) {
        if (rows.length < i) addRow();

        rows[i - 1]['lt']?.text = lt?.toString() ?? '';
        rows[i - 1]['indicacion']?.text = ind?.toString() ?? '';
        rows[i - 1]['retorno']?.text = data['retorno_lin$i']?.toString() ?? '0';
        rows[i - 1]['difference']?.text = data['diff$i']?.toString() ?? '';

        valoresCargados++;
      }
    }

    // Si no se cargó ninguna fila, crear 12 vacías
    if (valoresCargados == 0) {
      for (int i = 0; i < 12; i++) {
        addRow();
      }
    }

    debugPrint('Valores cargados desde AppDatabase: $valoresCargados');
  }

  // Crear filas vacías por defecto
  void _createDefaultEmptyRows() {
    for (int i = 0; i < 12; i++) {
      // Cambiado de 6 a 12
      addRow();
    }
  }

  // Mostrar mensaje de no hay datos
  void _showNoDataMessage() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron registros previos. Se han creado 12 campos vacíos para ingresar nuevos datos.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Persistir datos temporales y actualizar UI
  Future<void> _persistTempDataAndUpdate() async {
    await Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
    onUpdate?.call();
  }

  // Manejo de errores
  void _handleLoadError(dynamic error) {
    debugPrint('Error en carga de datos: $error');

    // Crear filas vacías como fallback
    if (rows.isEmpty) {
      _createDefaultEmptyRows();
    }

    // Mostrar mensaje de error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar datos: ${error.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    onUpdate?.call();
  }

  Future<void> loadPreviousServiceData() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'precarga_database.db');

      final db = await openDatabase(path);

      // Traemos el último registro de servicios
      final List<Map<String, dynamic>> result = await db.query(
        'servicios',
        orderBy: 'id DESC', // suponiendo que tienes un id autoincrement
        limit: 1,
      );

      if (result.isNotEmpty) {
        final row = result.first;

        for (int i = 0; i < 60; i++) {
          final key = 'lin${i + 1}';
          final value = row[key]?.toString() ?? '';

          // Suponiendo que la estructura es: par (carga, indicacion)
          if (i < cargaControllers.length) {
            cargaControllers[i].text = value;
          } else if (i - cargaControllers.length <
              indicacionControllers.length) {
            indicacionControllers[i - cargaControllers.length].text = value;
          }
        }
      }
    } catch (e) {
      print("Error cargando datos previos: $e");
    }
  }

  Future<void> initialize() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);

      // Solo cargar datos temporales si no hay datos en DB por sessionId
      final tempData = provider.getTempDataForTest('linealidad');

      if (tempData != null && !_hasDatabaseData(existingRecord)) {
        // Hay datos temporales y no hay datos en BD por session
        fromMap(tempData);
      } else if (existingRecord != null && _hasDatabaseData(existingRecord)) {
        // Hay datos en BD por sessionId, los carga directamente
        loadFromDatabase(existingRecord);
      } else {
        // No hay datos temporales ni por sessionId, busca por codMetrica
        await loadLinFromPrecargaOrDatabase(); // ← Usar el nuevo método
      }
    } catch (e) {
      debugPrint('Error en initialize(): $e');
      _createDefaultEmptyRows();
    }

    onUpdate?.call();
  }

  bool _hasDatabaseData(Map<String, dynamic>? data) {
    if (data == null) return false;
    for (int i = 1; i <= 60; i++) {
      if (data['lin$i'] != null && data['lin$i'].toString().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  void addUpdateListener(VoidCallback callback) {
    _updateCallbacks.add(callback);
  }

  void removeUpdateListener(VoidCallback callback) {
    _updateCallbacks.remove(callback);
  }

  void _initializeRows() {
    _disposeRows();
    for (int i = 0; i < 6; i++) {
      addRow();
    }
    _loadExistingData();
  }

  void _loadExistingData() {
    if (provider.currentData != null) {
      final data = provider.currentData!.balanzaData;
      selectedMetodo = data['metodo'];
      selectedMetodoCarga = data['metodo_carga'];

      for (int i = 1; i <= 60; i++) {
        final lt = data['lin$i'];
        final ind = data['ind$i'];
        if ((lt != null && lt.toString().isNotEmpty) ||
            (ind != null && ind.toString().isNotEmpty)) {
          if (rows.length < i) addRow();
          rows[i - 1]['lt']?.text = lt ?? '';
          rows[i - 1]['indicacion']?.text = ind ?? '';
          rows[i - 1]['retorno']?.text = data['retorno_lin$i'] ?? '0';
          rows[i - 1]['difference']?.text = data['diff$i'] ?? '';
        }
      }
    }
  }

  void calcularMetodo2() {
    final iLsubn = double.tryParse(iLsubnController.text) ?? 0.0;
    final io = double.tryParse(ioController.text) ?? 0.0;
    double? lsubnCalculado;
    for (var row in rows) {
      final lt = double.tryParse(row['lt']?.text ?? '') ?? 0.0;
      final indicacion = double.tryParse(row['indicacion']?.text ?? '') ?? 0.0;
      final diff = (indicacion - lt).abs();
      final targetDiff = (iLsubn - lt).abs();
      if ((diff - targetDiff).abs() < 0.0001) {
        lsubnCalculado = indicacion;
        break;
      }
    }
    lsubnCalculado ??= rows.isNotEmpty
        ? double.tryParse(rows.last['indicacion']?.text ?? '') ?? 0.0
        : 0.0;
    lsubnController.text = lsubnCalculado.toStringAsFixed(2);
    final ltn = lsubnCalculado + io;
    ltnController.text = ltn.toStringAsFixed(2);
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  void _notifyUpdate() {
    for (final callback in _updateCallbacks) {
      callback();
    }
  }

  void updateMetodo(String? value) {
    selectedMetodo = value;
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
      _notifyUpdate(); // ← En lugar de onUpdate?.call()
    });
  }

  void updateMetodoCarga(String? value) {
    selectedMetodoCarga = value;
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  void addRow() {
    if (rows.length >= 60) return;
    if (rows.length == 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha superado las 12 cargas sugeridas.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    rows.add({
      'lt': TextEditingController(),
      'indicacion': TextEditingController(),
      'retorno': TextEditingController(text: '0'),
      'difference': TextEditingController(),
    });
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
    onUpdate?.call();
  }

  void removeRow(int index) {
    if (index >= 6 && rows.length > 6) {
      for (var controller in rows[index].values) {
        controller.dispose();
      }
      rows.removeAt(index);
      Future.microtask(() {
        provider.updateTempDataForTest('linealidad', toMap());
      });
    }
  }

  void saveLtnToNewRow() {
    final ltn = ltnController.text;
    if (ltn.isEmpty) return;

    bool inserted = false;
    for (var row in rows) {
      if (row['lt']?.text.isEmpty ?? true) {
        row['lt']?.text = ltn;
        inserted = true;
        break;
      }
    }

    if (!inserted && rows.length < 60) {
      addRow();
      rows.last['lt']?.text = ltn;
      // Notificar que se agregó una nueva fila (para el scroll)
      onUpdate?.call();
    }

    iLsubnController.clear();
    lsubnController.clear();
    ioController.clear();
    ltnController.clear();
    cpController.clear();
    iCpController.clear();

    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  // Método actualizado para calcular diferencias
  Future<void> calculateAllDifferences() async {
    for (int i = 0; i < rows.length; i++) {
      await calculateDifferenceForRow(i);
    }
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  // Método actualizado para calcular diferencia por fila
  Future<void> calculateDifferenceForRow(int index) async {
    if (index >= rows.length) return;
    final lt = double.tryParse(rows[index]['lt']?.text ?? '') ?? 0.0;
    final indicacion =
        double.tryParse(rows[index]['indicacion']?.text ?? '') ?? 0.0;

    // Obtener decimal places basado en la carga
    final decimalPlaces = await getDecimalPlacesForCarga(lt);

    rows[index]['difference']?.text =
        (indicacion - lt).toStringAsFixed(decimalPlaces);
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  bool get isDataValid {
    for (var row in rows) {
      if (row['lt']?.text.isEmpty ?? true) return false;
      if (row['indicacion']?.text.isEmpty ?? true) return false;
    }
    return true;
  }

  Future<void> saveDataToDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);

      final Map<String, dynamic> registro = {
        'session_id': sessionId,
        'seca': secaValue,
        'metodo': selectedMetodo,
        'metodo_carga': selectedMetodoCarga,
        'linealidad_comentario': notaController.text,
      };

      // Guardar datos de cada fila
      for (int i = 0; i < rows.length; i++) {
        registro['lin${i + 1}'] = rows[i]['lt']?.text ?? '';
        registro['ind${i + 1}'] = rows[i]['indicacion']?.text ?? '';
        registro['retorno_lin${i + 1}'] = rows[i]['retorno']?.text ?? '0';
      }

      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }
    } catch (e) {
      debugPrint('Error al guardar linealidad: $e');
      rethrow;
    }
  }

  void loadFromDatabase(Map<String, dynamic> data) {
    selectedMetodo = data['metodo'] ?? 'Ascenso evaluando ceros';
    selectedMetodoCarga = data['metodo_carga'] ?? 'Método 1';
    notaController.text = data['linealidad_comentario'] ?? '';

    // Cargar datos de las filas
    for (int i = 1; i <= 60; i++) {
      final lt = data['lin$i'];
      final ind = data['ind$i'];
      if ((lt != null && lt.toString().isNotEmpty) ||
          (ind != null && ind.toString().isNotEmpty)) {
        if (rows.length < i) addRow();
        rows[i - 1]['lt']?.text = lt?.toString() ?? '';
        rows[i - 1]['indicacion']?.text = ind?.toString() ?? '';
        rows[i - 1]['retorno']?.text = data['retorno_lin$i']?.toString() ?? '0';
        rows[i - 1]['difference']?.text = data['diff$i']?.toString() ?? '';
      }
    }

    // Cargar campos adicionales del método
    iLsubnController.text = data['i_lsubn']?.toString() ?? '';
    lsubnController.text = data['lsubn']?.toString() ?? '';
    ioController.text = data['io']?.toString() ?? '0';
    ltnController.text = data['ltn']?.toString() ?? '';
    cpController.text = data['cp']?.toString() ?? '';
    iCpController.text = data['i_cp']?.toString() ?? '';

    onUpdate?.call();
  }

  void clearAllFields() {
    _disposeRows();
    _initializeRows();
    iLsubnController.clear();
    lsubnController.clear();
    ioController.clear();
    ltnController.clear();
    cpController.clear();
    iCpController.clear();
    notaController.clear();
    comentarioController.clear();
    onUpdate?.call();
  }

  void _disposeRows() {
    for (var row in rows) {
      for (var controller in row.values) {
        controller.dispose();
      }
    }
    rows.clear();
  }

  void dispose() {
    _disposeRows();
    notaController.dispose();
    comentarioController.dispose();
    iLsubnController.dispose();
    lsubnController.dispose();
    ioController.dispose();
    ltnController.dispose();
    cpController.dispose();
    iCpController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'metodo': selectedMetodo,
      'metodoCarga': selectedMetodoCarga,
      'rows': rows.map((row) {
        return {
          'lt': row['lt']?.text,
          'indicacion': row['indicacion']?.text,
          'retorno': row['retorno']?.text,
          'difference': row['difference']?.text,
        };
      }).toList(),
      'nota': notaController.text,
      'comentario': comentarioController.text,
      'iLsubn': iLsubnController.text,
      'lsubn': lsubnController.text,
      'io': ioController.text,
      'ltn': ltnController.text,
      'cp': cpController.text,
      'iCp': iCpController.text,
    };
  }

  void fromMap(Map<String, dynamic> map) {
    selectedMetodo = map['selectedMetodo'];
    selectedMetodoCarga = map['selectedMetodoCarga'];
    _disposeRows();
    List rowsData = map['rows'] ?? [];
    for (var rowMap in rowsData) {
      rows.add({
        'lt': TextEditingController(text: rowMap['lt']),
        'indicacion': TextEditingController(text: rowMap['indicacion']),
        'retorno': TextEditingController(text: rowMap['retorno'] ?? '0'),
        'difference': TextEditingController(text: rowMap['difference']),
      });
    }
    notaController.text = map['nota'] ?? '';
    comentarioController.text = map['comentario'] ?? '';
    iLsubnController.text = map['iLsubn'] ?? '';
    lsubnController.text = map['lsubn'] ?? '';
    ioController.text = map['io'] ?? '';
    ltnController.text = map['ltn'] ?? '';
    cpController.text = map['cp'] ?? '';
    iCpController.text = map['iCp'] ?? '';
    onUpdate?.call();
  }
}
