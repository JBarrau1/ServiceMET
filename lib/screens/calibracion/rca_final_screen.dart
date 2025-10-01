import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../bdb/calibracion_bd.dart';
import '../../database/app_database.dart';
import '../../provider/balanza_provider.dart';
import 'fin_servicio.dart';
import 'package:flutter/services.dart';

class RcaFinalScreen extends StatefulWidget {
  final String secaValue;
  final String sessionId;
  final Map<String, dynamic> selectedBalanza;
  final String codMetrica;

  const RcaFinalScreen({
    super.key,
    required this.selectedBalanza,
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
  });

  @override
  _RcaFinalScreenState createState() => _RcaFinalScreenState();
}

class _RcaFinalScreenState extends State<RcaFinalScreen> {

  double? _hriInicial;
  double? _tiInicial;
  double? _patmiInicial;

  String? _selectedEmp23001;
  DatabaseHelper? _dbHelper; // Declaración de _dbHelper
  bool _isDataSaved =
      false; // Variable para rastrear si los datos se han guardado
  String? _selectedReglaAceptacion;

  final ValueNotifier<bool> _isNextButtonVisible = ValueNotifier<bool>(false);
  final TextEditingController _indicarController = TextEditingController();
  final TextEditingController _factorSeguridadController =
      TextEditingController();
  final TextEditingController _hrifinController = TextEditingController();
  final TextEditingController _tifinController = TextEditingController();
  final TextEditingController _patmifinController = TextEditingController();
  final TextEditingController _mantenimientoController =
      TextEditingController();
  final TextEditingController _ventaPesasController = TextEditingController();
  final TextEditingController _reemplazoController = TextEditingController();
  final TextEditingController _obscomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _horaController = TextEditingController();
  final Map<String, List<File>> _finalPhotos = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool _fotosTomadas = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper(); // Inicializa _dbHelper aquí
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    try {
      final dbHelper = AppDatabase();
      final registro = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

      if (registro != null) {
        setState(() {
          _hriInicial = double.tryParse(registro['hri']?.toString() ?? '');
          _tiInicial = double.tryParse(registro['ti']?.toString() ?? '');
          _patmiInicial = double.tryParse(registro['patmi']?.toString() ?? '');
        });
      }
    } catch (e) {
      debugPrint('Error al cargar valores iniciales: $e');
    }
  }

  Color _getValidationColor(double? initialValue, String currentText) {
    if (initialValue == null || currentText.isEmpty) {
      return Colors.grey; // Color por defecto
    }

    final currentValue = double.tryParse(currentText);
    if (currentValue == null) return Colors.grey;

    final difference = (currentValue - initialValue).abs();

    if (difference <= 4) {
      return Colors.green; // Dentro del rango permitido
    } else {
      return Colors.red; // Fuera del rango
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // color del texto
        ),
        // Usa `SnackBarTheme` o personaliza aquí:
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // esto aún funciona en versiones actuales
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    // Validaciones existentes...
    if (_horaController.text.isEmpty ||
        _hrifinController.text.isEmpty ||
        _tifinController.text.isEmpty ||
        _patmifinController.text.isEmpty ||
        _mantenimientoController.text.isEmpty ||
        _ventaPesasController.text.isEmpty ||
        _reemplazoController.text.isEmpty ||
        _obscomController.text.isEmpty

    // ... resto de validaciones
    ) {
      _showSnackBar(context, 'Error, termine de llenar todos los campos', isError: true);
      return;
    }

    // Guardar fotos si existen
    if (_finalPhotos['final']?.isNotEmpty ?? false) {
      await _savePhotosToZip(context);
    }

    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

      // Crear registro con TODOS los datos
      final Map<String, dynamic> registro = {
        'session_id': widget.sessionId,
        'seca': widget.secaValue,
        'hora_fin': _horaController.text,
        'hri_fin': _hrifinController.text,
        'ti_fin': _tifinController.text,
        'patmi_fin': _patmifinController.text,
        'mant_soporte': _mantenimientoController.text,
        'venta_pesas': _ventaPesasController.text,
        'reemplazo': _reemplazoController.text,
        'observaciones': _obscomController.text,
        'estado_servicio_bal': 'Balanza Calibrada',
      };

      // APLICAR LA MISMA LÓGICA QUE FUNCIONA
      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      if (mounted) {
        setState(() {
          _isDataSaved = true;
        });
        _isNextButtonVisible.value = true;
      }

      _showSnackBar(context, 'Datos guardados correctamente');
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar los datos: $e', isError: true);
      debugPrint('Error al guardar: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _finalPhotos['final'] ??= [];
        if (_finalPhotos['final']!.length < 5) {
          _finalPhotos['final']!.add(File(photo.path));
          _fotosTomadas = true;
        } else {
          _showSnackBar(context, 'Maximo de 5 fotos alcanzado', isError: true);
        }
      });
    }
  }

  Future<void> _savePhotosToZip(BuildContext context) async {
    if (_finalPhotos['final']?.isNotEmpty ?? false) {
      final archive = Archive();
      for (var i = 0; i < _finalPhotos['final']!.length; i++) {
        final file = _finalPhotos['final']![i];
        final fileName = 'final_${i + 1}.jpg';
        archive.addFile(
            ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName =
          '${widget.secaValue}_${widget.codMetrica}_FotosFinalesBalanza.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        await FlutterFileDialog.saveFile(params: params);
      } catch (e) {
        _showSnackBar(context, 'Error al guardar fotos: $e', isError: true);
      }
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMACIÓN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: const Text(
            '¿Está seguro de los datos ingresados?, irá a la parte final del servicio de la balanza seleccionada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.yellow
                      : Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Color verde
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinServicioScreen(
                      secaValue: widget.secaValue,
                      sessionId: widget.sessionId,
                    ),
                  ),
                );
              },
              child: const Text(
                'Sí',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _reemplazoController.dispose();
    _mantenimientoController.dispose();
    _ventaPesasController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  void _setHora(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _horaController.text = formattedTime;
  }

  Widget _buildEditableDetailContainer(
      String label, String value, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            value,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContainer(
      String label, String value, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            value,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
      String label, String value, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration buildInputDecoration(
    String labelText, {
    Widget? suffixIcon,
    String? suffixText,
    TextStyle? errorStyle,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      errorStyle: errorStyle,
    );
  }

  InputDecoration buildPhotoInputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: _fotosTomadas ? Colors.green : Colors.grey,
          width: 2.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: _fotosTomadas ? Colors.green : Colors.grey,
          width: 1.0,
        ),
      ),
      labelText: 'Fotografías',
      labelStyle: TextStyle(
        color: _fotosTomadas ? Colors.green : Colors.grey,
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, File photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: Stack(
              children: [
                Center(
                  child: Image.file(
                    photo,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDarkMode ? Colors.white : Colors.black;
    final String horaFinal = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70, // Ajusta la altura del AppBar según lo necesites
        title: const Text(
          'CALIBRACIÓN',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10.0),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'REGISTRO DE CONDICIONES FINALES',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  Column(
                    children: [
                      const Text(
                        'FOTOGRAFÍAS FINALES DEL SERVICIO',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Máximo 5 fotos (${_finalPhotos['final']?.length ?? 0}/5)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _takePhoto(context),
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color(0xFFc0101a),
                                foregroundColor: Colors.white,
                              ),
                              child: const Icon(Icons.camera_alt),
                            ),
                            if (_finalPhotos['final'] != null)
                              ..._finalPhotos['final']!.map((photo) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () => _showFullScreenPhoto(context, photo),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Image.file(photo, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () {
                                              setState(() {
                                                _finalPhotos['final']!.remove(photo);
                                                if (_finalPhotos['final']!.isEmpty) {
                                                  _fotosTomadas = false;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              '1. INGRESE LAS CONDICIONES AMBIENTALES FINALES:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  const SizedBox(height: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _horaController,
                        readOnly: true,
                        decoration: buildInputDecoration(
                          'Hora',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _setHora(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white70
                                : Colors.black, // Naranja oscuro en modo claro
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Haga clic en el icono del reloj para ingresar la hora, la hora es obtenida automáticamente del sistema, no es editable.',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black,
                                fontWeight:
                                    FontWeight.w500, // Texto un poco más grueso
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _hrifinController,
                    builder: (context, value, child) {
                      final borderColor = _getValidationColor(_hriInicial, value.text);
                      return TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        controller: _hrifinController,
                        decoration: buildInputDecoration(
                          'HRi (%)',
                          suffixText: '%',
                        ).copyWith(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.5),
                          ),
                          prefixIcon: Icon(
                            borderColor == Colors.green
                                ? Icons.check_circle
                                : (borderColor == Colors.red ? Icons.warning : Icons.info),
                            color: borderColor,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un valor';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20.0),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _tifinController,
                    builder: (context, value, child) {
                      final borderColor = _getValidationColor(_tiInicial, value.text);
                      return TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        controller: _tifinController,
                        decoration: buildInputDecoration(
                          'ti (°C)',
                          suffixText: '°C',
                        ).copyWith(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.5),
                          ),
                          prefixIcon: Icon(
                            borderColor == Colors.green
                                ? Icons.check_circle
                                : (borderColor == Colors.red ? Icons.warning : Icons.info),
                            color: borderColor,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un valor';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20.0),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _patmifinController,
                    builder: (context, value, child) {
                      final borderColor = _getValidationColor(_patmiInicial, value.text);
                      return TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        controller: _patmifinController,
                        decoration: buildInputDecoration(
                          'Patmi (hPa)',
                          suffixText: 'hPa',
                        ).copyWith(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: borderColor, width: 2.5),
                          ),
                          prefixIcon: Icon(
                            borderColor == Colors.green
                                ? Icons.check_circle
                                : (borderColor == Colors.red ? Icons.warning : Icons.info),
                            color: borderColor,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un valor';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              '2. REGISTRO DE RECOMENDACIONES:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              decoration: buildInputDecoration(
                'Mantenimiento con ST',
              ),
              items: ['Sí', 'No'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                _mantenimientoController.text = newValue ?? '';
              },
              validator: (value) =>
                  value == null ? 'Por favor seleccione una opción' : null,
            ),
            const SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              decoration: buildInputDecoration(
                'Venta de Pesas',
              ),
              items: ['Sí', 'No'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                _ventaPesasController.text = newValue ?? '';
              },
              validator: (value) =>
                  value == null ? 'Por favor seleccione una opción' : null,
            ),
            const SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              decoration: buildInputDecoration(
                'Reemplazo',
              ),
              items: ['Sí', 'No'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                _reemplazoController.text = newValue ?? '';
              },
              validator: (value) =>
                  value == null ? 'Por favor seleccione una opción' : null,
            ),
            const SizedBox(height: 20.0),
            const Text(
              '3. OBSERVACIONES Y RECOMENDACIONES ADICIONALES:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _obscomController,
              decoration: buildInputDecoration(
                'Comentarios y Observaciones',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un comentario u observación';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveDataToDatabase(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007195),
                    ),
                    child: const Text('1: GUARDAR DATOS'),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isNextButtonVisible,
                    builder: (context, isVisible, child) {
                      return Visibility(
                        visible: isVisible,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_isDataSaved) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Debe guardar los datos antes de continuar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _showConfirmationDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF478b3a),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('2: SIGUIENTE'),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.black54),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.info),
            backgroundColor: Colors.orangeAccent,
            label: 'Información de la balanza',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text(
                            'Información de la balanza',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (balanza != null) ...[
                            _buildDetailContainer(
                                'Código Métrica',
                                balanza.cod_metrica,
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'pmax1',
                                balanza.cap_max1,
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'd1',
                                balanza.d1.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'e1',
                                balanza.e1.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'dec',
                                balanza.dec1.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'pmax2',
                                balanza.cap_max2,
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'd2',
                                balanza.d2.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'e2',
                                balanza.e2.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'dec2',
                                balanza.dec2.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'pmax3',
                                balanza.cap_max3,
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'd3',
                                balanza.d3.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'e3',
                                balanza.e3.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                            _buildDetailContainer(
                                'dec3',
                                balanza.dec3.toString(),
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black,
                                Colors.grey),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.info),
            backgroundColor: Colors.orange,
            label: 'Datos del Último Servicio',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  final lastServiceData =
                      Provider.of<BalanzaProvider>(context, listen: false)
                          .lastServiceData;
                  if (lastServiceData == null) {
                    return const Center(
                        child: Text('No hay datos de servicio'));
                  }

                  final textColor =
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black;
                  final dividerColor =
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black;

                  // Definir etiquetas para los campos
                  final Map<String, String> fieldLabels = {
                    'reg_fecha': 'Fecha del Último Servicio',
                    'reg_usuario': 'Técnico Responsable',
                    'seca': 'Último SECA',
                    'exc': 'Exc',
                  };

                  // Agregar los campos rep1 a rep30 dinámicamente
                  for (int i = 1; i <= 30; i++) {
                    fieldLabels['rep$i'] = 'rep $i';
                  }

                  for (int i = 1; i <= 60; i++) {
                    fieldLabels['lin$i'] = 'lin $i';
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REGISTRO DE ÚLTIMOS SERVICIOS DE CALIBRACIÓN',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ...lastServiceData.entries
                              .where((entry) =>
                                  entry.value != null &&
                                  fieldLabels.containsKey(entry.key))
                              .map((entry) => _buildEditableDetailContainer(
                                  fieldLabels[entry.key]!,
                                  entry.key == 'reg_fecha'
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(DateTime.parse(entry.value))
                                      : entry.value
                                          .toString(), // Ensure value is a String
                                  textColor,
                                  dividerColor)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
