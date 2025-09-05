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
  final double Function() getD1Value;
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final BuildContext context;
  VoidCallback? onUpdate;

  final List<String> metodoOptions = [
    'Ascenso evaluando ceros',
    'Ascenso continúo por pasos'
  ];
  final List<String> metodocargaOptions = ['Método 1', 'Método 2'];

  String? selectedMetodo = 'Ascenso evaluando ceros';
  String? selectedMetodoCarga = 'Método 1';
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
    required this.getD1Value,
    this.onUpdate,
  });

  void initControllers(int rowCount) {
    cargaControllers = List.generate(rowCount, (_) => TextEditingController());
    indicacionControllers = List.generate(rowCount, (_) => TextEditingController());
  }

  Future<String> _getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'precarga_database.db');
  }

  Future<void> loadLinFromPrecargaOrDatabase() async {
    try {
      _disposeRows();

      // Paso 1: Buscar en precarga_database.db
      final precargaData = await _loadFromPrecargaDatabase();

      if (precargaData.isNotEmpty) {
        // Si encuentra datos en precarga, los usa
        _createRowsFromPrecargaData(precargaData);
        debugPrint('Datos cargados desde precarga_database.db');

        // Persistir y actualizar UI
        await _persistTempDataAndUpdate();
        return;
      }

      // Paso 2: Si no hay datos en precarga, buscar en AppDatabase
      final appDatabaseData = await _loadFromAppDatabase();

      if (appDatabaseData.isNotEmpty) {
        // Si encuentra datos en AppDatabase, los usa
        _createRowsFromAppDatabaseData(appDatabaseData);
        debugPrint('Datos cargados desde AppDatabase');

        // Persistir y actualizar UI
        await _persistTempDataAndUpdate();
        return;
      }

      // Paso 3: Si no hay datos en ninguna base de datos
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

    // Encontrar el último índice con dato
    int lastIndexWithData = 0;
    for (int i = 1; i <= 60; i++) {
      final v = data['lin$i'];
      if (v != null && v.toString().trim().isNotEmpty) {
        lastIndexWithData = i;
      }
    }

    // Crear filas solo hasta el último índice con dato
    if (lastIndexWithData > 0) {
      for (int i = 1; i <= lastIndexWithData; i++) {
        final v = data['lin$i'];
        addRow();
        if (v != null && v.toString().trim().isNotEmpty) {
          rows[i - 1]['lt']?.text = v.toString();
          valoresCargados++;
        }
      }
    }

    debugPrint('Valores cargados desde precarga: $valoresCargados');
  }

// Procesar datos de AppDatabase
  void _createRowsFromAppDatabaseData(Map<String, dynamic> data) {
    int valoresCargados = 0;

    // Cargar métodos seleccionados
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

        valoresCargados++;
      }
    }

    debugPrint('Valores cargados desde AppDatabase: $valoresCargados');
  }

// Crear filas vacías por defecto
  void _createDefaultEmptyRows() {
    for (int i = 0; i < 6; i++) {
      addRow();
    }
  }

// Mostrar mensaje de no hay datos
  void _showNoDataMessage() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La balanza no tiene registros previos, debe ingresar nuevos',
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
          } else if (i - cargaControllers.length < indicacionControllers.length) {
            indicacionControllers[i - cargaControllers.length].text = value;
          }
        }
      }
    } catch (e) {
      print("Error cargando datos previos: $e");
    }
  }


  // Reemplazar el método initialize() en LinealidadController

  Future<void> initialize() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

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

  void calculateAllDifferences() {
    for (int i = 0; i < rows.length; i++) {
      calculateDifferenceForRow(i);
    }
    Future.microtask(() {
      provider.updateTempDataForTest('linealidad', toMap());
    });
  }

  void calculateDifferenceForRow(int index) {
    if (index >= rows.length) return;
    final lt = double.tryParse(rows[index]['lt']?.text ?? '') ?? 0.0;
    final indicacion =
        double.tryParse(rows[index]['indicacion']?.text ?? '') ?? 0.0;
    final decimalPlaces = getD1Value().toString().split('.').last.length;
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
      final existingRecord = await dbHelper.getRegistroBySeca(secaValue, sessionId);

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
