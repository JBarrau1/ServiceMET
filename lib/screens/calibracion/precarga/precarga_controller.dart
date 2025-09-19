// precarga_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import '../../../database/app_database.dart';

class PrecargaController extends ChangeNotifier {
  // Estados del flujo
  int _currentStep = 0;
  bool _isDataSaved = false;
  String? _generatedSessionId;
  String? _generatedSeca;
  bool _secaConfirmed = false;

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
    'BALANZA ELECTRÓNICA DE DOBLE INTÉRVALO', 'BALANZA ELECTRÓNICA DE TRIPLE INTÉRVALO',
    'BALANZA SEMIMICROANALÍTICA', 'BALANZA MICROANALÍTICA',
    'BALANZA SEMIMICROANALÍTICA DE DOBLE RANGO', 'BALANZA SEMIMICROANALÍTICA DE TRIPLE RANGO', 'BALANZA ELECTRONICA',
  ];

  // MÉTODOS DE NAVEGACIÓN
  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
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
    notifyListeners();

    fetchPlantas(_selectedClienteId!);
    // AGREGAR ESTA LÍNEA:
    fetchEquipos(); // Cargar equipos inmediatamente para selección temprana
  }

  void selectNewClient(String nombreComercial, String razonSocial) {
    _isNewClient = true;
    _selectedClienteName = nombreComercial;
    _selectedClienteRazonSocial = razonSocial;
    _selectedClienteId = null;
    _plantas = null;
    notifyListeners();
  }

  void clearClientSelection() {
    _selectedClienteId = null;
    _selectedClienteName = null;
    _selectedClienteRazonSocial = null;
    _isNewClient = false;
    _plantas = null;
    _selectedPlantaKey = null;
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
    _selectedPlantaDir = selectedPlanta['dir']?.toString() ?? '';
    _selectedPlantaDep = selectedPlanta['dep']?.toString() ?? '';
    _selectedPlantaCodigo = selectedPlanta['codigo_planta']?.toString() ?? '';

    generateSugestedSeca();
    notifyListeners();
  }

  void setPlantaManualData(String direccion, String departamento, String codigo) {
    _selectedPlantaDir = direccion;
    _selectedPlantaDep = departamento;
    _selectedPlantaCodigo = codigo;

    generateSugestedSeca();
    notifyListeners();
  }

  // MÉTODOS DE SECA
  void generateSugestedSeca() {
    if (_selectedPlantaCodigo != null && _selectedPlantaCodigo!.isNotEmpty) {
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      _generatedSeca = '$year-$_selectedPlantaCodigo-C01';
      notifyListeners();
    }
  }

  void updateNumeroCotizacion(String nuevoNumero) {
    if (_generatedSeca != null && nuevoNumero.isNotEmpty) {
      // Validar formato C + número (01-99)
      final regex = RegExp(r'^C\d{2}$');
      if (!regex.hasMatch(nuevoNumero)) {
        throw Exception('Formato inválido. Use C01 a C99');
      }

      // Mantener las partes fijas y cambiar solo el número de cotización
      final partes = _generatedSeca!.split('-');
      if (partes.length == 4) {
        partes[3] = nuevoNumero; // Reemplazar la última parte (C01)
        _generatedSeca = partes.join('-');
        notifyListeners();
      }
    }
  }

  Future<void> confirmSeca(String userName, String fechaServicio) async {
    if (_generatedSeca == null) throw Exception('No hay SECA generado');

    try {
      final dbHelper = AppDatabase();

      // Verificar si el SECA ya existe
      final secaExiste = await dbHelper.secaExists(_generatedSeca!);

      if (secaExiste) {
        final ultimoRegistro = await dbHelper.getUltimoRegistroPorSeca(_generatedSeca!);
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
      final dbHelper = AppDatabase();
      _generatedSessionId = await dbHelper.generateSessionId(_generatedSeca!);

      await dbHelper.upsertRegistroCalibracion({
        'seca': _generatedSeca!,
        'fecha_servicio': fechaServicio,
        'personal': userName,
        'session_id': _generatedSessionId!,
        'cliente': _selectedClienteName ?? 'No especificado',
        'razon_social': _selectedClienteRazonSocial ?? 'No especificado',
        'planta': _selectedClienteName ?? 'No especificado',
        'dir_planta': _selectedPlantaDir ?? 'No especificado',
        'dep_planta': _selectedPlantaDep ?? 'No especificado',
        'cod_planta': _selectedPlantaCodigo ?? 'No especificado',
      });

      _secaConfirmed = true;
      notifyListeners();

      // Cargar balanzas después de confirmar SECA
      await fetchBalanzas(_selectedPlantaCodigo!);
    } catch (e) {
      throw Exception('Error al crear sesión: $e');
    }
  }

  // MÉTODOS DE BALANZA
  Future<void> fetchBalanzas(String plantaCodigo) async {
    try {
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

        // Consultar la tabla 'inf' para obtener detalles adicionales
        final List<Map<String, dynamic>> infDetails = await db.query(
          'inf',
          where: 'cod_metrica = ?',
          whereArgs: [codMetrica],
        );

        if (infDetails.isNotEmpty) {
          processedBalanzas.add({
            ...balanza,
            ...infDetails.first,
          });
        } else {
          processedBalanzas.add(balanza);
        }
      }

      _balanzas = processedBalanzas;
      await db.close();
      notifyListeners();
    } catch (e) {
      throw Exception('Error al cargar balanzas: $e');
    }
  }

  void selectBalanza(Map<String, dynamic> balanza) {
    _selectedBalanza = balanza;
    _isNewBalanza = false;
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

  // MÉTODOS DE EQUIPOS
  Future<void> fetchEquipos() async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      final List<Map<String, dynamic>> equiposList = await db.query(
        'equipamientos',
        where: "estado != 'DESACTIVADO'",
      );

      _equipos = equiposList;
      await db.close();
      notifyListeners();
    } catch (e) {
      throw Exception('Error al cargar equipos: $e');
    }
  }

  void addEquipo(Map<String, dynamic> equipo, String tipo, String cantidad) {
    final equipoWithType = {
      ...equipo,
      'tipo': tipo,
      'cantidad': cantidad,
    };

    if (tipo == 'pesa') {
      if (_selectedEquipos.length < 5) {
        _selectedEquipos.add(equipoWithType);
      }
    } else if (tipo == 'termohigrometro') {
      if (_selectedTermohigrometros.length < 2) {
        _selectedTermohigrometros.add(equipoWithType);
      }
    }

    notifyListeners();
  }

  void removeEquipo(String codInstrumento, String tipo) {
    if (tipo == 'pesa') {
      _selectedEquipos.removeWhere((e) =>
      e['cod_instrumento'] == codInstrumento && e['tipo'] == tipo);
    } else if (tipo == 'termohigrometro') {
      _selectedTermohigrometros.removeWhere((e) =>
      e['cod_instrumento'] == codInstrumento && e['tipo'] == tipo);
    }

    notifyListeners();
  }

  void updateEquipoCantidad(String codInstrumento, String tipo, String cantidad) {
    List<Map<String, dynamic>> targetList = tipo == 'pesa'
        ? _selectedEquipos
        : _selectedTermohigrometros;

    for (var equipo in targetList) {
      if (equipo['cod_instrumento'] == codInstrumento && equipo['tipo'] == tipo) {
        equipo['cantidad'] = cantidad;
        break;
      }
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> getAllSelectedEquipos() {
    return [..._selectedEquipos, ..._selectedTermohigrometros];
  }

  // MÉTODOS DE FOTOS
  Future<void> takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _balanzaPhotos['identificacion'] ??= [];
      if (_balanzaPhotos['identificacion']!.length < 5) {
        _balanzaPhotos['identificacion']!.add(File(photo.path));
        _fotosTomadas = true;
        notifyListeners();
      }
    }
  }

  void removePhoto(File photo) {
    _balanzaPhotos['identificacion']?.remove(photo);
    if (_balanzaPhotos['identificacion']?.isEmpty ?? true) {
      _fotosTomadas = false;
    }
    notifyListeners();
  }

  // MÉTODOS DE VALIDACIÓN
  bool validateStep(int step) {
    switch (step) {
      case 0: // Cliente
        return _selectedClienteName != null;
      case 1: // Planta
        return _selectedPlantaCodigo != null;
      case 2: // SECA
        return _secaConfirmed;
      case 3: // Balanza
        return _selectedBalanza != null;
      case 4: // Equipos
        return _selectedEquipos.isNotEmpty || _selectedTermohigrometros.isNotEmpty;
      default:
        return false;
    }
  }

  bool canProceedToNextStep() {
    return validateStep(_currentStep);
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
      final dbHelper = AppDatabase();

      final registro = {
        'seca': _generatedSeca!,
        'session_id': _generatedSessionId!,
        'personal': userName,
        'fecha_servicio': fechaServicio,
        'cliente': _selectedClienteName ?? 'No especificado',
        'razon_social': _selectedClienteRazonSocial ?? 'No especificado',
        'planta': _selectedClienteName ?? 'No especificado',
        'dir_planta': _selectedPlantaDir ?? 'No especificado',
        'dep_planta': _selectedPlantaDep ?? 'No especificado',
        'cod_planta': _selectedPlantaCodigo ?? 'No especificado',
        'foto_balanza': _fotosTomadas ? 1 : 0,
        'n_reca': nReca,
        'sticker': sticker,
        ...balanzaData,
      };

      // Agregar equipos seleccionados
      final allEquipos = getAllSelectedEquipos();
      for (int i = 0; i < allEquipos.length && i < 10; i++) {
        final equipo = allEquipos[i];
        registro['equipo${i + 1}'] = equipo['cod_instrumento']?.toString() ?? '';
        registro['certificado${i + 1}'] = equipo['cert_fecha']?.toString() ?? '';
        registro['ente_calibrador${i + 1}'] = equipo['ente_calibrador']?.toString() ?? '';
        registro['estado${i + 1}'] = equipo['estado']?.toString() ?? '';
        registro['cantidad${i + 1}'] = equipo['cantidad']?.toString() ?? '1';
      }

      await dbHelper.upsertRegistroCalibracion(registro);

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
    _currentStep = 0;
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

    _balanzas = [];
    _selectedBalanza = null;
    _isNewBalanza = false;

    _equipos = [];
    _selectedEquipos = [];
    _selectedTermohigrometros = [];

    _balanzaPhotos.clear();
    _fotosTomadas = false;

    notifyListeners();
  }
}

// Excepción personalizada para SECA existente
class SecaExistsException implements Exception {
  final String fechaUltimoServicio;

  SecaExistsException(this.fechaUltimoServicio);

  @override
  String toString() => 'SECA ya existe. Último servicio: $fechaUltimoServicio';
}