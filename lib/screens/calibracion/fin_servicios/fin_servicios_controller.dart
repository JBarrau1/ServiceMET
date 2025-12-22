import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_met/database/app_database.dart';
import 'package:service_met/screens/calibracion/precarga/precarga_screen.dart';
import 'package:service_met/home/home_screen.dart';

class FinServiciosController extends ChangeNotifier {
  final String secaValue;
  final String sessionId;
  final String codMetrica;
  final BuildContext context;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Step 1: Condiciones Finales
  final TextEditingController horaController = TextEditingController();
  final TextEditingController hrifinController = TextEditingController();
  final TextEditingController tifinController = TextEditingController();
  final TextEditingController patmifinController = TextEditingController();
  final TextEditingController mantenimientoController = TextEditingController();
  final TextEditingController ventaPesasController = TextEditingController();
  final TextEditingController reemplazoController = TextEditingController();
  final TextEditingController obscomController = TextEditingController();

  double? hriInicial;
  double? tiInicial;
  double? patmiInicial;

  final Map<String, List<File>> finalPhotos = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool fotosTomadas = false;
  bool isDataSaved = false;

  // Step 2: Exportación
  String? selectedEmp23001;
  final TextEditingController indicarController = TextEditingController();
  final TextEditingController factorSeguridadController =
      TextEditingController();
  String? selectedReglaAceptacion;
  bool isExporting = false;

  FinServiciosController({
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
    required this.context,
  }) {
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    try {
      final dbHelper = AppDatabase();
      final registro = await dbHelper.getRegistroBySeca(secaValue, sessionId);

      if (registro != null) {
        hriInicial = double.tryParse(registro['hri']?.toString() ?? '');
        tiInicial = double.tryParse(registro['ti']?.toString() ?? '');
        patmiInicial = double.tryParse(registro['patmi']?.toString() ?? '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar valores iniciales: $e');
    }
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

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

  // --- Logic for Step 1 ---

  void setHora() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    horaController.text = formattedTime;
    notifyListeners();
  }

  Future<void> takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      finalPhotos['final'] ??= [];
      if (finalPhotos['final']!.length < 5) {
        finalPhotos['final']!.add(File(photo.path));
        fotosTomadas = true;
        notifyListeners();
      } else {
        _showSnackBar('Maximo de 5 fotos alcanzado', isError: true);
      }
    }
  }

  void removePhoto(File photo) {
    finalPhotos['final']?.remove(photo);
    if (finalPhotos['final']?.isEmpty ?? true) {
      fotosTomadas = false;
    }
    notifyListeners();
  }

  Future<void> saveStep1() async {
    if (horaController.text.isEmpty ||
        hrifinController.text.isEmpty ||
        tifinController.text.isEmpty ||
        patmifinController.text.isEmpty ||
        mantenimientoController.text.isEmpty ||
        ventaPesasController.text.isEmpty ||
        reemplazoController.text.isEmpty ||
        obscomController.text.isEmpty) {
      _showSnackBar('Error, termine de llenar todos los campos', isError: true);
      return;
    }

    if (finalPhotos['final']?.isNotEmpty ?? false) {
      await _savePhotosToZip();
    }

    try {
      final dbHelper = AppDatabase();
      final existingRecord =
          await dbHelper.getRegistroBySeca(secaValue, sessionId);

      final Map<String, dynamic> registro = {
        'session_id': sessionId,
        'seca': secaValue,
        'hora_fin': horaController.text,
        'hri_fin': hrifinController.text,
        'ti_fin': tifinController.text,
        'patmi_fin': patmifinController.text,
        'mant_soporte': mantenimientoController.text,
        'venta_pesas': ventaPesasController.text,
        'reemplazo': reemplazoController.text,
        'observaciones': obscomController.text,
        'estado_servicio_bal': 'Balanza Calibrada',
      };

      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      isDataSaved = true;
      notifyListeners();
      _showSnackBar('Datos guardados correctamente');
    } catch (e) {
      _showSnackBar('Error al guardar los datos: $e', isError: true);
    }
  }

  Future<void> _savePhotosToZip() async {
    if (finalPhotos['final']?.isNotEmpty ?? false) {
      final archive = Archive();
      for (var i = 0; i < finalPhotos['final']!.length; i++) {
        final file = finalPhotos['final']![i];
        final fileName = 'final_${i + 1}.jpg';
        archive.addFile(
            ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName = '${secaValue}_${codMetrica}_FotosFinalesBalanza.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        await FlutterFileDialog.saveFile(params: params);
      } catch (e) {
        _showSnackBar('Error al guardar fotos: $e', isError: true);
      }
    }
  }

  // --- Logic for Step 2 ---

  Future<List<Map<String, dynamic>>> prepareExportData() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

      final rows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND estado_servicio_bal = ?',
        whereArgs: [secaValue, 'Balanza Calibrada'],
      );

      final cantidad = rows.length;

      if (cantidad == 0) {
        _showSnackBar(
            'No hay registros para exportar con este SECA ($secaValue)',
            isError: true);
        return [];
      }

      // 1. Solicitar datos adicionales (Dialog logic should be in UI, but we can handle data here)
      // Assuming the dialog is handled in the UI and sets the values in the controller
      if (selectedEmp23001 == null ||
          indicarController.text.isEmpty ||
          factorSeguridadController.text.isEmpty ||
          selectedReglaAceptacion == null) {
        // This check should ideally happen before calling this method or inside the dialog
        // But if we are calling this from the "Finalizar" button directly after filling fields
        _showSnackBar('Complete todos los campos de exportación',
            isError: true);
        return [];
      }

      // 2. Actualizar registros con datos adicionales
      for (final row in rows) {
        await db.update(
          'registros_calibracion',
          {
            'emp': selectedEmp23001,
            'indicar': indicarController.text,
            'factor': factorSeguridadController.text,
            'regla_aceptacion': selectedReglaAceptacion,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }

      // 3. Obtener rows actualizados
      final updatedRows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND estado_servicio_bal = ?',
        whereArgs: [secaValue, 'Balanza Calibrada'],
      );

      return updatedRows;
    } catch (e) {
      _showSnackBar('Error en exportación: $e', isError: true);
      return [];
    }
  }

  Future<void> executeExport(List<Map<String, dynamic>> rows) async {
    // Export logic
    await _exportToCSV(rows);

    // Navigate to Home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _exportToCSV(List<Map<String, dynamic>> registros) async {
    if (isExporting) return;
    isExporting = true;
    notifyListeners();

    try {
      final registrosDepurados = await _depurarDatos(registros);
      final csvBytes = await _generateCSVBytes(registrosDepurados);
      final fileName =
          '${secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';

      final internalDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${internalDir.path}/export_servicios');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);

      final internalFile = File('${exportDir.path}/$fileName');
      await internalFile.writeAsBytes(csvBytes);

      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino para exportación',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$fileName');
        await userFile.writeAsBytes(csvBytes, mode: FileMode.write);
        _showSnackBar('Archivo CSV exportado exitosamente a: ${userFile.path}');
      } else {
        _showSnackBar('Exportación cancelada.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error al exportar CSV: $e', isError: true);
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _depurarDatos(
      List<Map<String, dynamic>> registros) async {
    registros.removeWhere((registro) =>
        registro.values.every((value) => value == null || value == ''));

    final Map<String, Map<String, dynamic>> registrosUnicos = {};

    for (var registro in registros) {
      final String claveUnica =
          '${registro['reca']}_${registro['cod_metrica']}_${registro['sticker']}';
      final String horaFinActual = registro['hora_fin']?.toString() ?? '';

      if (!registrosUnicos.containsKey(claveUnica) ||
          (registrosUnicos[claveUnica]?['hora_fin']?.toString() ?? '')
                  .compareTo(horaFinActual) <
              0) {
        registrosUnicos[claveUnica] = registro;
      }
    }

    return registrosUnicos.values.toList();
  }

  Future<List<int>> _generateCSVBytes(
      List<Map<String, dynamic>> registros) async {
    final headers = registros.first.keys.toList();

    final rows = registros.map((registro) {
      return headers.map((header) {
        final value = registro[header];
        if (value is double || value is num) {
          return value.toString();
        } else {
          return value?.toString() ?? '';
        }
      }).toList();
    }).toList();

    rows.insert(0, headers);

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
    ).convert(rows);

    return utf8.encode(csv);
  }

  Future<void> confirmarSeleccionOtraBalanza() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> rows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [secaValue, sessionId],
        orderBy: 'id DESC',
      );

      final nuevoSessionId = await dbHelper.generateSessionId(secaValue);

      final Map<String, dynamic> nuevoRegistro = {
        'seca': secaValue,
        'session_id': nuevoSessionId,
        'fecha_servicio': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };

      const columnsToCarry = [
        'cliente',
        'razon_social',
        'planta',
        'dir_planta',
        'dep_planta',
        'cod_planta',
        'personal',
        'equipo6',
        'certificado6',
        'ente_calibrador6',
        'estado6',
        'cantidad6',
        'equipo7',
        'certificado7',
        'ente_calibrador7',
        'estado7',
        'cantidad7',
      ];

      for (final col in columnsToCarry) {
        for (final row in rows) {
          final v = row[col];
          if (v != null && (v is! String || v.toString().trim().isNotEmpty)) {
            nuevoRegistro[col] = v;
            break;
          }
        }
      }

      await dbHelper.upsertRegistroCalibracion(nuevoRegistro);

      final userName = nuevoRegistro['personal']?.toString() ?? 'Usuario';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrecargaScreen(
            userName: userName,
            initialStep: 3,
            sessionId: nuevoSessionId,
            secaValue: secaValue,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error al preparar nueva balanza: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    horaController.dispose();
    hrifinController.dispose();
    tifinController.dispose();
    patmifinController.dispose();
    mantenimientoController.dispose();
    ventaPesasController.dispose();
    reemplazoController.dispose();
    obscomController.dispose();
    indicarController.dispose();
    factorSeguridadController.dispose();
    super.dispose();
  }
}
