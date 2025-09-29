// servicio_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';

import '../../../database/app_database.dart';

class ServicioController extends ChangeNotifier {
  // Parámetros del servicio
  final String dbName;
  final String secaValue;
  final String codMetrica;
  final String nReca;
  final String sessionId;

  ServicioController({
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
    required this.nReca,
    required this.sessionId,
  });

  final AppDatabase _dbHelper = AppDatabase();

  // Estados del flujo
  int _currentStep = 0;
  bool _isDataSaved = false;

  // Getters
  int get currentStep => _currentStep;
  bool get isDataSaved => _isDataSaved;

  // Método getCurrentTime
  String getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // Datos de condiciones iniciales
  String? _horaInicio;
  String? _tiempoEstabilizacion;
  String? _tiempoBalanza;
  final Map<String, dynamic> _condicionesEntorno = {};
  final Map<String, List<File>> _condicionesPhotos = {};
  bool _condicionesPhotosTomadas = false;

  // Getters condiciones iniciales
  String? get horaInicio => _horaInicio;
  String? get tiempoEstabilizacion => _tiempoEstabilizacion;
  String? get tiempoBalanza => _tiempoBalanza;
  Map<String, dynamic> get condicionesEntorno => _condicionesEntorno;
  Map<String, List<File>> get condicionesPhotos => _condicionesPhotos;
  bool get condicionesPhotosTomadas => _condicionesPhotosTomadas;

  // Datos de precargas
  final List<Map<String, String>> _precargas = [];
  final Map<String, String> _ajusteData = {};
  final Map<String, String> _condicionesAmbientales = {};

  // Getters precargas
  List<Map<String, String>> get precargas => _precargas;
  Map<String, String> get ajusteData => _ajusteData;
  Map<String, String> get condicionesAmbientales => _condicionesAmbientales;

  // Datos de excentricidad
  String? _selectedPlataforma;
  String? _selectedOpcionExcentricidad;
  String? _cargaExcentricidad;
  final List<Map<String, String>> _posicionesExcentricidad = [];

  // Getters excentricidad
  String? get selectedPlataforma => _selectedPlataforma;
  String? get selectedOpcionExcentricidad => _selectedOpcionExcentricidad;
  String? get cargaExcentricidad => _cargaExcentricidad;
  List<Map<String, String>> get posicionesExcentricidad => _posicionesExcentricidad;

  // Datos de repetibilidad
  int _selectedRepetibilityCount = 3;
  int _selectedRowCount = 3;
  final List<List<Map<String, String>>> _repetibilidadData = [];

  // Getters repetibilidad
  int get selectedRepetibilityCount => _selectedRepetibilityCount;
  int get selectedRowCount => _selectedRowCount;
  List<List<Map<String, String>>> get repetibilidadData => _repetibilidadData;

  // Datos de linealidad
  String? _selectedMetodoLinealidad;
  String? _selectedMetodoCarga;
  final List<Map<String, String>> _linealidadRows = [];

  // Getters linealidad
  String? get selectedMetodoLinealidad => _selectedMetodoLinealidad;
  String? get selectedMetodoCarga => _selectedMetodoCarga;
  List<Map<String, String>> get linealidadRows => _linealidadRows;

  // Datos de condiciones finales
  final Map<String, String> _condicionesFinales = {};
  final Map<String, List<File>> _condicionesFinalesPhotos = {};
  bool _condicionesFinalesPhotosTomadas = false;

  // Getters condiciones finales
  Map<String, String> get condicionesFinales => _condicionesFinales;
  Map<String, List<File>> get condicionesFinalesPhotos => _condicionesFinalesPhotos;
  bool get condicionesFinalesPhotosTomadas => _condicionesFinalesPhotosTomadas;

  // Setter para condicionesFinalesPhotosTomadas
  set condicionesFinalesPhotosTomadas(bool value) {
    _condicionesFinalesPhotosTomadas = value;
    notifyListeners();
  }

  // Servicios
  final ImagePicker _imagePicker = ImagePicker();

  // Listas de opciones para dropdowns
  final List<String> tiemposOptions = [
    'Mayor a 15 minutos',
    'Mayor a 30 minutos'
  ];

  final Map<String, List<String>> entornoOptions = {
    'Vibración': ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
    'Polvo': ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
    'Temperatura': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Humedad': ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
    'Mesada': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Iluminación': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Limpieza de Fosa': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Estado de Drenaje': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Limpieza General': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Golpes al Terminal': ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica'],
    'Nivelación': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
    'Limpieza Receptor': ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
    'Golpes al receptor de Carga': [
      'Sin Daños',
      'Daños Leves',
      'Dañado',
      'No aplica'
    ],
    'Encendido': ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
  };

  final Map<String, List<String>> plataformaOptions = {
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

  final List<String> metodosLinealidad = [
    'Ascenso evaluando ceros',
    'Ascenso contínuo por pasos'
  ];

  final List<String> metodoCargaOptions = ['Método 1', 'Método 2'];

  // Inicialización
  Future<void> initializeServicio() async {
    try {
      _tiempoEstabilizacion = null; // Dejar vacío
      _tiempoBalanza = null; // Dejar vacío

      // Inicializar precargas por defecto (5 precargas)
      for (int i = 0; i < 5; i++) {
        _precargas.add({
          'precarga': '',
          'indicacion': '',
        });
      }

      // Inicializar repetibilidad por defecto
      _initializeRepetibilidadData();

      // Inicializar linealidad por defecto (6 filas)
      for (int i = 0; i < 6; i++) {
        _linealidadRows.add({
          'lt': '',
          'indicacion': '',
          'retorno': '0',
          'difference': '',
        });
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Error al inicializar servicio: $e');
    }
  }

  void restoreInitialCondiciones(Map<String, String> initialValues) {
    _condicionesEntorno.clear();
    _condicionesEntorno.addAll(initialValues);
    notifyListeners();
  }

  void _initializeRepetibilidadData() {
    _repetibilidadData.clear();
    for (int carga = 0; carga < _selectedRepetibilityCount; carga++) {
      List<Map<String, String>> cargaData = [];
      for (int fila = 0; fila < _selectedRowCount; fila++) {
        cargaData.add({
          'indicacion': '',
          'retorno': '0',
        });
      }
      _repetibilidadData.add(cargaData);
    }
  }

  // Navegación entre pasos
  void nextStep() {
    if (_currentStep < 5 && validateCurrentStep()) {
      _currentStep++;
      _isDataSaved = false;
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
    if (step >= 0 && step <= 5) {
      _currentStep = step;
      _isDataSaved = false;
      notifyListeners();
    }
  }

  // Validaciones por paso
  bool validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateCondicionesIniciales();
      case 1:
        return _validatePrecargas();
      case 2:
        return _validateExcentricidad();
      case 3:
        return _validateRepetibilidad();
      case 4:
        return _validateLinealidad();
      case 5:
        return _validateCondicionesFinales();
      default:
        return false;
    }
  }

  bool _validateCondicionesIniciales() {
    return _horaInicio != null &&
        _tiempoEstabilizacion != null &&
        _tiempoBalanza != null &&
        _condicionesEntorno.isNotEmpty;
  }

  bool _validatePrecargas() {
    return _precargas.any(
            (p) => p['precarga']!.isNotEmpty && p['indicacion']!.isNotEmpty) &&
        _ajusteData.isNotEmpty &&
        _condicionesAmbientales.isNotEmpty;
  }

  bool _validateExcentricidad() {
    return _selectedPlataforma != null &&
        _selectedOpcionExcentricidad != null &&
        _cargaExcentricidad != null &&
        _posicionesExcentricidad.isNotEmpty;
  }

  bool _validateRepetibilidad() {
    return _repetibilidadData.isNotEmpty &&
        _repetibilidadData.every((carga) => carga.every((fila) =>
            fila['indicacion']!.isNotEmpty && fila['retorno']!.isNotEmpty));
  }

  bool _validateLinealidad() {
    return _selectedMetodoLinealidad != null &&
        _linealidadRows.any(
            (row) => row['lt']!.isNotEmpty && row['indicacion']!.isNotEmpty);
  }

  bool _validateCondicionesFinales() {
    return _condicionesFinales.isNotEmpty;
  }

  void setDataSaved(bool value) {
    _isDataSaved = value;
    notifyListeners();
  }

  // Métodos para condiciones iniciales
  void setHoraInicio(String hora) {
    _horaInicio = hora;
    notifyListeners(); // IMPORTANTE: notificar cambios
  }

  void setTiempoEstabilizacion(String tiempo) {
    _tiempoEstabilizacion = tiempo;
    notifyListeners();
  }

  void setTiempoBalanza(String tiempo) {
    _tiempoBalanza = tiempo;
    notifyListeners();
  }

  void setCondicionEntorno(String key, String value) {
    _condicionesEntorno[key] = value;
    notifyListeners();
  }

  void setAllCondicionesToGood() {
    final goodValues = {
      'Vibración': 'Inexistente',
      'Polvo': 'Inexistente',
      'Temperatura': 'Bueno',
      'Humedad': 'Inexistente',
      'Mesada': 'Bueno',
      'Iluminación': 'Bueno',
      'Limpieza de Fosa': 'Bueno',
      'Estado de Drenaje': 'Bueno',
      'Limpieza General': 'Bueno',
      'Golpes al Terminal': 'Sin Daños',
      'Nivelación': 'Bueno',
      'Limpieza Receptor': 'Inexistente',
      'Golpes al receptor de Carga': 'Sin Daños',
      'Encendido': 'Bueno',
    };

    _condicionesEntorno.addAll(goodValues);
    notifyListeners();
  }

  Future<void> takeCondicionesPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _condicionesPhotos['condiciones'] ??= [];
      if (_condicionesPhotos['condiciones']!.length < 5) {
        _condicionesPhotos['condiciones']!.add(File(photo.path));
        _condicionesPhotosTomadas = true;
        notifyListeners();
      }
    }
  }

  void removeCondicionesPhoto(File photo) {
    _condicionesPhotos['condiciones']?.remove(photo);
    if (_condicionesPhotos['condiciones']?.isEmpty ?? true) {
      _condicionesPhotosTomadas = false;
    }
    notifyListeners();
  }

  // Métodos para precargas
  void updatePrecarga(int index, String precarga, String indicacion) {
    if (index < _precargas.length) {
      _precargas[index]['precarga'] = precarga;
      _precargas[index]['indicacion'] = indicacion;
      notifyListeners();
    }
  }

  void addPrecarga() {
    if (_precargas.length < 6) {
      _precargas.add({
        'precarga': '',
        'indicacion': '',
      });
      notifyListeners();
    }
  }

  void removePrecarga() {
    if (_precargas.length > 5) {
      _precargas.removeLast();
      notifyListeners();
    }
  }

  void setAjusteData(Map<String, String> data) {
    _ajusteData.addAll(data);
    notifyListeners();
  }

  void setCondicionesAmbientales(Map<String, String> data) {
    _condicionesAmbientales.addAll(data);
    notifyListeners();
  }

  // Métodos para excentricidad
  void setSelectedPlataforma(String plataforma) {
    _selectedPlataforma = plataforma;
    _selectedOpcionExcentricidad =
        null; // Reset opción cuando cambia plataforma
    notifyListeners();
  }

  void setSelectedOpcionExcentricidad(String opcion) {
    _selectedOpcionExcentricidad = opcion;
    _updatePosicionesExcentricidad();
    notifyListeners();
  }

  void _updatePosicionesExcentricidad() {
    if (_selectedOpcionExcentricidad == null) return;

    int numberOfPositions =
        _getNumberOfPositions(_selectedOpcionExcentricidad!);
    _posicionesExcentricidad.clear();

    for (int i = 0; i < numberOfPositions; i++) {
      _posicionesExcentricidad.add({
        'posicion': (i + 1).toString(),
        'indicacion': '',
        'retorno': '0',
      });
    }
  }

  int _getNumberOfPositions(String platform) {
    if (platform.contains('3')) return 3;
    if (platform.contains('4')) return 4;
    if (platform.contains('5')) return 5;
    if (platform.startsWith('Cuadrada')) return 5;
    if (platform.startsWith('Triangular')) return 4;
    return 0;
  }

  void setCargaExcentricidad(String carga) {
    _cargaExcentricidad = carga;
    // Auto-rellenar indicaciones con el valor de la carga
    for (var posicion in _posicionesExcentricidad) {
      posicion['indicacion'] = carga;
    }
    notifyListeners();
  }

  void updatePosicionExcentricidad(int index, String field, String value) {
    if (index < _posicionesExcentricidad.length) {
      _posicionesExcentricidad[index][field] = value;
      notifyListeners();
    }
  }

  // Métodos para repetibilidad
  void setSelectedRepetibilityCount(int count) {
    _selectedRepetibilityCount = count;
    _initializeRepetibilidadData();
    notifyListeners();
  }

  void setSelectedRowCount(int count) {
    _selectedRowCount = count;
    _initializeRepetibilidadData();
    notifyListeners();
  }

  void updateRepetibilidadData(
      int carga, int fila, String field, String value) {
    if (carga < _repetibilidadData.length &&
        fila < _repetibilidadData[carga].length) {
      _repetibilidadData[carga][fila][field] = value;
      notifyListeners();
    }
  }

  void updateAllIndicaciones(int carga, String value) {
    if (carga < _repetibilidadData.length) {
      for (var fila in _repetibilidadData[carga]) {
        fila['indicacion'] = value;
      }
      notifyListeners();
    }
  }

  // Métodos para linealidad
  void setSelectedMetodoLinealidad(String metodo) {
    _selectedMetodoLinealidad = metodo;
    notifyListeners();
  }

  void setSelectedMetodoCarga(String metodo) {
    _selectedMetodoCarga = metodo;
    notifyListeners();
  }

  void updateLinealidadRow(int index, String field, String value) {
    if (index < _linealidadRows.length) {
      _linealidadRows[index][field] = value;
      notifyListeners();
    }
  }

  void addLinealidadRow() {
    if (_linealidadRows.length < 60) {
      _linealidadRows.add({
        'lt': '',
        'indicacion': '',
        'retorno': '0',
        'difference': '',
      });
      notifyListeners();
    }
  }

  void removeLinealidadRow(int index) {
    if (index >= 6 && _linealidadRows.length > 6) {
      // No eliminar primeras 6 filas
      _linealidadRows.removeAt(index);
      notifyListeners();
    }
  }

  void calculateAllDifferences() {
    // Obtener d1 y calcular diferencias para todas las filas
    for (int i = 0; i < _linealidadRows.length; i++) {
      final lt = double.tryParse(_linealidadRows[i]['lt'] ?? '') ?? 0.0;
      final indicacion =
          double.tryParse(_linealidadRows[i]['indicacion'] ?? '') ?? 0.0;
      final difference = indicacion - lt;
      _linealidadRows[i]['difference'] = difference.toString();
    }
    notifyListeners();
  }

  // Métodos para condiciones finales
  void setCondicionFinal(String key, String value) {
    _condicionesFinales[key] = value;
    notifyListeners();
  }

  Future<void> takeCondicionesFinalesPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _condicionesFinalesPhotos['final'] ??= [];
      if (_condicionesFinalesPhotos['final']!.length < 5) {
        _condicionesFinalesPhotos['final']!.add(File(photo.path));
        _condicionesFinalesPhotosTomadas = true;
        notifyListeners();
      }
    }
  }

  void removeCondicionesFinalesPhoto(File photo) {
    _condicionesFinalesPhotos['final']?.remove(photo);
    if (_condicionesFinalesPhotos['final']?.isEmpty ?? true) {
      _condicionesFinalesPhotosTomadas = false;
    }
    notifyListeners();
  }

  // Métodos de guardado por paso
  Future<void> saveCurrentStepData([Map<String, TextEditingController>? comentarioControllers]) async {
    try {
      switch (_currentStep) {
        case 0:
          await _saveCondicionesIniciales(comentarioControllers);
          break;
        case 1:
          await _savePrecargas();
          break;
        case 2:
          await _saveExcentricidad();
          break;
        case 3:
          await _saveRepetibilidad();
          break;
        case 4:
          await _saveLinealidad();
          break;
        case 5:
          await _saveCondicionesFinales();
          break;
      }

      _isDataSaved = true;
      notifyListeners();

    } catch (e) {
      _isDataSaved = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveCondicionesIniciales([Map<String, TextEditingController>? comentarioControllers]) async {
    try {
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = {
        'seca': secaValue,
        'session_id': sessionId,
        'cod_metrica': codMetrica,
        'n_reca': nReca,
        'hora_inicio': _horaInicio ?? '',
        'tiempo_estab': _tiempoEstabilizacion ?? '',
        't_ope_balanza': _tiempoBalanza ?? '',
        'foto_balanza': _condicionesPhotosTomadas ? 1 : 0,

        // Condiciones con comentarios
        'vibracion': _condicionesEntorno['Vibración'] ?? '',
        'vibracion_comentario': comentarioControllers?['Vibración']?.text ?? 'Sin Comentario',
        'polvo': _condicionesEntorno['Polvo'] ?? '',
        'polvo_comentario': comentarioControllers?['Polvo']?.text ?? 'Sin Comentario',
        'temp': _condicionesEntorno['Temperatura'] ?? '',
        'temp_comentario': comentarioControllers?['Temperatura']?.text ?? 'Sin Comentario',
        'humedad': _condicionesEntorno['Humedad'] ?? '',
        'humedad_comentario': comentarioControllers?['Humedad']?.text ?? 'Sin Comentario',
        'mesada': _condicionesEntorno['Mesada'] ?? '',
        'mesada_comentario': comentarioControllers?['Mesada']?.text ?? 'Sin Comentario',
        'iluminacion': _condicionesEntorno['Iluminación'] ?? '',
        'iluminacion_comentario': comentarioControllers?['Iluminación']?.text ?? 'Sin Comentario',
        'limp_foza': _condicionesEntorno['Limpieza de Fosa'] ?? '',
        'limp_foza_comentario': comentarioControllers?['Limpieza de Fosa']?.text ?? 'Sin Comentario',
        'estado_drenaje': _condicionesEntorno['Estado de Drenaje'] ?? '',
        'estado_drenaje_comentario': comentarioControllers?['Estado de Drenaje']?.text ?? 'Sin Comentario',
        'limp_general': _condicionesEntorno['Limpieza General'] ?? '',
        'limp_general_comentario': comentarioControllers?['Limpieza General']?.text ?? 'Sin Comentario',
        'golpes_terminal': _condicionesEntorno['Golpes al Terminal'] ?? '',
        'golpes_terminal_comentario': comentarioControllers?['Golpes al Terminal']?.text ?? 'Sin Comentario',
        'nivelacion': _condicionesEntorno['Nivelación'] ?? '',
        'nivelacion_comentario': comentarioControllers?['Nivelación']?.text ?? 'Sin Comentario',
        'limp_recepto': _condicionesEntorno['Limpieza Receptor'] ?? '',
        'limp_recepto_comentario': comentarioControllers?['Limpieza Receptor']?.text ?? 'Sin Comentario',
        'golpes_receptor': _condicionesEntorno['Golpes al receptor de Carga'] ?? '',
        'golpes_receptor_comentario': comentarioControllers?['Golpes al receptor de Carga']?.text ?? 'Sin Comentario',
        'encendido': _condicionesEntorno['Encendido'] ?? '',
        'encendido_comentario': comentarioControllers?['Encendido']?.text ?? 'Sin Comentario',
      };

      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar condiciones iniciales: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _savePrecargas() async {
    try {
      // ✅ AGREGAR: Verificar si existe el registro primero
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = <String, dynamic>{};

      // Precargas
      for (int i = 0; i < _precargas.length && i < 6; i++) {
        registro['precarga${i + 1}'] = _precargas[i]['precarga'] ?? '';
        registro['p_indicador${i + 1}'] = _precargas[i]['indicacion'] ?? '';
      }

      // Limpiar precargas no usadas
      for (int i = _precargas.length; i < 6; i++) {
        registro['precarga${i + 1}'] = '';
        registro['p_indicador${i + 1}'] = '';
      }

      // Datos adicionales
      registro.addAll(_ajusteData);
      registro.addAll(_condicionesAmbientales);

      // ✅ AGREGAR: Siempre incluir seca y session_id para el upsert
      registro['seca'] = secaValue;
      registro['session_id'] = sessionId;

      // ✅ CORREGIR: Usar la misma lógica de upsert
      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar precargas: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }


  Future<void> _saveExcentricidad() async {
    try {
      // ✅ AGREGAR: Verificar si existe el registro primero
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = {
        'tipo_plataforma': _selectedPlataforma ?? '',
        'puntos_ind': _selectedOpcionExcentricidad ?? '',
        'carga': _cargaExcentricidad ?? '',
        // ✅ AGREGAR: Siempre incluir seca y session_id
        'seca': secaValue,
        'session_id': sessionId,
      };

      // Posiciones de excentricidad
      for (int i = 0; i < _posicionesExcentricidad.length && i < 6; i++) {
        registro['posicion${i + 1}'] = _posicionesExcentricidad[i]['posicion'] ?? '';
        registro['indicacion${i + 1}'] = _posicionesExcentricidad[i]['indicacion'] ?? '';
        registro['retorno${i + 1}'] = _posicionesExcentricidad[i]['retorno'] ?? '';
      }

      // Limpiar posiciones no usadas
      for (int i = _posicionesExcentricidad.length; i < 6; i++) {
        registro['posicion${i + 1}'] = '';
        registro['indicacion${i + 1}'] = '';
        registro['retorno${i + 1}'] = '';
      }

      // ✅ CORREGIR: Usar la misma lógica de upsert
      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar excentricidad: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveRepetibilidad() async {
    try {
      // ✅ AGREGAR: Verificar si existe el registro primero
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = <String, dynamic>{
        // ✅ AGREGAR: Siempre incluir seca y session_id
        'seca': secaValue,
        'session_id': sessionId,
      };

      // Datos de repetibilidad
      for (int carga = 0; carga < _repetibilidadData.length && carga < 3; carga++) {
        for (int fila = 0; fila < _repetibilidadData[carga].length && fila < 10; fila++) {
          registro['indicacion${carga + 1}_${fila + 1}'] =
              _repetibilidadData[carga][fila]['indicacion'] ?? '';
          registro['retorno${carga + 1}_${fila + 1}'] =
              _repetibilidadData[carga][fila]['retorno'] ?? '';
        }
      }

      // ✅ CORREGIR: Usar la misma lógica de upsert
      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar repetibilidad: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveLinealidad() async {
    try {
      // ✅ AGREGAR: Verificar si existe el registro primero
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = {
        'metodo': _selectedMetodoLinealidad ?? '',
        'metodo_carga': _selectedMetodoCarga ?? '',
        // ✅ AGREGAR: Siempre incluir seca y session_id
        'seca': secaValue,
        'session_id': sessionId,
      };

      // Filas de linealidad
      for (int i = 0; i < _linealidadRows.length && i < 60; i++) {
        registro['lin${i + 1}'] = _linealidadRows[i]['lt'] ?? '';
        registro['ind${i + 1}'] = _linealidadRows[i]['indicacion'] ?? '';
        registro['retorno_lin${i + 1}'] = _linealidadRows[i]['retorno'] ?? '';
      }

      // Limpiar filas no usadas
      for (int i = _linealidadRows.length; i < 60; i++) {
        registro['lin${i + 1}'] = '';
        registro['ind${i + 1}'] = '';
        registro['retorno_lin${i + 1}'] = '';
      }

      // ✅ CORREGIR: Usar la misma lógica de upsert
      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar linealidad: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveCondicionesFinales() async {
    try {
      // ✅ AGREGAR: Verificar si existe el registro primero
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      final registro = <String, dynamic>{
        // ✅ AGREGAR: Siempre incluir seca y session_id
        'seca': secaValue,
        'session_id': sessionId,
      };

      registro.addAll(_condicionesFinales);
      registro['foto_final'] = _condicionesFinalesPhotosTomadas ? 1 : 0;

      // ✅ CORREGIR: Usar la misma lógica de upsert
      if (existingRecord != null) {
        await _dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await _dbHelper.insertRegistroCalibracion(registro);
      }

    } catch (e, stackTrace) {
      debugPrint('Error al guardar condiciones finales: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  void _loadDataFromRecord(Map<String, dynamic> record) {
    // Cargar datos según el paso actual
    _horaInicio = record['hora_inicio']?.toString();
    _tiempoEstabilizacion = record['tiempo_estab']?.toString();
    _tiempoBalanza = record['t_ope_balanza']?.toString();

    // Cargar condiciones de entorno
    _condicionesEntorno['Vibración'] = record['vibracion']?.toString();
    // ... cargar todas las condiciones
  }


  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> finalizeServicio() async {
    if (!validateCurrentStep()) {
      throw Exception('Debe completar todos los campos antes de finalizar');
    }

    await saveCurrentStepData();

    // Actualizar estado del servicio
    final registro = {
      'estado_servicio_bal': 'Balanza Calibrada'
    };

    await _dbHelper.upsertRegistroCalibracion(registro);
  }

  String _getDbFieldName(String displayName) {
    const fieldMap = {
      'Vibración': 'vibracion',
      'Polvo': 'polvo',
      'Temperatura': 'temp',
      'Humedad': 'humedad',
      'Mesada': 'mesada',
      'Iluminación': 'iluminacion',
      'Limpieza de Fosa': 'limp_foza',
      'Estado de Drenaje': 'estado_drenaje',
      'Limpieza General': 'limp_general',
      'Golpes al Terminal': 'golpes_terminal',
      'Nivelación': 'nivelacion',
      'Limpieza Receptor': 'limp_recepto',
      'Golpes al receptor de Carga': 'golpes_receptor',
      'Encendido': 'encendido',
    };
    return fieldMap[displayName] ??
        displayName.toLowerCase().replaceAll(' ', '_');
  }

  Future<double> getD1FromDatabase() async {
    try {
      final existingRecord = await _dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (existingRecord != null && existingRecord['d1'] != null) {
        return double.tryParse(existingRecord['d1'].toString()) ?? 0.1;
      }
      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener d1 desde la base de datos: $e');
      return 0.1;
    }
  }

  List<String> generateD1Options(double baseValue, double d1) {
    final decimalPlaces = _getSignificantDecimals(d1);
    return List.generate(11, (index) {
      final multiplier = index - 5;
      final value = baseValue + (multiplier * d1);
      return value.toStringAsFixed(decimalPlaces);
    });
  }

  int _getSignificantDecimals(double value) {
    final text = value.toString();
    if (text.contains('.')) {
      return text.split('.')[1].replaceAll(RegExp(r'0+$'), '').length;
    }
    return 0;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
