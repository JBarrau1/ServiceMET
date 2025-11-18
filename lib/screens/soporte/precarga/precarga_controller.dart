// precarga_controller.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive_io.dart';
import '../../../database/soporte_tecnico/database_helper_ajustes.dart';
import '../../../database/soporte_tecnico/database_helper_diagnostico.dart';
import '../../../database/soporte_tecnico/database_helper_instalacion.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_correctivo.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_regular_stac.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_regular_stil.dart';
import '../../../database/soporte_tecnico/database_helper_relevamiento.dart';
import '../../../database/soporte_tecnico/database_helper_verificaciones.dart';

class PrecargaControllerSop extends ChangeNotifier {

  String? _baseFotoPath;
  String? get baseFotoPath => _baseFotoPath;

  set baseFotoPath(String? path) {
    _baseFotoPath = path;
    notifyListeners();
  }

  // Controllers de balanza - PERSISTENTES para evitar memory leaks
  late final Map<String, TextEditingController> _balanzaControllers;

  // Tipo de Servicio
  String? _selectedTipoServicio;
  String? _selectedTipoServicioLabel;
  String? _tableName;

  String? get selectedTipoServicio => _selectedTipoServicio;
  String? get selectedTipoServicioLabel => _selectedTipoServicioLabel;
  String? get tableName => _tableName;

  // Estados del flujo
  int _currentStep = 0;
  bool _isDataSaved = false;
  String? _generatedSessionId;
  String? _generatedSeca;
  bool _secaConfirmed = false;

  // Validación por paso
  Map<int, String?> _stepErrors = {-1: null, 0: null, 1: null, 2: null, 3: null, 4: null};
  Map<int, String?> get stepErrors => _stepErrors;

  // Getters
  int get currentStep => _currentStep;
  bool get isDataSaved => _isDataSaved;
  String? get generatedSessionId => _generatedSessionId;
  String? get generatedSeca => _generatedSeca;
  bool get secaConfirmed => _secaConfirmed;

  // Datos del cliente
  List<dynamic>? _clientes;
  List<dynamic>? _filteredClientes;
  String? _selectedClienteId;
  String? _selectedClienteName;
  String? _selectedClienteRazonSocial;
  bool _isNewClient = false;

  // Getters cliente
  List<dynamic>? get clientes => _clientes;
  List<dynamic>? get filteredClientes => _filteredClientes;
  String? get selectedClienteId => _selectedClienteId;
  String? get selectedClienteName => _selectedClienteName;
  String? get selectedClienteRazonSocial => _selectedClienteRazonSocial;
  bool get isNewClient => _isNewClient;

  // Datos de la planta
  String? _selectedPlantaNombre;
  String? get selectedPlantaNombre => _selectedPlantaNombre;

  List<dynamic>? _plantas;
  String? _selectedPlantaKey;
  String? _selectedPlantaDir;
  String? _selectedPlantaDep;
  String? _selectedPlantaCodigo;

  // Getters planta
  List<dynamic>? get plantas => _plantas;
  String? get selectedPlantaKey => _selectedPlantaKey;
  String? get selectedPlantaDir => _selectedPlantaDir;
  String? get selectedPlantaDep => _selectedPlantaDep;
  String? get selectedPlantaCodigo => _selectedPlantaCodigo;

  // Datos de balanza
  List<Map<String, dynamic>> _balanzas = [];
  Map<String, dynamic>? _selectedBalanza;
  bool _isNewBalanza = false;

  // Getters balanza
  List<Map<String, dynamic>> get balanzas => _balanzas;
  Map<String, dynamic>? get selectedBalanza => _selectedBalanza;
  bool get isNewBalanza => _isNewBalanza;

  // Equipos
  List<dynamic> _equipos = [];
  List<Map<String, dynamic>> _selectedEquipos = [];
  List<Map<String, dynamic>> _selectedTermohigrometros = [];

  // Getters equipos
  List<dynamic> get equipos => _equipos;
  List<Map<String, dynamic>> get selectedEquipos => _selectedEquipos;
  List<Map<String, dynamic>> get selectedTermohigrometros => _selectedTermohigrometros;

  // Fotos
  final Map<String, List<File>> _balanzaPhotos = {};
  bool _fotosTomadas = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Getters fotos
  Map<String, List<File>> get balanzaPhotos => _balanzaPhotos;
  bool get fotosTomadas => _fotosTomadas;

  // Listas de opciones
  final List<String> unidadesPermitidas = ['mg', 'g', 'kg'];

  final List<String> marcasBalanzas = [
    'ACCULAB', 'AIV ELECTRONIC TECH', 'AIV-ELECTRONIC TECH', 'AND', 'ASPIRE',
    'AVERY', 'BALPER', 'CAMRY', 'CARDINAL', 'CAS', 'CAUDURO', 'CLEVER',
    'DAYANG', 'DIGITAL SCALE', 'DOLPHIN', 'ELECTRONIC SCALE', 'FAIRBANKS',
    'FAIRBANKS MORSE', 'AOSAI', 'FAMOCOL', 'FERTON', 'FILIZOLA', 'GRAM',
    'GRAM PRECISION', 'GSC', 'GUOMING', 'HBM', 'HIWEIGH', 'HOWE', 'INESA',
    'JADEVER', 'JM', 'KERN', 'KRETZ', 'LUTRANA', 'METTLER', 'METTLER TOLEDO',
    'MY WEIGH', 'OHAUS', 'PRECISA', 'PRECISION HISPANA', 'PT Ltd',
    'QUANTUM SCALES', 'RADWAG', 'RINSTRUM', 'SARTORIUS', 'SCIENTECH', 'SECA',
    'SHANGAI', 'SHIMADZU', 'SIPEL', 'STAVOL', 'SYMMETRY', 'SYSTEL', 'TOLEDO',
    'TOP BRAND', 'TOP INSTRUMENTS', 'TRANSCELL', 'TRINER', 'TRINNER SCALES',
    'WATERPROOF', 'WHITE BIRD', 'CONSTANT', 'JEWELLRY SCALE', 'YAOHUA', 'PRIX'
  ];

  final List<String> tiposEquipo = [
    'BALANZA', 'BALANZA ANALIZADORA DE HUMEDAD', 'BALANZA ANALÍTICA',
    'BALANZA MECÁNICA', 'BALANZA ELECTROMECÁNICA',
    'BALANZA ELECTRÓNICA DE DOBLE RANGO', 'BALANZA ELECTRÓNICA DE TRIPLE RANGO',
    'BALANZA ELECTRÓNICA DE DOBLE INTERVALO', 'BALANZA ELECTRÓNICA DE TRIPLE INTERVALO',
    'BALANZA SEMIMICROANALÍTICA', 'BALANZA MICROANALÍTICA',
    'BALANZA SEMIMICROANALÍTICA DE DOBLE RANGO', 'BALANZA SEMIMICROANALÍTICA DE TRIPLE RANGO', 'BALANZA ELECTRONICA',
  ];

  // MÉTODOS DE VALIDACIÓN
  String? validateStep(int step) {
    switch (step) {
      case -1: // Tipo de Servicio
        if (_selectedTipoServicio == null || _selectedTipoServicio!.isEmpty) {
          return 'Debe seleccionar un tipo de servicio';
        }
        return null;

      case 0: // Cliente
        if (_selectedClienteName == null || _selectedClienteName!.isEmpty) {
          return 'Debe seleccionar un cliente';
        }
        return null;

      case 1: // Planta
        if (_selectedPlantaCodigo == null || _selectedPlantaCodigo!.isEmpty) {
          return 'Debe seleccionar una planta';
        }
        if (_selectedPlantaDir == null || _selectedPlantaDir!.isEmpty) {
          return 'La dirección de planta es requerida';
        }
        if (_selectedPlantaDep == null || _selectedPlantaDep!.isEmpty) {
          return 'El departamento es requerido';
        }
        if (_selectedPlantaNombre == null || _selectedPlantaNombre!.isEmpty) {
          return 'El nombre de planta es requerido';
        }
        return null;

      case 2: // SECA
        if (!_secaConfirmed) {
          return 'Debe confirmar la OTST';
        }
        return null;

      case 3: // Balanza
        if (_selectedBalanza == null) {
          return 'Debe seleccionar una balanza';
        }
        return null;

      case 4: // Confirmación final
        for (int i = -1; i < 4; i++) {
          final error = validateStep(i);
          if (error != null) return 'Complete los pasos anteriores';
        }
        return null;

      default:
        return null;
    }
  }

  void updateStepErrors() {
    for (int i = -1; i <= _currentStep && i <= 4; i++) {
      _stepErrors[i] = validateStep(i);
    }
    notifyListeners();
  }

  bool canProceedToStep(int targetStep) {

    final error = validateStep(targetStep);
    return error == null;
  }

  // MÉTODOS DE NAVEGACIÓN
  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      updateStepErrors();
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > -1) {
      _currentStep--;
      updateStepErrors();
      notifyListeners();
    }
  }

  void goToStep(int step) {

    if (!canProceedToStep(step)) {
      debugPrint('No se puede saltar al paso $step: pasos anteriores incompletos');
      return;
    }

    _currentStep = step;
    updateStepErrors();
    notifyListeners();
  }

  void setCurrentStep(int step) {
    if (step >= -1 && step <= 4) {
      _currentStep = step;
      updateStepErrors();
      notifyListeners();
    }
  }

  dynamic _getDatabaseHelper() {
    if (_tableName == null) {
      throw Exception('No se ha seleccionado un tipo de servicio');
    }

    switch (_tableName) {
      case 'relevamiento_de_datos':
        return DatabaseHelperRelevamiento();
      case 'ajustes_metrologicos':
        return DatabaseHelperAjustes();
      case 'diagnostico':
        return DatabaseHelperDiagnostico();
      case 'mnt_prv_regular_stac':
        return DatabaseHelperMntPrvRegularStac();
      case 'mnt_prv_regular_stil':
        return DatabaseHelperMntPrvRegularStil();
      case 'mnt_prv_avanzado_stac':
        return DatabaseHelperMntPrvAvanzadoStac();
      case 'mnt_prv_avanzado_stil':
        return DatabaseHelperMntPrvAvanzadoStil();
      case 'mnt_correctivo':
        return DatabaseHelperMntCorrectivo();
      case 'instalacion':
        return DatabaseHelperInstalacion();
      case 'verificaciones_internas':
        return DatabaseHelperVerificaciones();
      default:
        throw Exception('Tipo de servicio no válido: $_tableName');
    }
  }

  void selectTipoServicio(String tipoServicio, String? subtipo) {
    _selectedTipoServicio = tipoServicio;

    // Determinar el nombre de la tabla
    _tableName = tipoServicio;

    // Crear label descriptivo
    String label = '';
    switch (tipoServicio) {
      case 'relevamiento_de_datos':
        label = 'Relevamiento de Datos';
        break;
      case 'ajustes_metrologicos':
        label = 'Ajustes Metrológicos';
        break;
      case 'diagnostico':
        label = 'Diagnóstico';
        break;
      case 'mnt_prv_regular_stac':
        label = 'Mantenimiento Preventivo Regular - STAC';
        break;
      case 'mnt_prv_regular_stil':
        label = 'Mantenimiento Preventivo Regular - STIL';
        break;
      case 'mnt_prv_avanzado_stac':
        label = 'Mantenimiento Preventivo Avanzado - STAC';
        break;
      case 'mnt_prv_avanzado_stil':
        label = 'Mantenimiento Preventivo Avanzado - STIL';
        break;
      case 'mnt_correctivo':
        label = 'Mantenimiento Correctivo';
        break;
      case 'instalacion':
        label = 'Instalación';
        break;
      case 'verificaciones_internas':
        label = 'Verificaciones Internas';
        break;
      default:
        label = tipoServicio;
    }

    _selectedTipoServicioLabel = label;
    updateStepErrors();
    notifyListeners();
  }

  void setInternalValues({
    required String sessionId,
    required String seca,
    String? clienteName,
    String? clienteRazonSocial,
    String? plantaDir,
    String? plantaDep,
    String? plantaCodigo,
    String? plantaNombre,
  }) {
    _generatedSessionId = sessionId;
    _generatedSeca = seca;
    _secaConfirmed = true;

    if (clienteName != null) _selectedClienteName = clienteName;
    if (clienteRazonSocial != null) _selectedClienteRazonSocial = clienteRazonSocial;
    if (plantaDir != null) _selectedPlantaDir = plantaDir;
    if (plantaDep != null) _selectedPlantaDep = plantaDep;
    if (plantaNombre != null) _selectedPlantaNombre = plantaNombre;
    if (plantaCodigo != null) {
      _selectedPlantaCodigo = plantaCodigo;
      fetchBalanzas(plantaCodigo);
    }

    updateStepErrors();
    notifyListeners();
  }

  Future<void> addNewPlanta({
    required String nombrePlanta,
    required String direccion,
    required String departamento,
    required String codigo,
  }) async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      final plantaId = DateTime.now().millisecondsSinceEpoch.toString();
      final depId = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('plantas', {
        'cliente_id': _selectedClienteId,
        'planta_id': plantaId,
        'dep_id': depId,
        'planta': nombrePlanta,
        'dir': direccion,
        'dep': departamento,
        'codigo_planta': codigo,
      });

      await db.close();

      await fetchPlantas(_selectedClienteId!);

      final uniqueKey = '${plantaId}_${depId}';
      selectPlanta(uniqueKey);

      notifyListeners();
    } catch (e) {
      throw Exception('Error al agregar planta: $e');
    }
  }

  // MÉTODOS DE CLIENTE
  Future<void> fetchClientes() async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);
      final List<Map<String, dynamic>> clientesList = await db.query('clientes');

      _clientes = clientesList;
      _filteredClientes = clientesList;
      await db.close();
      notifyListeners();
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  void filterClientes(String query) {
    final queryLower = query.toLowerCase();
    _filteredClientes = _clientes?.where((cliente) {
      final clienteName = cliente['cliente']?.toLowerCase() ?? '';
      return clienteName.contains(queryLower);
    }).toList();
    notifyListeners();
  }

  void selectClientFromList(Map<String, dynamic> cliente) {
    _isNewClient = false;
    _selectedClienteId = cliente['cliente_id']?.toString() ?? '';
    _selectedClienteName = cliente['cliente']?.toString() ?? '';
    _selectedClienteRazonSocial = cliente['razonsocial']?.toString() ?? '';
    updateStepErrors();
    notifyListeners();

    fetchPlantas(_selectedClienteId!);
  }

  void selectNewClient(String nombreComercial, String razonSocial) {
    _isNewClient = true;
    _selectedClienteName = nombreComercial;
    _selectedClienteRazonSocial = razonSocial;
    _selectedClienteId = null;
    _plantas = null;
    updateStepErrors();
    notifyListeners();
  }

  void clearClientSelection() {
    _selectedClienteId = null;
    _selectedClienteName = null;
    _selectedClienteRazonSocial = null;
    _isNewClient = false;
    _plantas = null;
    _selectedPlantaKey = null;
    updateStepErrors();
    notifyListeners();
  }

  // MÉTODOS DE PLANTA
  Future<void> fetchPlantas(String clienteId) async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      final List<Map<String, dynamic>> plantasList = await db.query(
        'plantas',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
      );

      final plantasModificadas = plantasList.map((planta) {
        return {
          ...planta,
          'unique_key': '${planta['planta_id']}_${planta['dep_id']}',
        };
      }).toList();

      _plantas = plantasModificadas;
      await db.close();
      notifyListeners();
    } catch (e) {
      throw Exception('Error al cargar plantas: $e');
    }
  }

  void selectPlanta(String uniqueKey) {
    final selectedPlanta = _plantas!.firstWhere(
          (planta) => planta['unique_key'] == uniqueKey,
      orElse: () => <String, dynamic>{},
    );

    _selectedPlantaKey = uniqueKey;
    _selectedPlantaNombre = selectedPlanta['planta']?.toString() ?? '';
    _selectedPlantaDir = selectedPlanta['dir']?.toString() ?? '';
    _selectedPlantaDep = selectedPlanta['dep']?.toString() ?? '';
    _selectedPlantaCodigo = selectedPlanta['codigo_planta']?.toString() ?? '';

    generateSugestedSeca();
    updateStepErrors();
    notifyListeners();
  }

  void setPlantaManualData({
    required String direccion,
    required String departamento,
    required String codigo,
    String? nombrePlanta,
  }) {
    _selectedPlantaDir = direccion;
    _selectedPlantaDep = departamento;
    _selectedPlantaCodigo = codigo;
    _selectedPlantaNombre = nombrePlanta ?? 'Planta sin nombre';

    generateSugestedSeca();
    updateStepErrors();
    notifyListeners();
  }

  // MÉTODOS DE SECA
  void generateSugestedSeca() {
    if (_selectedPlantaCodigo != null && _selectedPlantaCodigo!.isNotEmpty) {
      final now = DateTime.now();
      final year = now.year.toString().substring(2);

      // Solo generar si NO existe un SECA o si NO está confirmado
      if (_generatedSeca == null || !_secaConfirmed) {
        _generatedSeca = '$year-$_selectedPlantaCodigo-S01';
        notifyListeners();
      }
    }
  }

  void updateNumeroCotizacion(String nuevoNumero) {
    if (nuevoNumero.isEmpty) {
      return; // No hacer nada si está vacío
    }

    final regex = RegExp(r'^S\d{2}$');
    if (!regex.hasMatch(nuevoNumero)) {
      throw Exception('Formato inválido. Use S01 a S99');
    }

    if (_generatedSeca != null) {
      final partes = _generatedSeca!.split('-');

      // Si tiene 3 partes (año-planta-C01), reemplazar la última
      if (partes.length == 3) {
        partes[2] = nuevoNumero;
        _generatedSeca = partes.join('-');
      }
      // Si tiene 4 partes (año-planta-algo-C01), reemplazar la última
      else if (partes.length == 4) {
        partes[3] = nuevoNumero;
        _generatedSeca = partes.join('-');
      }

      notifyListeners();
    }
  }

  Future<void> confirmSeca(String userName, String fechaServicio) async {
    if (_generatedSeca == null) throw Exception('No hay OTST generado');
    if (_tableName == null) throw Exception('No se ha seleccionado tipo de servicio');

    try {

      final dbHelper = _getDatabaseHelper();

      // Verificar si ya existe registro con este SECA
      final secaExiste = await dbHelper.metricaExists(_generatedSeca!);

      if (secaExiste) {
        final ultimoRegistro = await dbHelper.getUltimoRegistroPorMetrica(_generatedSeca!);
        throw SecaExistsException(ultimoRegistro?['fecha_servicio'] ?? 'N/A');
      } else {
        await createNewSecaSession(userName, fechaServicio);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createNewSecaSession(String userName, String fechaServicio) async {
    try {
      if (_tableName == null) {
        throw Exception('No se ha seleccionado un tipo de servicio');
      }


      final dbHelper = _getDatabaseHelper();

      // Generar session_id específico
      _generatedSessionId = await _generateSessionIdSop(_generatedSeca!);

      // Preparar registro base
      final registro = {
        'session_id': _generatedSessionId!,
        'tipo_servicio': _selectedTipoServicioLabel ?? _selectedTipoServicio,
        'otst': _generatedSeca!,
        'fecha_servicio': fechaServicio,
        'personal': userName,
        'cliente': _selectedClienteName ?? 'No especificado',
        'razon_social': _selectedClienteRazonSocial ?? 'No especificado',
        'planta': _selectedPlantaNombre ?? 'No especificado',
        'dir_planta': _selectedPlantaDir ?? 'No especificado',
        'dep_planta': _selectedPlantaDep ?? 'No especificado',
        'cod_planta': _selectedPlantaCodigo ?? 'No especificado',
        'cod_metrica': '',
      };


      await dbHelper.upsertRegistro(registro);

      _secaConfirmed = true;
      updateStepErrors();
      notifyListeners();

      // Cargar balanzas después de confirmar SECA
      if (_selectedPlantaCodigo != null) {
        await fetchBalanzas(_selectedPlantaCodigo!);
      }
    } catch (e) {
      throw Exception('Error al crear sesión: $e');
    }
  }

  Future<String> _generateSessionIdSop(String codMetrica) async {
    try {
      if (_tableName == null) {
        throw Exception('No se ha seleccionado un tipo de servicio');
      }


      final dbHelper = _getDatabaseHelper();
      return await dbHelper.generateSessionId(codMetrica);
    } catch (e) {
      throw Exception('Error al generar sessionId: $e');
    }
  }

  // MÉTODOS DE BALANZA
  Future<void> fetchBalanzas(String plantaCodigo) async {
    try {

      if (_tableName == null) {
        debugPrint('⚠️ No se puede buscar balanzas sin tipo de servicio seleccionado');
        _balanzas = [];
        notifyListeners();
        return;
      }

      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      final List<Map<String, dynamic>> balanzasList = await db.query(
        'balanzas',
        where: 'cod_metrica LIKE ?',
        whereArgs: ['$plantaCodigo%'],
      );

      List<Map<String, dynamic>> processedBalanzas = [];

      for (var balanza in balanzasList) {
        final codMetrica = balanza['cod_metrica'].toString();

        final List<Map<String, dynamic>> infDetails = await db.query(
          'inf',
          where: 'cod_metrica = ?',
          whereArgs: [codMetrica],
        );


        final estadoCalibacion = await _verificarEstadoCalibacion(codMetrica);

        Map<String, dynamic> balanzaCompleta = {
          ...balanza,
          'estado_calibracion': estadoCalibacion['estado'],
          'tiene_registro': estadoCalibacion['tiene_registro'],
        };

        if (infDetails.isNotEmpty) {
          balanzaCompleta = {
            ...balanzaCompleta,
            ...infDetails.first,
          };
        }

        processedBalanzas.add(balanzaCompleta);
      }

      _balanzas = processedBalanzas;
      await db.close();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar balanzas: $e');
      throw Exception('Error al cargar balanzas: $e');
    }
  }

  Future<Map<String, dynamic>> _verificarEstadoCalibacion(String codMetrica) async {
    try {

      if (_tableName == null || _tableName!.isEmpty) {
        return {'estado': 'sin_tabla', 'tiene_registro': false};
      }


      final dbHelper = _getDatabaseHelper();
      final db = await dbHelper.database;

      // Buscar en la tabla independiente
      final List<Map<String, dynamic>> registros = await db.query(
        dbHelper.tableName, // Usar el nombre de tabla del helper
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
        orderBy: 'fecha_servicio DESC',
        limit: 1,
      );

      if (registros.isEmpty) {
        return {'estado': 'sin_registro', 'tiene_registro': false};
      }

      // Verificar el estado del servicio
      final estadoServicio = registros.first['estado_servicio_bal']?.toString() ?? '';

      if (estadoServicio == 'Balanza Calibrada') {
        return {'estado': 'calibrada', 'tiene_registro': true};
      } else {
        return {'estado': 'no_calibrada', 'tiene_registro': true};
      }
    } catch (e) {
      debugPrint('Error al verificar estado de calibración: $e');
      return {'estado': 'error', 'tiene_registro': false};
    }
  }

  void selectBalanza(Map<String, dynamic> balanza) {
    _selectedBalanza = balanza;
    _isNewBalanza = false;
    updateStepErrors();
    notifyListeners();
  }

  void createNewBalanza() {
    final now = DateTime.now();
    final formattedDateTime =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    _isNewBalanza = true;
    _selectedBalanza = {
      'cod_metrica': '$_selectedPlantaCodigo-$formattedDateTime',
    };
    notifyListeners();
  }

  Future<void> takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _balanzaPhotos['identificacion'] ??= [];

      if (_balanzaPhotos['identificacion']!.length < 5) {
        try {
          // Guardar directamente en memoria, sin carpeta previa
          _balanzaPhotos['identificacion']!.add(File(photo.path));
          _fotosTomadas = true;
          notifyListeners();
        } catch (e) {
          throw Exception('Error al procesar foto: $e');
        }
      }
    }
  }

  void removePhoto(File photo) {
    try {
      _balanzaPhotos['identificacion']?.remove(photo);

      if (_balanzaPhotos['identificacion']?.isEmpty ?? true) {
        _fotosTomadas = false;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Error al eliminar foto: $e');
    }
  }

  Future<List<File>> getGuardedasPhotos() async {
    try {
      if (_baseFotoPath == null) return [];

      final folder = Directory(_baseFotoPath!);
      if (!await folder.exists()) return [];

      final files = folder.listSync();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      throw Exception('Error al listar fotos: $e');
    }
  }

  String? getFotoDirectoryPath() {
    return _baseFotoPath;
  }

  Future<String?> createPhotosZip() async {
    try {
      final photos = _balanzaPhotos['identificacion'] ?? [];
      if (photos.isEmpty) {
        throw Exception('No hay fotos para comprimir');
      }

      // Permitir al usuario seleccionar ubicación para el ZIP
      final String? zipPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar ubicación para guardar ZIP de fotos',
      );

      if (zipPath == null) {
        return null; // Usuario canceló
      }

      // Crear nombre del ZIP
      final zipFileName =
          '${_selectedBalanza?['cod_metrica']}_fotos_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFilePath = join(zipPath, zipFileName);

      // Crear archivo ZIP
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      // Agregar fotos al ZIP
      for (var photo in photos) {
        await encoder.addFile(photo);
      }

      encoder.close();

      return zipFilePath;
    } catch (e) {
      throw Exception('Error al crear ZIP: $e');
    }
  }

  // GUARDADO FINAL
  Future<void> saveAllData({
    required String userName,
    required String fechaServicio,
    required String nReca,
    required String sticker,
    required Map<String, String> balanzaData,
  }) async {
    try {
      if (_tableName == null) {
        throw Exception('No se ha seleccionado un tipo de servicio');
      }

      final dbHelper = _getDatabaseHelper();

      final registro = {
        'session_id': _generatedSessionId!,
        'tipo_servicio': _selectedTipoServicioLabel ?? _selectedTipoServicio,
        'otst': _generatedSeca!,
        'fecha_servicio': fechaServicio,
        'personal': userName,
        'cliente': _selectedClienteName ?? 'No especificado',
        'razon_social': _selectedClienteRazonSocial ?? 'No especificado',
        'planta': _selectedPlantaNombre ?? 'No especificado',
        'dir_planta': _selectedPlantaDir ?? 'No especificado',
        'dep_planta': _selectedPlantaDep ?? 'No especificado',
        'cod_planta': _selectedPlantaCodigo ?? '',
        'foto_balanza': _fotosTomadas ? '1' : '0',
        ...balanzaData,
      };

      await dbHelper.upsertRegistro(registro);

      _isDataSaved = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Error al guardar datos: $e');
    }
  }

  // UTILIDADES
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void reset() {
    _currentStep = -1;
    _isDataSaved = false;
    _generatedSessionId = null;
    _generatedSeca = null;
    _secaConfirmed = false;

    _clientes = null;
    _filteredClientes = null;
    _selectedClienteId = null;
    _selectedClienteName = null;
    _selectedClienteRazonSocial = null;
    _isNewClient = false;

    _plantas = null;
    _selectedPlantaKey = null;
    _selectedPlantaDir = null;
    _selectedPlantaDep = null;
    _selectedPlantaCodigo = null;
    _selectedPlantaNombre = null;

    _balanzas = [];
    _selectedBalanza = null;
    _isNewBalanza = false;

    _equipos = [];
    _selectedEquipos = [];
    _selectedTermohigrometros = [];

    _balanzaPhotos.clear();
    _fotosTomadas = false;
    _baseFotoPath = null;

    _stepErrors = {-1: null, 0: null, 1: null, 2: null, 3: null, 4: null};

    _selectedTipoServicio = null;
    _selectedTipoServicioLabel = null;
    _tableName = null;

    notifyListeners();
  }
}

// Excepción personalizada para SECA existente
class SecaExistsException implements Exception {
  final String fechaUltimoServicio;

  SecaExistsException(this.fechaUltimoServicio);

  @override
  String toString() => 'OTST ya existe. Último servicio: $fechaUltimoServicio';
}