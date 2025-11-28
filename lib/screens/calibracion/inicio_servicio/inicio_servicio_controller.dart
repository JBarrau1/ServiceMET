import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import '../../../database/app_database.dart';

class InicioServicioController extends ChangeNotifier {
  // --- Estado Global ---
  int _currentStep = 0;
  int get currentStep => _currentStep;

  final String sessionId;
  final String secaValue;
  final String codMetrica;
  final String nReca;

  InicioServicioController({
    required this.sessionId,
    required this.secaValue,
    required this.codMetrica,
    required this.nReca,
  }) {
    _initializeControllers();
  }

  // --- Estado Paso 1: Inspección Visual (ServicioScreen) ---
  final Map<String, List<File>> fieldPhotos = {};
  final Map<String, Map<String, dynamic>> fieldData = {};

  // Controllers para comentarios de inspección
  final Map<String, TextEditingController> commentControllers = {
    'Vibración': TextEditingController(text: 'Sin Comentario'),
    'Polvo': TextEditingController(text: 'Sin Comentario'),
    'Temperatura': TextEditingController(text: 'Sin Comentario'),
    'Humedad': TextEditingController(text: 'Sin Comentario'),
    'Mesada': TextEditingController(text: 'Sin Comentario'),
    'Iluminación': TextEditingController(text: 'Sin Comentario'),
    'Limpieza de Fosa': TextEditingController(text: 'Sin Comentario'),
    'Estado de Drenaje': TextEditingController(text: 'Sin Comentario'),
    'Limpieza General': TextEditingController(text: 'Sin Comentario'),
    'Golpes al Terminal': TextEditingController(text: 'Sin Comentario'),
    'Nivelación': TextEditingController(text: 'Sin Comentario'),
    'Limpieza Receptor': TextEditingController(text: 'Sin Comentario'),
    'Golpes al receptor de Carga':
        TextEditingController(text: 'Sin Comentario'),
    'Encendido': TextEditingController(text: 'Sin Comentario'),
  };

  String? horaInicio;
  String? tiempoMin;
  String? tiempoBalanza;
  bool setAllToGood = false;

  // --- Estado Paso 2: Precargas y Ajuste (PruebasScreen) ---
  final List<TextEditingController> precargasControllers = [];
  final List<TextEditingController> indicacionesControllers = [];
  int rowCount = 5; // AppConstants.minPreloads
  static const int maxPreloads = 6;
  static const int minPreloads = 5;

  final TextEditingController tipoAjusteController = TextEditingController();
  final TextEditingController cargasPesasController = TextEditingController();
  final TextEditingController horaPruebasController = TextEditingController();
  final TextEditingController tiController = TextEditingController();
  final TextEditingController hriController = TextEditingController();
  final TextEditingController patmiController = TextEditingController();

  bool isAjusteRealizado = false;
  bool isAjusteExterno = false;

  // --- Inicialización ---
  void _initializeControllers() {
    horaInicio = DateFormat('HH:mm:ss').format(DateTime.now());
    horaPruebasController.text = DateFormat('HH:mm:ss').format(DateTime.now());

    // Inicializar filas de precarga
    for (int i = 0; i < rowCount; i++) {
      precargasControllers.add(TextEditingController());
      indicacionesControllers.add(TextEditingController());
    }
    notifyListeners();
  }

  void _setFieldToGood(String label, String value) {
    fieldData[label] ??= {};
    fieldData[label]!['value'] = value;
  }

  void updateFieldData(String label, String value) {
    fieldData[label] ??= {};
    fieldData[label]!['value'] = value;
    notifyListeners();
  }

  void addPhoto(String label, File photo) {
    fieldPhotos[label] ??= [];
    fieldPhotos[label]!.add(photo);

    fieldData[label] ??= {};
    fieldData[label]!['foto'] = basename(photo.path);

    notifyListeners();
  }

  void removePhoto(String label, File photo) {
    if (fieldPhotos[label] != null) {
      fieldPhotos[label]!.remove(photo);
      if (fieldPhotos[label]!.isEmpty) {
        fieldData[label]?.remove('foto');
      }
      notifyListeners();
    }
  }

  void setSetAllToGood(bool value) {
    setAllToGood = value;
    if (value) {
      _setFieldToGood('Vibración', 'Inexistente');
      _setFieldToGood('Polvo', 'Inexistente');
      _setFieldToGood('Temperatura', 'Bueno');
      _setFieldToGood('Humedad', 'Inexistente');
      _setFieldToGood('Mesada', 'Bueno');
      _setFieldToGood('Iluminación', 'Bueno');
      _setFieldToGood('Limpieza de Fosa', 'Bueno');
      _setFieldToGood('Estado de Drenaje', 'Bueno');
      _setFieldToGood('Limpieza General', 'Bueno');
      _setFieldToGood('Golpes al Terminal', 'Sin Daños');
      _setFieldToGood('Nivelación', 'Bueno');
      _setFieldToGood('Limpieza Receptor', 'Inexistente');
      _setFieldToGood('Golpes al receptor de Carga', 'Sin Daños');
      _setFieldToGood('Encendido', 'Bueno');
    }
    notifyListeners();
  }

  void setTiempoMin(String? value) {
    tiempoMin = value;
    notifyListeners();
  }

  void setTiempoBalanza(String? value) {
    tiempoBalanza = value;
    notifyListeners();
  }

  // --- Métodos Paso 2 ---
  void addPreloadRow() {
    if (rowCount >= maxPreloads) return;
    rowCount++;
    precargasControllers.add(TextEditingController());
    indicacionesControllers.add(TextEditingController());
    notifyListeners();
  }

  void removePreloadRow() {
    if (rowCount > minPreloads) {
      rowCount--;
      precargasControllers.removeLast().dispose();
      indicacionesControllers.removeLast().dispose();
      notifyListeners();
    }
  }

  void setAjusteRealizado(bool value) {
    isAjusteRealizado = value;
    if (!value) {
      tipoAjusteController.text = 'NO APLICA';
      cargasPesasController.text = 'NO APLICA';
      isAjusteExterno = false;
    } else {
      tipoAjusteController.clear();
      cargasPesasController.clear();
    }
    notifyListeners();
  }

  void setTipoAjuste(String value) {
    isAjusteExterno = value == 'EXTERNO';
    tipoAjusteController.text = value;
    if (!isAjusteExterno) {
      cargasPesasController.text = 'NO APLICA';
    } else {
      cargasPesasController.clear();
    }
    notifyListeners();
  }

  void updatePruebasTime() {
    horaPruebasController.text = DateFormat('HH:mm:ss').format(DateTime.now());
    notifyListeners();
  }

  Future<double> getD1FromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> result = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [secaValue, sessionId],
        columns: ['d1'],
        limit: 1,
      );

      if (result.isNotEmpty && result.first['d1'] != null) {
        final d1Value = result.first['d1'];
        if (d1Value is double) return d1Value;
        if (d1Value is int) return d1Value.toDouble();
        if (d1Value is String) return double.tryParse(d1Value) ?? 0.1;
      }
      return 0.1;
    } catch (e) {
      debugPrint('Error getting d1: $e');
      return 0.1;
    }
  }

  Future<Map<String, double>> getAllDValues() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> result = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [secaValue, sessionId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final data = result.first;
        return {
          'd1': double.tryParse(data['d1']?.toString() ?? '') ?? 0.1,
          'd2': double.tryParse(data['d2']?.toString() ?? '') ?? 0.1,
          'd3': double.tryParse(data['d3']?.toString() ?? '') ?? 0.1,
          'pmax1': double.tryParse(data['cap_max1']?.toString() ?? '') ?? 0.0,
          'pmax2': double.tryParse(data['cap_max2']?.toString() ?? '') ?? 0.0,
          'pmax3': double.tryParse(data['cap_max3']?.toString() ?? '') ?? 0.0,
        };
      }
      return {
        'd1': 0.1,
        'd2': 0.1,
        'd3': 0.1,
        'pmax1': 0.0,
        'pmax2': 0.0,
        'pmax3': 0.0
      };
    } catch (e) {
      debugPrint('Error getting all D values: $e');
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

  // --- Navegación y Guardado ---
  void nextStep() {
    if (_currentStep < 1) {
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

  bool validateStep1() {
    if (tiempoMin == null || tiempoMin!.isEmpty) return false;
    if (tiempoBalanza == null || tiempoBalanza!.isEmpty) return false;

    // Validar que todos los campos tengan valor (o estén en good)
    final requiredFields = [
      'Vibración',
      'Polvo',
      'Temperatura',
      'Humedad',
      'Mesada',
      'Iluminación',
      'Limpieza de Fosa',
      'Estado de Drenaje',
      'Limpieza General',
      'Golpes al Terminal',
      'Nivelación',
      'Limpieza Receptor',
      'Golpes al receptor de Carga',
      'Encendido'
    ];

    for (var field in requiredFields) {
      if (fieldData[field]?['value'] == null ||
          fieldData[field]!['value'].toString().isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool validateStep2() {
    // Validar precargas
    for (int i = 0; i < precargasControllers.length; i++) {
      if (precargasControllers[i].text.isEmpty ||
          indicacionesControllers[i].text.isEmpty) {
        return false;
      }
    }

    if (horaPruebasController.text.isEmpty) return false;
    if (hriController.text.isEmpty) return false;
    if (tiController.text.isEmpty) return false;
    if (patmiController.text.isEmpty) return false;

    if (isAjusteRealizado && tipoAjusteController.text.isEmpty) return false;
    if (isAjusteExterno && cargasPesasController.text.isEmpty) return false;

    return true;
  }

  Future<void> saveStep1() async {
    // Guardar fotos primero
    await _savePhotosToZip();

    // Guardar datos
    final dbHelper = AppDatabase();
    final existingRecord =
        await dbHelper.getRegistroBySeca(secaValue, sessionId);

    final registro = {
      'seca': secaValue,
      'session_id': sessionId,
      'cod_metrica': codMetrica,
      'n_reca': nReca,
      'hora_inicio': horaInicio,
      'tiempo_estab': tiempoMin,
      't_ope_balanza': tiempoBalanza,
      'vibracion': fieldData['Vibración']?['value'] ?? '',
      'vibracion_comentario': commentControllers['Vibración']?.text ?? '',
      'polvo': fieldData['Polvo']?['value'] ?? '',
      'polvo_comentario': commentControllers['Polvo']?.text ?? '',
      'temp': fieldData['Temperatura']?['value'] ?? '',
      'temp_comentario': commentControllers['Temperatura']?.text ?? '',
      'humedad': fieldData['Humedad']?['value'] ?? '',
      'humedad_comentario': commentControllers['Humedad']?.text ?? '',
      'mesada': fieldData['Mesada']?['value'] ?? '',
      'mesada_comentario': commentControllers['Mesada']?.text ?? '',
      'iluminacion': fieldData['Iluminación']?['value'] ?? '',
      'iluminacion_comentario': commentControllers['Iluminación']?.text ?? '',
      'limp_foza': fieldData['Limpieza de Fosa']?['value'] ?? '',
      'limp_foza_comentario':
          commentControllers['Limpieza de Fosa']?.text ?? '',
      'estado_drenaje': fieldData['Estado de Drenaje']?['value'] ?? '',
      'estado_drenaje_comentario':
          commentControllers['Estado de Drenaje']?.text ?? '',
      'limp_general': fieldData['Limpieza General']?['value'] ?? '',
      'limp_general_comentario':
          commentControllers['Limpieza General']?.text ?? '',
      'golpes_terminal': fieldData['Golpes al Terminal']?['value'] ?? '',
      'golpes_terminal_comentario':
          commentControllers['Golpes al Terminal']?.text ?? '',
      'nivelacion': fieldData['Nivelación']?['value'] ?? '',
      'nivelacion_comentario': commentControllers['Nivelación']?.text ?? '',
      'limp_recepto': fieldData['Limpieza Receptor']?['value'] ?? '',
      'limp_recepto_comentario':
          commentControllers['Limpieza Receptor']?.text ?? '',
      'golpes_receptor':
          fieldData['Golpes al receptor de Carga']?['value'] ?? '',
      'golpes_receptor_comentario':
          commentControllers['Golpes al receptor de Carga']?.text ?? '',
      'encendido': fieldData['Encendido']?['value'] ?? '',
      'encendido_comentario': commentControllers['Encendido']?.text ?? '',
    };

    if (existingRecord != null) {
      await dbHelper.upsertRegistroCalibracion(registro);
    } else {
      await dbHelper.insertRegistroCalibracion(registro);
    }
  }

  void setIsAjusteRealizado(bool value) {
    isAjusteRealizado = value;
    notifyListeners();
  }

  void setIsAjusteExterno(bool value) {
    isAjusteExterno = value;
    notifyListeners();
  }

  Future<void> saveStep2() async {
    final dbHelper = AppDatabase();

    final Map<String, Object?> registro = {
      'seca': secaValue,
      'session_id': sessionId,
      'ajuste': isAjusteRealizado ? 'Sí' : 'No',
      'tipo': tipoAjusteController.text,
      'cargas_pesas': cargasPesasController.text,
      'hora': horaPruebasController.text,
      'hri': hriController.text,
      'ti': tiController.text,
      'patmi': patmiController.text,
    };

    for (int i = 0; i < precargasControllers.length; i++) {
      registro['precarga${i + 1}'] = precargasControllers[i].text;
      registro['p_indicador${i + 1}'] = indicacionesControllers[i].text;
    }

    for (int i = precargasControllers.length; i < maxPreloads; i++) {
      registro['precarga${i + 1}'] = '';
      registro['p_indicador${i + 1}'] = '';
    }

    await dbHelper.upsertRegistroCalibracion(registro);
  }

  Future<bool> _savePhotosToZip() async {
    bool hasPhotos = fieldPhotos.values.any((photos) => photos.isNotEmpty);
    if (!hasPhotos) return true;

    try {
      final archive = Archive();
      fieldPhotos.forEach((label, photos) {
        for (var i = 0; i < photos.length; i++) {
          final file = photos[i];
          final fileName = '${label}_${i + 1}.jpg'.replaceAll(' ', '_');
          archive.addFile(
              ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
        }
      });

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName = '${secaValue}_${codMetrica}_FotosEntornoBalanza.zip';

      final filePath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: uint8ListData,
          fileName: zipFileName,
          mimeTypesFilter: ['application/zip'],
        ),
      );

      return filePath != null;
    } catch (e) {
      debugPrint('Error saving photos: $e');
      return false;
    }
  }

  @override
  void dispose() {
    for (var controller in commentControllers.values) {
      controller.dispose();
    }
    for (var controller in precargasControllers) {
      controller.dispose();
    }
    for (var controller in indicacionesControllers) {
      controller.dispose();
    }
    tipoAjusteController.dispose();
    cargasPesasController.dispose();
    horaPruebasController.dispose();
    tiController.dispose();
    hriController.dispose();
    patmiController.dispose();

    super.dispose();
  }
}
