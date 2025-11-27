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
  final TextEditingController fiftyPercentPmax1Controller =
      TextEditingController();
  final bool loadExisting;
  final List<ValueNotifier<String>> cargaNotifiers = [];

  bool _dataLoadedFromPrecarga = false;
  bool _dataLoadedFromAppDatabase = false;
  bool _isLoadingData = false;

  final VoidCallback? onUpdate;

  RepetibilidadController({
    required this.provider,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.context,
    this.loadExisting = true,
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

  // Método para obtener el valor D apropiado basado en el texto de carga
  Future<double> getDValueForCargaController(int cargaIndex) async {
    if (cargaIndex >= cargaControllers.length) return 0.1;

    final cargaText = cargaControllers[cargaIndex].text.trim();
    if (cargaText.isEmpty) return 0.1;

    final cargaValue = double.tryParse(cargaText.replaceAll(',', '.')) ?? 0.0;
    return await getDForCarga(cargaValue);
  }

  // Método para obtener sugerencias (ahora async)
  Future<List<String>> getIndicationSuggestions(
      int cargaIndex, String currentValue) async {
    final dValue = await getDValueForCargaController(cargaIndex);

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

  // Eliminamos _loadDValuesFromDatabase ya que ahora obtenemos los datos directamente

  Future<void> loadFromPrecargaOrDatabase() async {
    try {
      _disposeControllers();

      // PASO 1: Buscar en AppDatabase (datos históricos) - PRIMERO AHORA
      final appDatabaseData = await _loadFromAppDatabase();

      if (appDatabaseData.isNotEmpty &&
          _hasRepetibilidadData(appDatabaseData)) {
        // Si encuentra datos en AppDatabase, los usa
        _createRowsFromAppDatabaseData(appDatabaseData);
        _dataLoadedFromAppDatabase = true;
        _showDataLoadedMessage(
            'Datos de repetibilidad cargados desde registro existente');
        debugPrint(
            'Datos de repetibilidad cargados desde AppDatabase (históricos)');
        return;
      }

      // PASO 2: Si no hay datos históricos, buscar en precarga_database.db
      final precargaData = await _loadFromPrecargaDatabase();

      if (precargaData.isNotEmpty) {
        // Si encuentra datos en precarga, los usa
        _createRowsFromPrecargaData(precargaData);
        _dataLoadedFromPrecarga = true;
        _showDataLoadedMessage(
            'Datos de repetibilidad cargados desde servicio anterior');
        debugPrint(
            'Datos de repetibilidad cargados desde precarga_database.db');
        return;
      }

      // PASO 3: Si no hay datos en ninguna base de datos
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
        if (data[indicacionKey] != null &&
            data[indicacionKey].toString().isNotEmpty) {
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
      final sessionData =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);
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
    _isLoadingData = true;
    try {
      _initializeControllers(false);

      // Cargar datos de repetibilidad desde precarga (rep1, rep2, rep3)
      for (int i = 1; i <= 3; i++) {
        final cargaValue = data['rep$i']?.toString();
        if (cargaValue != null &&
            cargaValue.isNotEmpty &&
            cargaControllers.length >= i) {
          cargaControllers[i - 1].text = cargaValue;

          // ✅ MEJORADO: Replicar en TODAS las indicaciones y retornos
          for (int j = 0; j < selectedRowCount; j++) {
            if (indicacionControllers[i - 1].length > j) {
              indicacionControllers[i - 1][j].text =
                  cargaValue; // Auto-completar con el valor de carga
            }
            if (retornoControllers[i - 1].length > j) {
              retornoControllers[i - 1][j].text =
                  '0'; // Valor por defecto para retorno
            }
          }
        }
      }

      // Cargar comentario si existe
      notaController.text = data['repetibilidad_comentario']?.toString() ?? '';
    } finally {
      _isLoadingData = false;
      onUpdate?.call();
    }
  }

  void _createRowsFromAppDatabaseData(Map<String, dynamic> data) {
    _isLoadingData = true;
    try {
      _initializeControllers(false);

      // Cargar datos de AppDatabase (repetibilidad1, repetibilidad2, repetibilidad3)
      for (int i = 1; i <= 3; i++) {
        final cargaValue = data['repetibilidad$i']?.toString();
        if (cargaValue != null &&
            cargaValue.isNotEmpty &&
            cargaControllers.length >= i) {
          cargaControllers[i - 1].text = cargaValue;

          // ✅ MEJORADO: Cargar indicaciones y retornos desde AppDatabase
          // Si no hay datos en AppDatabase, replicar el valor de carga
          for (int j = 1; j <= 10; j++) {
            final indicacionValue = data['indicacion${i}_$j']?.toString();
            final retornoValue = data['retorno${i}_$j']?.toString();

            if (j <= selectedRowCount &&
                indicacionControllers[i - 1].length >= j) {
              // Si hay dato en BD, usarlo; si no, replicar carga
              indicacionControllers[i - 1][j - 1].text =
                  indicacionValue ?? cargaValue;
            }

            if (j <= selectedRowCount &&
                retornoControllers[i - 1].length >= j) {
              retornoControllers[i - 1][j - 1].text = retornoValue ?? '0';
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
    } finally {
      _isLoadingData = false;
      onUpdate?.call();
    }
  }

  void _createDefaultEmptyRows() {
    _initializeControllers(false);
  }

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
                  'No se encontraron registros previos de repetibilidad. Debe ingresar nuevos datos.',
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

  Future<void> initialize() async {
    try {
      debugPrint('🔄 Iniciando initialize() de RepetibilidadController');

      // ✅ CRÍTICO: Primero inicializar los controladores con valores por defecto
      _initializeControllers(false);
      debugPrint(
          '✅ Controladores inicializados: ${cargaControllers.length} cargas');

      // Luego intentar cargar datos existentes de esta sesión
      final dbHelper = AppDatabase();
      final existingSessionData =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingSessionData != null &&
          _hasRepetibilidadData(existingSessionData)) {
        // Cargar datos de esta sesión específica
        debugPrint('📥 Cargando datos de sesión actual');
        loadFromDatabase(existingSessionData);
        _showDataLoadedMessage(
            'Datos de repetibilidad cargados desde sesión actual');
      } else {
        // Si no hay datos de esta sesión, buscar en cascada
        debugPrint('🔍 Buscando datos en cascada');
        await loadFromPrecargaOrDatabase();
      }

      // Cargar pmax1 desde la base de datos si existe
      await _loadPmax1FromDatabase();

      debugPrint('✅ initialize() completado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en initialize() de repetibilidad: $e');
      // Asegurar que al menos los controladores estén inicializados
      if (cargaControllers.isEmpty) {
        _initializeControllers(false);
      }
      _handleLoadError(e);
    }
  }

  // Método separado para cargar pmax1
  Future<void> _loadPmax1FromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['cap_max1'] != null) {
        double pmax1 =
            double.tryParse(existingRecord['cap_max1'].toString()) ?? 0.0;
        double fiftyPercentPmax1 = pmax1 * 0.5;
        pmax1Controller.text = pmax1.toStringAsFixed(2);
        fiftyPercentPmax1Controller.text = fiftyPercentPmax1.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error al obtener pmax1: $e');
    }
  }

  void loadFromDatabase(Map<String, dynamic> data) {
    _isLoadingData = true;
    try {
      for (int i = 1; i <= selectedRepetibilityCount; i++) {
        if (data['repetibilidad$i'] != null && cargaControllers.length >= i) {
          final cargaValue = data['repetibilidad$i'].toString();
          cargaControllers[i - 1].text = cargaValue;

          for (int j = 1; j <= selectedRowCount; j++) {
            if (indicacionControllers[i - 1].length >= j) {
              // ✅ MEJORADO: Si no hay indicación en BD, usar valor de carga
              final indicacionValue = data['indicacion${i}_$j']?.toString();
              indicacionControllers[i - 1][j - 1].text =
                  indicacionValue ?? cargaValue;

              final retornoValue = data['retorno${i}_$j']?.toString();
              retornoControllers[i - 1][j - 1].text = retornoValue ?? '0';
            }
          }
        }
      }
      notaController.text = data['repetibilidad_comentario'] ?? '';
    } finally {
      _isLoadingData = false;
      onUpdate?.call();
    }
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
    onUpdate?.call();
  }

  // NUEVO MÉTODO: Manejar cambios en el valor de carga
  void _onCargaValueChanged(int cargaIndex) {
    if (_isLoadingData) return;

    final value = cargaControllers[cargaIndex].text;
    debugPrint('Carga $cargaIndex cambiada a: "$value"');
    _replicateCargaToIndicaciones(cargaIndex, value);
    onUpdate?.call();
  }

  // NUEVO MÉTODO: Replicar valor a todas las indicaciones
  // VERSIÓN SIMPLIFICADA Y MÁS EFECTIVA
  void _replicateCargaToIndicaciones(int cargaIndex, String value) {
    debugPrint(
        'Replicando carga $cargaIndex: "$value" a todas las indicaciones');

    for (int j = 0; j < indicacionControllers[cargaIndex].length; j++) {
      // SIEMPRE actualizar con el nuevo valor, sin excepciones
      indicacionControllers[cargaIndex][j].text = value;
    }

    debugPrint(
        'Actualizadas ${indicacionControllers[cargaIndex].length} indicaciones para carga $cargaIndex');
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
          data['indicacion${i + 1}_${j + 1}'] =
              indicacionControllers[i][j].text;
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
  // Método para restaurar los datos preservados - VERSIÓN MEJORADA
  void _restorePreservedData(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    // Primero restaurar datos de carga
    for (int i = 0;
        i < selectedRepetibilityCount && i < cargaControllers.length;
        i++) {
      final cargaKey = 'repetibilidad${i + 1}';
      if (data[cargaKey] != null) {
        cargaControllers[i].text = data[cargaKey].toString();
      }
    }

    // Luego restaurar datos de indicaciones y retornos
    for (int i = 0;
        i < selectedRepetibilityCount && i < indicacionControllers.length;
        i++) {
      for (int j = 0;
          j < selectedRowCount && j < indicacionControllers[i].length;
          j++) {
        final indicacionKey = 'indicacion${i + 1}_${j + 1}';
        final retornoKey = 'retorno${i + 1}_${j + 1}';

        if (data[indicacionKey] != null) {
          indicacionControllers[i][j].text = data[indicacionKey].toString();
        } else {
          // SI no hay dato preservado, usar el valor actual de la carga
          indicacionControllers[i][j].text = cargaControllers[i].text;
        }

        if (data[retornoKey] != null) {
          retornoControllers[i][j].text = data[retornoKey].toString();
        } else {
          retornoControllers[i][j].text = '0';
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
        registro['indicacion${i + 1}_${j + 1}'] =
            indicacionControllers[i][j].text;
        registro['retorno${i + 1}_${j + 1}'] = retornoControllers[i][j].text;
      }
    }
    registro['repetibilidad_comentario'] = notaController.text;
    registro['seca'] = secaValue;
    registro['session_id'] = sessionId;

    final dbHelper = AppDatabase();
    final existingRecord =
        await dbHelper.getRegistroBySeca(secaValue, sessionId);
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
    pmax1Controller.dispose();
    fiftyPercentPmax1Controller.dispose();
  }

  void clearAllFields() {
    for (var c in cargaControllers) {
      c.clear();
    }
    for (var list in indicacionControllers) {
      for (var c in list) {
        c.clear();
      }
    }
    for (var list in retornoControllers) {
      for (var c in list) {
        c.clear();
      }
    }
    notaController.clear();
    comentarioController.clear();
  }
}
