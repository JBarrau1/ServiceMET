import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import '../../database/app_database.dart';
import 'pruebas_screen.dart';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

class ServicioScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String codMetrica;
  final String nReca;

  const ServicioScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.codMetrica,
    required this.nReca,
  });

  @override
  _ServicioScreenState createState() => _ServicioScreenState();
}

class _ServicioScreenState extends State<ServicioScreen> {
  final Map<String, List<File>> _fieldPhotos = {};
  final _formKey = GlobalKey<FormState>();
  final Map<String, Map<String, dynamic>> _fieldData =
      {}; // Almacena comentarios e imágenes
  final TextEditingController _vibracionComentarioController =
      TextEditingController();
  final TextEditingController _polvoComentarioController =
      TextEditingController();
  final TextEditingController _temperaturaComentarioController =
      TextEditingController();
  final TextEditingController _humedadComentarioController =
      TextEditingController();
  final TextEditingController _mesadaComentarioController =
      TextEditingController();
  final TextEditingController _iluminacionComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaFosaComentarioController =
      TextEditingController();
  final TextEditingController _estadoDrenajeComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaGeneralComentarioController =
      TextEditingController();
  final TextEditingController _golpesTerminalComentarioController =
      TextEditingController();
  final TextEditingController _nivelacionComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaReceptorComentarioController =
      TextEditingController();
  final TextEditingController _golpesReceptorComentarioController =
      TextEditingController();
  final TextEditingController _encendidoComentarioController =
      TextEditingController();
  final ValueNotifier<bool> _isNextButtonVisible = ValueNotifier<bool>(false);
  final ImagePicker _imagePicker = ImagePicker();

  bool _setAllToGood = false;
  String? _horaInicio;
  String? _tiempoMin;
  String? _tiempoBalanza;
  String? _createdFolderPath;
  DatabaseHelper? _dbHelper;
  bool _isDataSaved =
      false; // Variable para rastrear si los datos se han guardado
  DateTime? _lastPressedTime;

  @override
  void dispose() {
    _isNextButtonVisible.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _horaInicio = DateFormat('HH:mm:ss').format(DateTime.now());

    _vibracionComentarioController.text = 'Sin Comentario';
    _polvoComentarioController.text = 'Sin Comentario';
    _temperaturaComentarioController.text = 'Sin Comentario';
    _humedadComentarioController.text = 'Sin Comentario';
    _mesadaComentarioController.text = 'Sin Comentario';
    _iluminacionComentarioController.text = 'Sin Comentario';
    _limpiezaFosaComentarioController.text = 'Sin Comentario';
    _estadoDrenajeComentarioController.text = 'Sin Comentario';
    _limpiezaGeneralComentarioController.text = 'Sin Comentario';
    _golpesTerminalComentarioController.text = 'Sin Comentario';
    _nivelacionComentarioController.text = 'Sin Comentario';
    _limpiezaReceptorComentarioController.text = 'Sin Comentario';
    _golpesReceptorComentarioController.text = 'Sin Comentario';
    _encendidoComentarioController.text = 'Sin Comentario';
  }

  void _handleSetAllToGood(bool value) {
    setState(() {
      _setAllToGood = value;

      if (value) {
        // Establecer todos los campos a sus valores "Bueno" o equivalentes
        _fieldData['Vibración'] = {'value': 'Inexistente'};
        _fieldData['Polvo'] = {'value': 'Inexistente'};
        _fieldData['Temperatura'] = {'value': 'Bueno'};
        _fieldData['Humedad'] = {'value': 'Inexistente'};
        _fieldData['Mesada'] = {'value': 'Bueno'};
        _fieldData['Iluminación'] = {'value': 'Bueno'};
        _fieldData['Limpieza de Fosa'] = {'value': 'Bueno'};
        _fieldData['Estado de Drenaje'] = {'value': 'Bueno'};
        _fieldData['Limpieza General'] = {'value': 'Bueno'};
        _fieldData['Golpes al Terminal'] = {'value': 'Sin Daños'};
        _fieldData['Nivelación'] = {'value': 'Bueno'};
        _fieldData['Limpieza Receptor'] = {'value': 'Inexistente'};
        _fieldData['Golpes al receptor de Carga'] = {'value': 'Sin Daños'};
        _fieldData['Encendido'] = {'value': 'Bueno'};
      } else {
        // Limpiar todos los campos
        _fieldData.clear();
      }
    });
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(context,
          'Presione nuevamente para retroceder. Los datos registrados se perderán.');
      return false;
    }
    return true;
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

  Future<void> _saveAllDataAndPhotos(BuildContext context) async {
    // 1. Manejo de fotos (igual que en IdenBalanzaScreen)
    bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      try {
        final archive = Archive();
        _fieldPhotos.forEach((label, photos) {
          for (var i = 0; i < photos.length; i++) {
            final file = photos[i];
            final fileName = '${label}_${i + 1}.jpg'.replaceAll(' ', '_');
            archive.addFile(ArchiveFile(
                fileName,
                file.lengthSync(),
                file.readAsBytesSync()
            ));
          }
        });

        final zipEncoder = ZipEncoder();
        final zipData = zipEncoder.encode(archive);
        final uint8ListData = Uint8List.fromList(zipData!);
        final zipFileName = '${widget.secaValue}_${widget.codMetrica}_FotosEntornoBalanza.zip';

        final filePath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            data: uint8ListData,
            fileName: zipFileName,
            mimeTypesFilter: ['application/zip'],
          ),
        );

        if (filePath == null) {
          _showSnackBar(context, 'No se seleccionó ubicación para guardar las fotos');
        }
      } catch (e) {
        _showSnackBar(context, 'Error al comprimir fotos: $e', isError: true);
        debugPrint('Error al comprimir fotos: $e');
      }
    }

    // 2. Validaciones (como en CalibracionScreen)
    if (_horaInicio == null || _horaInicio!.isEmpty) {
      _showSnackBar(context, 'Ingrese la hora de inicio', isError: true);
      return;
    }

    if (_tiempoMin == null || _tiempoMin!.isEmpty) {
      _showSnackBar(context, 'Ingrese el tiempo de estabilización', isError: true);
      return;
    }

    if (_tiempoBalanza == null || _tiempoBalanza!.isEmpty) {
      _showSnackBar(context, 'Ingrese el tiempo de operación de la balanza', isError: true);
      return;
    }

    // 3. Guardado en BD (patrón consistente con otras pantallas)
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

      // Preparar datos con misma estructura que otras pantallas
      final registro = {
        'seca': widget.secaValue,
        'session_id': widget.sessionId,
        'cod_metrica': widget.codMetrica,
        'n_reca': widget.nReca,
        'hora_inicio': _horaInicio,
        'tiempo_estab': _tiempoMin,
        't_ope_balanza': _tiempoBalanza,
        'vibracion': _fieldData['Vibración']?['value'] ?? '',
        'vibracion_comentario': _vibracionComentarioController.text,
        'polvo': _fieldData['Polvo']?['value'] ?? '',
        'polvo_comentario': _polvoComentarioController.text,
        'temp': _fieldData['Temperatura']?['value'] ?? '',
        'temp_comentario': _temperaturaComentarioController.text,
        'humedad': _fieldData['Humedad']?['value'] ?? '',
        'humedad_comentario': _humedadComentarioController.text,
        'mesada': _fieldData['Mesada']?['value'] ?? '',
        'mesada_comentario': _mesadaComentarioController.text,
        'iluminacion': _fieldData['Iluminación']?['value'] ?? '',
        'iluminacion_comentario': _iluminacionComentarioController.text,
        'limp_foza': _fieldData['Limpieza de Fosa']?['value'] ?? '',
        'limp_foza_comentario': _limpiezaFosaComentarioController.text,
        'estado_drenaje': _fieldData['Estado de Drenaje']?['value'] ?? '',
        'estado_drenaje_comentario': _estadoDrenajeComentarioController.text,
        'limp_general': _fieldData['Limpieza General']?['value'] ?? '',
        'limp_general_comentario': _limpiezaGeneralComentarioController.text,
        'golpes_terminal': _fieldData['Golpes al Terminal']?['value'] ?? '',
        'golpes_terminal_comentario': _golpesTerminalComentarioController.text,
        'nivelacion': _fieldData['Nivelación']?['value'] ?? '',
        'nivelacion_comentario': _nivelacionComentarioController.text,
        'limp_recepto': _fieldData['Limpieza Receptor']?['value'] ?? '',
        'limp_recepto_comentario': _limpiezaReceptorComentarioController.text,
        'golpes_receptor': _fieldData['Golpes al receptor de Carga']?['value'] ?? '',
        'golpes_receptor_comentario': _golpesReceptorComentarioController.text,
        'encendido': _fieldData['Encendido']?['value'] ?? '',
        'encendido_comentario': _encendidoComentarioController.text,
      };

      // Usar el mismo método upsert que en CalibracionScreen
      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      setState(() {
        _isDataSaved = true;
      });

      _showSnackBar(context, 'Datos guardados correctamente');
      _isNextButtonVisible.value = true;
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar en la base de datos: $e', isError: true);
      debugPrint('Error al guardar: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Widget _buildDropdownFieldWithComment(BuildContext context, String label,
      List<String> items, TextEditingController commentController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: _setAllToGood
                    ? _getDefaultGoodValue(label)
                    : _fieldData[label]?['value'],
                decoration: buildInputDecoration(label),
                items: items.map((String value) {
                  Color textColor;
                  switch (value) {
                    case 'Inexistente':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Dañado':
                      textColor = Colors.red;
                      break;
                    case 'Malo':
                      textColor = Colors.red;
                      break;
                    case 'Aceptable':
                      textColor = Colors.orange;
                      break;
                    case 'Bueno':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Sin Daños':
                      textColor = Colors.lightGreen;
                      break;
                    case 'Existente':
                      textColor = Colors.red;
                      break;
                    case 'Daños Leves':
                      textColor = Colors.orange;
                      break;
                    case 'No aplica':
                      textColor = Colors.grey;
                      break;
                    default:
                      textColor = Colors.black;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: textColor),
                    ),
                  );
                }).toList(),
                onChanged: _setAllToGood
                    ? null // Deshabilitar cambios cuando el switch está activado
                    : (newValue) {
                        setState(() {
                          _fieldData[label] ??= {};
                          _fieldData[label]!['value'] = newValue;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _showCommentDialog(context, label),
              icon: Icon(
                (_fieldPhotos[label]?.isNotEmpty ?? false)
                    ? Icons.check_circle
                    : Icons.camera_alt_rounded,
                color: (_fieldPhotos[label]?.isNotEmpty ?? false)
                    ? Colors.green
                    : null,
              ),
              tooltip: 'Agregar Fotografía',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: commentController,
                decoration: buildInputDecoration('Comentario $label'),
                onTap: () {
                  if (commentController.text == 'Sin Comentario') {
                    commentController.clear();
                  }
                },
                readOnly:
                    _setAllToGood, // Hacer el campo de solo lectura si el switch está activado
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

// Método auxiliar para obtener el valor "Bueno" por defecto según el campo
  String _getDefaultGoodValue(String label) {
    switch (label) {
      case 'Vibración':
      case 'Polvo':
      case 'Humedad':
      case 'Limpieza Receptor':
        return 'Inexistente';
      case 'Golpes al Terminal':
      case 'Golpes al receptor de Carga':
        return 'Sin Daños';
      default:
        return 'Bueno';
    }
  }

  Future<void> _showCommentDialog(BuildContext context, String label) async {
    final ImagePicker picker = ImagePicker();
    List<File> photos = _fieldPhotos[label] ?? [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'AGREGAR FOTOGRAFÍA PARA: $label',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? photo =
                            await picker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
                          setState(() {
                            photos.add(File(photo.path));
                            _fieldPhotos[label] = photos;
                            _fieldData[label] ??= {};
                            _fieldData[label]!['foto'] = basename(photo.path);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt),
                          const SizedBox(width: 8),
                          Text(photos.isEmpty
                              ? 'TOMAR FOTO'
                              : 'TOMAR OTRA FOTO'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (photos.isNotEmpty)
                      Wrap(
                        children: photos.map((photo) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child:
                                    Image.file(photo, width: 100, height: 100),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      photos.remove(photo);
                                      _fieldPhotos[label] = photos;
                                      if (photos.isEmpty) {
                                        _fieldData[label]?.remove('foto');
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Actualizamos el estado para reflejar los cambios
                      _fieldPhotos[label] = photos;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDarkMode ? Colors.white : Colors.black;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 70,
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
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'REGISTRO DE DATOS DE CONDICIONES DEL EQUIPO A CALIBRAR',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _horaInicio,
                      decoration: buildInputDecoration(
                        'Hora de inicio de la Calibración:',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Alinea el ícono con la parte superior del texto
                      children: [
                        Icon(
                          Icons.info, // Ícono de información
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                          size: 16.0, // Tamaño del ícono
                        ),
                        const SizedBox(
                            width: 5.0), // Espacio entre el ícono y el texto
                        Expanded(
                          child: Text(
                            'Hora obtenida automáticamente del sistema',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: _tiempoMin,
                  decoration: buildInputDecoration(
                    'Tiempo de estabilización de Pesas (en Minutos):',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Mayor a 15 minutos',
                        child: Text('Mayor a 15 minutos')),
                    DropdownMenuItem(
                        value: 'Mayor a 30 minutos',
                        child: Text('Mayor a 30 minutos')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _tiempoMin = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione una opción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: _tiempoBalanza,
                  decoration: buildInputDecoration(
                    'Tiempo previo a operacion de Balanza:',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Mayor a 15 minutos',
                        child: Text('Mayor a 15 minutos')),
                    DropdownMenuItem(
                        value: 'Mayor a 30 minutos',
                        child: Text('Mayor a 30 minutos')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _tiempoBalanza = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione una opción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'ENTORNO DE INSTALACIÓN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('Establecer todo en Buen Estado'),
                  value: _setAllToGood,
                  onChanged: _handleSetAllToGood,
                  activeColor: Colors.green,
                  secondary: Icon(
                    _setAllToGood ? Icons.check_circle : Icons.circle_outlined,
                    color: _setAllToGood ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Vibración',
                    ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
                    _vibracionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Polvo',
                    ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
                    _polvoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Temperatura',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _temperaturaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Humedad',
                    ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
                    _humedadComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Mesada',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _mesadaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Iluminación',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _iluminacionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Limpieza de Fosa',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _limpiezaFosaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Estado de Drenaje',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _estadoDrenajeComentarioController),
                const SizedBox(height: 20.0),
                const SizedBox(height: 20.0),
                const Text(
                  'ESTADO GENERAL DE LA BALANZA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Limpieza General',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _limpiezaGeneralComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Golpes al Terminal',
                    ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica'],
                    _golpesTerminalComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Nivelación',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _nivelacionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Limpieza Receptor',
                    ['Inexistente', 'Aceptable', 'Existente', 'No aplica'],
                    _limpiezaReceptorComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Golpes al receptor de Carga',
                    ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica'],
                    _golpesReceptorComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Encendido',
                    ['Bueno', 'Aceptable', 'Malo', 'No aplica'],
                    _encendidoComentarioController),
                const SizedBox(height: 20.0),
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await _saveAllDataAndPhotos(context);
                                _isNextButtonVisible.value = true;
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007195),
                              ),
                              child: const Text('1: GUARDAR DATOS'),
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Al guardar los datos, también se exportarán las fotos tomadas.',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isNextButtonVisible,
                          builder: (context, isVisible, child) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: isVisible
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      key: const ValueKey('next_button'),
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            if (!_isDataSaved) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Debe guardar los datos antes de continuar')),
                                              );
                                              return;
                                            }

                                            if (_formKey.currentState!
                                                .validate()) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'CONFIRMACIÓN',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                    content: const Text(
                                                        '¿Desea continuar con las pruebas de carga?, Verifique los datos ingresados antes de empezar con las pruebas de carga.'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            'Cancelar'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        PruebasScreen(
                                                                          codMetrica: widget.codMetrica,
                                                                          secaValue: widget.secaValue,
                                                                          sessionId: widget.sessionId,
                                                                        )),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                        child: const Text(
                                                            'Aceptar'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF3e7732),
                                          ),
                                          child: const Text('2: SIGUIENTE'),
                                        ),
                                        const SizedBox(height: 8.0),
                                        const Text(
                                          'Se empezará con las pruebas de carga.',
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
