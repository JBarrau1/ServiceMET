import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/fin_servicio.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../database/app_database_sop.dart';
import '../../componentes/test_container.dart';

class RelevamientoDeDatosScreen extends StatefulWidget {
  final String nReca;
  final String codMetrica;
  final String secaValue;
  final String sessionId;

  const RelevamientoDeDatosScreen({
    super.key,
    required this.secaValue,
    required this.sessionId,
    required this.nReca,
    required this.codMetrica,
  });

  @override
  _RelevamientoDeDatosScreenState createState() =>
      _RelevamientoDeDatosScreenState();
}

class _RelevamientoDeDatosScreenState extends State<RelevamientoDeDatosScreen> {
  Timer? _debounceTimer;
  bool _isAutoSaving = false;

  final TextEditingController _comentarioGeneralController =
      TextEditingController();
  String? _selectedRecommendation;

  final Map<String, List<File>> _fieldPhotos = {};
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final ImagePicker _imagePicker = ImagePicker();
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _lastPressedTime;
  String _selectedUnit = 'kg';
  Map<String, dynamic> _metrologicalTestsData = {};

  final Map<String, bool> _sectorGoodState = {
    'TERMINAL': false,
    'PLATAFORMA': false,
    'CELDAS DE CARGA': false,
  };

  final Map<String, List<String>> _sectorFields = {
    'TERMINAL': [
      'Carcasa', 'Conector y Cables', 'Alimentación',
      'Pantalla', 'Teclado', 'Bracket y columna'
    ],
    'PLATAFORMA': [
      'Plato de Carga', 'Estructura', 'Topes de Carga',
      'Patas', 'Limpieza', 'Bordes y puntas'
    ],
    'CELDAS DE CARGA': [
      'Célula(s)', 'Cable(s)', 'Cubierta de Silicona'
    ],
  };

  // Configuración de campos de inspección
  final List<Map<String, dynamic>> _inspectionFields = [
    // Terminal
    {'label': 'Carcasa', 'section': 'TERMINAL'},
    {'label': 'Conector y Cables', 'section': 'TERMINAL'},
    {'label': 'Alimentación', 'section': 'TERMINAL'},
    {'label': 'Pantalla', 'section': 'TERMINAL'},
    {'label': 'Teclado', 'section': 'TERMINAL'},
    {'label': 'Bracket y columna', 'section': 'TERMINAL'},
    // Plataforma
    {'label': 'Plato de Carga', 'section': 'PLATAFORMA'},
    {'label': 'Estructura', 'section': 'PLATAFORMA'},
    {'label': 'Topes de Carga', 'section': 'PLATAFORMA'},
    {'label': 'Patas', 'section': 'PLATAFORMA'},
    {'label': 'Limpieza', 'section': 'PLATAFORMA'},
    {'label': 'Bordes y puntas', 'section': 'PLATAFORMA'},
    // Celdas de carga
    {'label': 'Célula(s)', 'section': 'CELDAS DE CARGA'},
    {'label': 'Cable(s)', 'section': 'CELDAS DE CARGA'},
    {'label': 'Cubierta de Silicona', 'section': 'CELDAS DE CARGA'},
  ];

  final List<Map<String, dynamic>> _environmentFields = [
    {
      'label': 'Entorno',
      'options': [
        'Seco',
        'Polvoso',
        'Muy polvoso',
        'Húmedo parcial',
        'Húmedo constante'
      ]
    },
    {
      'label': 'Nivelación',
      'options': [
        'Irregular',
        'Liso',
        'Nivelación correcta',
        'Nivelación deficiente'
      ]
    },
    {
      'label': 'Movilización',
      'options': [
        'Ninguna',
        'Dentro el área',
        'Fuera del área',
        'Fuera del sector'
      ]
    },
    {
      'label': 'Flujo de Pesadas',
      'options': [
        '1 a 10 por día',
        '10 a 50 por día',
        '50 a 100 por día',
        'Más de 100 por día'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _actualizarHora();
    _initializeFieldData();
    _initializeCommentControllers();
  }

  void _initializeFieldData() {
    // Inicializar datos de campos con valores por defecto
    for (final field in _inspectionFields) {
      _fieldData[field['label']] = {'value': '4 No aplica'};
    }
    for (final field in _environmentFields) {
      _fieldData[field['label']] = {'value': field['options'][0]};
    }
  }

  void _initializeCommentControllers() {
    final defaultComments = {
      'Carcasa': 'Sin Comentario',
      'Conector y Cables': 'Sin Comentario',
      'Alimentación': 'Sin Comentario',
      'Pantalla': 'Sin Comentario',
      'Teclado': 'Sin Comentario',
      'Bracket y columna': 'Sin Comentario',
      'Plato de Carga': 'Sin Comentario',
      'Estructura': 'Sin Comentario',
      'Topes de Carga': 'Sin Comentario',
      'Patas': 'Sin Comentario',
      'Limpieza': 'Sin Comentario',
      'Bordes y puntas': 'Sin Comentario',
      'Célula(s)': 'Sin Comentario',
      'Cable(s)': 'Sin Comentario',
      'Cubierta de Silicona': 'Sin Comentario',
      'Entorno': 'Sin Comentario',
      'Nivelación': 'Sin Comentario',
      'Movilización': 'Sin Comentario',
      'Flujo de Pesadas': 'Sin Comentario',
    };

    defaultComments.forEach((label, comment) {
      _commentControllers[label] = TextEditingController(text: comment);
    });
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _horaController.text = horaFormateada;
  }

  void _toggleSectorGoodState(String sector, bool isGood) {
    setState(() {
      _sectorGoodState[sector] = isGood;

      final fields = _sectorFields[sector]!;

      if (isGood) {
        // Aplicar "1 Bueno" como SUGERENCIA a todos los campos del sector
        for (final field in fields) {
          // Solo aplicar si el campo está vacío o en "No aplica"
          final currentValue = _fieldData[field]?['value'];
          if (currentValue == null || currentValue == '4 No aplica') {
            _fieldData[field] = {'value': '1 Bueno'};
          }

          // Sugerir comentario solo si está vacío
          if (_commentControllers[field]?.text == 'Sin Comentario' ||
              _commentControllers[field]?.text.isEmpty == true) {
            _commentControllers[field]?.text = 'En buen estado';
          }
        }
      } else {
        // Al desactivar, mantener los valores actuales pero quitar la sugerencia de comentario
        for (final field in fields) {
          if (_commentControllers[field]?.text == 'En buen estado') {
            _commentControllers[field]?.text = 'Sin Comentario';
          }
        }
      }

    });
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Presione nuevamente para retroceder. Los datos registrados se perderán.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Map<String, dynamic> _prepareDataForSave() {
    final data = <String, dynamic>{
      // ✅ AGREGAR estos campos al inicio
      'session_id': widget.sessionId,
      'cod_metrica': widget.codMetrica,
      'otst': widget.secaValue,

      // Campos existentes (MANTENER)
      'tipo_servicio': 'relevamiento de datos',
      'hora_inicio': _horaController.text,
      'hora_fin': _horaFinController.text,
      'comentario_general': _comentarioGeneralController.text,
      'recomendaciones': _selectedRecommendation ?? '',
    };

    // Resto del código existente (MANTENER)
    _fieldData.forEach((label, fieldData) {
      final key = _getFieldKey(label);
      data[key] = fieldData['value'] ?? '';
      data['${key}_comentario'] = _commentControllers[label]?.text ?? '';
      data['${key}_foto'] = fieldData['foto'] ?? '';
    });

    _extractMetrologicalTestsData(data);

    return data;
  }

  void _extractMetrologicalTestsData(Map<String, dynamic> data) {
    // Retorno a cero (siempre presente)
    final returnToZero = _metrologicalTestsData['return_to_zero'];
    if (returnToZero != null) {
      data['retorno_cero'] = returnToZero['value'] ?? '';
      data['carga_retorno_cero'] = returnToZero['load'] ?? '';
    }

    // Excentricidad
    final eccentricity = _metrologicalTestsData['eccentricity'];
    if (eccentricity != null) {
      data['tipo_plataforma'] = eccentricity['platform'] ?? '';
      data['puntos_ind'] = eccentricity['option'] ?? '';
      data['carga'] = eccentricity['load'] ?? '';

      final positions = eccentricity['positions'] ?? [];
      for (int i = 0; i < positions.length && i < 6; i++) {
        final position = i + 1;
        data['posicion$position'] = positions[i]['position'] ?? '';
        data['indicacion$position'] = positions[i]['indication'] ?? '';
        data['retorno$position'] = positions[i]['return'] ?? '';
      }
    }

    // Repetibilidad
    final repeatability = _metrologicalTestsData['repeatability'];
    if (repeatability != null) {
      final loads = repeatability['loads'] ?? [];
      for (int i = 0; i < loads.length && i < 3; i++) {
        final loadNum = i + 1;
        data['repetibilidad$loadNum'] = loads[i]['value'] ?? '';

        final indications = loads[i]['indications'] ?? [];
        for (int j = 0; j < indications.length && j < 10; j++) {
          final testNum = j + 1;
          data['indicacion${loadNum}_$testNum'] = indications[j]['value'] ?? '';
          data['retorno${loadNum}_$testNum'] = indications[j]['return'] ?? '';
        }
      }
    }

    // Linealidad
    final linearity = _metrologicalTestsData['linearity'];
    if (linearity != null) {
      final rows = linearity['rows'] ?? [];
      for (int i = 0; i < rows.length && i < 10; i++) {
        final pointNum = i + 1;
        data['lin$pointNum'] = rows[i]['lt'] ?? '';
        data['ind$pointNum'] = rows[i]['indicacion'] ?? '';
        data['retorno_lin$pointNum'] = rows[i]['retorno'] ?? '';
      }
    }
  }

  String _getFieldKey(String label) {
    final keyMap = {
      'Carcasa': 'carcasa',
      'Conector y Cables': 'conector_cables',
      'Alimentación': 'alimentacion',
      'Pantalla': 'pantalla',
      'Teclado': 'teclado',
      'Bracket y columna': 'bracket_columna',
      'Plato de Carga': 'plato_carga',
      'Estructura': 'estructura',
      'Topes de Carga': 'topes_carga',
      'Patas': 'patas',
      'Limpieza': 'limpieza',
      'Bordes y puntas': 'bordes_puntas',
      'Célula(s)': 'celulas',
      'Cable(s)': 'cables',
      'Cubierta de Silicona': 'cubierta_silicona',
      'Entorno': 'entorno',
      'Nivelación': 'nivelacion',
      'Movilización': 'movilizacion',
      'Flujo de Pesadas': 'flujo_pesas',
    };
    return keyMap[label] ?? label.toLowerCase().replaceAll(' ', '_');
  }

  void _loadSavedData(BuildContext context, Map<String, dynamic> data) {
    setState(() {
      // Cargar campos básicos
      _comentarioGeneralController.text = data['comentario_general'] ?? '';
      _selectedRecommendation = data['recomendaciones'];
      _horaController.text = data['hora_inicio'] ?? '';
      _horaFinController.text = data['hora_fin'] ?? '';

      // Cargar datos de inspección
      _fieldData.forEach((label, _) {
        final key = _getFieldKey(label);
        if (data[key] != null) {
          _fieldData[label]!['value'] = data[key];
        }
        final commentKey = '${key}_comentario';
        if (data[commentKey] != null && _commentControllers[label] != null) {
          _commentControllers[label]!.text = data[commentKey];
        }
        final fotoKey = '${key}_foto';
        if (data[fotoKey] != null && data[fotoKey].isNotEmpty) {
          _fieldData[label]!['foto'] = data[fotoKey];
        }
      });

      // Cargar datos de pruebas metrológicas
      _loadMetrologicalTestsData(data);

      _isDataSaved.value = true;
    });

    _showSnackBar(context, 'Datos recuperados exitosamente');
  }

  void _loadMetrologicalTestsData(Map<String, dynamic> data) {
    // Retorno a cero
    if (data['retorno_cero'] != null) {
      _metrologicalTestsData['return_to_zero'] = {
        'type': 'return_to_zero',
        'value': data['retorno_cero'],
        'load': data['carga_retorno_cero'] ?? '',
      };
    }

    // Excentricidad
    if (data['tipo_plataforma'] != null && data['tipo_plataforma'].isNotEmpty) {
      final positions = <Map<String, dynamic>>[];
      for (int i = 1; i <= 6; i++) {
        if (data['posicion$i'] != null) {
          positions.add({
            'position': data['posicion$i'],
            'indication': data['indicacion$i'] ?? '',
            'return': data['retorno$i'] ?? '',
          });
        }
      }

      _metrologicalTestsData['eccentricity'] = {
        'type': 'eccentricity',
        'platform': data['tipo_plataforma'],
        'option': data['puntos_ind'] ?? '',
        'load': data['carga'] ?? '',
        'positions': positions,
      };
    }

    // Repetibilidad
    final loads = <Map<String, dynamic>>[];
    for (int i = 1; i <= 3; i++) {
      if (data['repetibilidad$i'] != null) {
        final indications = <Map<String, dynamic>>[];
        for (int j = 1; j <= 10; j++) {
          if (data['indicacion${i}_$j'] != null) {
            indications.add({
              'value': data['indicacion${i}_$j'],
              'return': data['retorno${i}_$j'] ?? '0',
            });
          }
        }

        loads.add({
          'value': data['repetibilidad$i'],
          'indications': indications,
        });
      }
    }

    if (loads.isNotEmpty) {
      _metrologicalTestsData['repeatability'] = {
        'type': 'repeatability',
        'loads': loads,
      };
    }

    // Linealidad
    final linearityRows = <Map<String, dynamic>>[];
    for (int i = 1; i <= 10; i++) {
      if (data['lin$i'] != null) {
        linearityRows.add({
          'lt': data['lin$i'],
          'indicacion': data['ind$i'] ?? '',
          'retorno': data['retorno_lin$i'] ?? '0',
        });
      }
    }

    if (linearityRows.isNotEmpty) {
      _metrologicalTestsData['linearity'] = {
        'type': 'linearity',
        'rows': linearityRows,
      };
    }
  }

  Widget _buildDropdownFieldWithComment(
      BuildContext context,
      String label, {
        List<String>? customOptions,
      }) {
    final List<String> options =
        customOptions ?? ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'];

    String currentValue = _fieldData[label]?['value'] ?? options.first;
    if (!options.contains(currentValue)) {
      currentValue = options.first;
    }

    // Determinar si el campo está afectado por el switch del sector
    final sector = _getSectorForField(label);
    final isSectorInGoodState = _sectorGoodState[sector] ?? false;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentValue,
                decoration: _buildInputDecoration(label).copyWith(
                  hintText: isSectorInGoodState ? 'Valor sugerido: Buen Estado' : null,
                  filled: isSectorInGoodState,
                  fillColor: isSectorInGoodState ? Colors.green.withOpacity(0.1) : null,
                ),
                items: options.map((String value) {
                  if (customOptions != null) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }
                  return _buildStandardDropdownItem(value);
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _fieldData[label] ??= {};
                      _fieldData[label]!['value'] = newValue;
                    });
                  }
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
              icon: Stack(
                children: [
                  Icon(
                    _fieldPhotos[label]?.isNotEmpty == true
                        ? Icons.check_circle
                        : Icons.camera_alt_rounded,
                    color: _fieldPhotos[label]?.isNotEmpty == true
                        ? Colors.green
                        : null,
                  ),
                  if (_fieldPhotos[label]?.isNotEmpty == true)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_fieldPhotos[label]?.length ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _commentControllers[label],
                decoration: _buildInputDecoration('Comentario $label').copyWith(
                  hintText: isSectorInGoodState ? 'Comentario editable...' : null,
                  filled: isSectorInGoodState,
                  fillColor: isSectorInGoodState ? Colors.green.withOpacity(0.1) : null,
                ),
                onTap: () {
                  if (_commentControllers[label]?.text == 'Sin Comentario'){
                    _commentControllers[label]?.clear();
                  }
                },

              ),
            ),
            const SizedBox(width: 10),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),

        // Indicador visual cuando el campo tiene valor sugerido
        // En el diálogo de comentarios, agregar esta opción
      ],
    );
  }

// Método auxiliar para obtener el sector de un campo
  String _getSectorForField(String fieldLabel) {
    for (final sector in _sectorFields.keys) {
      if (_sectorFields[sector]!.contains(fieldLabel)) {
        return sector;
      }
    }
    return '';
  }

  DropdownMenuItem<String> _buildStandardDropdownItem(String value) {
    Color textColor;
    Icon? icon;

    switch (value) {
      case '1 Bueno':
        textColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case '2 Aceptable':
        textColor = Colors.orange;
        icon = const Icon(Icons.warning, color: Colors.orange);
        break;
      case '3 Malo':
        textColor = Colors.red;
        icon = const Icon(Icons.error, color: Colors.red);
        break;
      case '4 No aplica':
        textColor = Colors.grey;
        icon = const Icon(Icons.block, color: Colors.grey);
        break;
      default:
        textColor = Colors.black;
        icon = null;
    }

    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (icon != null) icon,
          if (icon != null) const SizedBox(width: 8),
          Text(value, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Future<void> _showCommentDialog(BuildContext context, String label) async {
    final sector = _getSectorForField(label);
    final isSectorInGoodState = _sectorGoodState[sector] ?? false;

    List<File> photos = _fieldPhotos[label] ?? [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AGREGAR FOTOGRAFÍA PARA: $label',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isSectorInGoodState)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Sector en modo "Buen Estado"',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? photo = await _imagePicker.pickImage(
                            source: ImageSource.camera);
                        if (photo != null) {
                          final fileName = basename(photo.path);
                          setState(() {
                            photos.add(File(photo.path));
                            _fieldPhotos[label] = photos;
                            _fieldData[label] ??= {};
                            _fieldData[label]!['foto'] = fileName;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
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
                      Text(
                        'Fotos tomadas: ${photos.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: photos.map((photo) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(photo, width: 100, height: 100),
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllDataAndPhotos(BuildContext context) async {
    // Guardar fotos si existen
    bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      final archive = Archive();
      _fieldPhotos.forEach((label, photos) {
        for (var i = 0; i < photos.length; i++) {
          final file = photos[i];
          final fileName = '${label}_${i + 1}.jpg';
          archive.addFile(
              ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
        }
      });

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName =
          '${widget.secaValue}_${widget.codMetrica}_relevamiento_de_datos_fotos.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null) {
          _showSnackBar(context, 'Fotos guardadas en $filePath');
        } else {
          _showSnackBar(context, 'No se seleccionó ninguna carpeta');
        }
      } catch (e) {
        _showSnackBar(context, 'Error al guardar el archivo: $e');
      }
    } else {
      _showSnackBar(
        context,
        'No se tomaron fotografías. Solo se guardarán los datos.',
        backgroundColor: Colors.orange,
      );
    }

    await _saveRelevamientoData(context);
  }

  Future<void> _saveRelevamientoData(BuildContext context) async {
    // Validaciones actuales (MANTENER)
    if (_comentarioGeneralController.text.isEmpty) {
      _showSnackBar(
        context,
        'Por favor complete el campo "Comentario General"',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_selectedRecommendation == null) {
      _showSnackBar(
        context,
        'Por favor seleccione una recomendación',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_horaFinController.text.isEmpty) {
      _showSnackBar(context, 'Por favor ingrese la hora final',
          backgroundColor: Colors.red);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        context,
        'Por favor complete todos los campos requeridos',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // ✅ USAR DatabaseHelperSop en lugar de abrir BD manualmente
      final dbHelper = DatabaseHelperSop();

      // Preparar datos
      final Map<String, dynamic> relevamientoData = _prepareDataForSave();

      // ✅ AGREGAR session_id y cod_metrica del widget
      relevamientoData['session_id'] = widget.sessionId;
      relevamientoData['cod_metrica'] = widget.codMetrica;
      relevamientoData['otst'] = widget.secaValue;

      // ✅ USAR upsertRegistro del helper (actualiza si existe, inserta si no)
      await dbHelper.upsertRegistro('relevamiento_de_datos', relevamientoData);

      _showSnackBar(
        context,
        'Datos guardados exitosamente',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        _isDataSaved.value = true;
      });
    } catch (e) {
      _showSnackBar(
        context,
        'Error al guardar los datos: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Error al guardar relevamiento: $e');
    }
  }

  Future<void> _loadCurrentSessionData(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelperSop();
      final db = await dbHelper.database;

      final savedData = await db.query(
        'relevamiento_de_datos',
        where: 'session_id = ? AND cod_metrica = ?',
        whereArgs: [widget.sessionId, widget.codMetrica],
      );

      if (savedData.isEmpty) {
        _showSnackBar(context, 'No hay datos guardados en esta sesión');
        return;
      }

      _loadSavedData(context, savedData.first);
    } catch (e) {
      _showSnackBar(context, 'Error al cargar datos: $e');
      debugPrint('Error al cargar datos: $e');
    }
  }

  void _showConfirmationDialog(BuildContext context, String sector, bool newValue) {
    final action = newValue ? 'activar' : 'desactivar';
    final message = newValue
        ? '¿Está seguro que desea sugerir "Buen Estado" para el sector $sector?\n\nSe sugerirá "1 Bueno" en todos los campos, pero podrá modificarlos individualmente después.'
        : '¿Está seguro que desea desactivar la sugerencia de "Buen Estado" para el sector $sector?\n\nLos campos mantendrán sus valores actuales.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'SUGERIR BUEN ESTADO - $sector'.toUpperCase(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleSectorGoodState(sector, newValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: newValue ? Colors.green : Colors.orange,
              ),
              child: Text(newValue ? 'Aplicar Sugerencia' : 'Desactivar Sugerencia'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor ?? Colors.grey,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$title:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black54,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildInspectionFields(BuildContext context) {
    List<Widget> widgets = [];
    String? currentSection;

    for (final field in _inspectionFields) {
      if (field['section'] != currentSection) {
        currentSection = field['section'];
        widgets.add(const SizedBox(height: 10.0));

        // Agregar el switch del sector antes de los campos
        if (_sectorFields.containsKey(currentSection)) {
          widgets.add(_buildSectorSwitch(context, currentSection!));
          widgets.add(const SizedBox(height: 10.0));
        }

        widgets.add(_buildSectionTitle(context, currentSection!));
        widgets.add(const SizedBox(height: 20.0));
      }

      // Modificar el campo para considerar el estado del switch
      widgets.add(_buildDropdownFieldWithComment(
          context,
          field['label']  // ✅ Solo pasa los parámetros requeridos
      ));
      widgets.add(const SizedBox(height: 20.0));
    }

    return Column(children: widgets);
  }

  Widget _buildEnvironmentFields(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20.0),
        const Text(
          'CONDICIONES GENERALES DEL ENTORNO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),
        ..._environmentFields
            .map((field) => Column(
                  children: [
                    _buildDropdownFieldWithComment(
                      context,
                      field['label'],
                      customOptions: field['options'],
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ))
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () async {
        return _onWillPop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SOPORTE TÉCNICO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5.0),
              Text(
                'CÓDIGO MET: ${widget.codMetrica}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
          elevation: 0,
          flexibleSpace: isDarkMode
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                )
              : null,
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'RELEVAMIENTO DE DATOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),

                // Hora de inicio
                TextFormField(
                  controller: _horaController,
                  decoration: _buildInputDecoration(
                    'Hora de Inicio de Servicio',
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'La hora se extrae automáticamente del sistema, este campo no es editable.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),
                const Text(
                  'CONDICIONES GENERALES DEL INSTRUMENTO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Campos de inspección
                _buildInspectionFields(context),

                // Campos de entorno
                _buildEnvironmentFields(context),

                const SizedBox(height: 20.0),


                // Pruebas metrológicas
                MetrologicalTestsContainer(
                  testType: 'INICIAL',
                  initialData: _metrologicalTestsData,
                  onTestsDataChanged: (data) {
                    setState(() {
                      _metrologicalTestsData = data;
                    });
                  },
                  selectedUnit: _selectedUnit,
                  onUnitChanged: (unit) {
                    setState(() {
                      _selectedUnit = unit;
                    });
                  },
                ),

                const SizedBox(height: 20.0),

                // Comentario general
                TextFormField(
                  controller: _comentarioGeneralController,
                  decoration: _buildInputDecoration('Comentario General'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese un comentario general';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20.0),

                // Recomendaciones
                DropdownButtonFormField<String>(
                  value: _selectedRecommendation,
                  decoration: _buildInputDecoration('Recomendación'),
                  items: [
                    'Calibración',
                    'Diagnostico',
                    'Mant Preventivo Regular',
                    'Mant Preventivo Avanzado',
                    'Mnt Correctivo',
                    'Ajustes Metrológicos',
                    'Ninguno'
                  ]
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRecommendation = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione una recomendación';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20.0),

                // Hora final
                TextFormField(
                  controller: _horaFinController,
                  decoration: _buildInputDecoration(
                    'Hora Final del Servicio',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () {
                        final ahora = DateTime.now();
                        final horaFormateada =
                            DateFormat('HH:mm:ss').format(ahora);
                        setState(() {
                          _horaFinController.text = horaFormateada;
                        });
                      },
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor registre la hora final';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Para registrar la hora final del servicio debe dar click al icono del reloj, este obtendrá la hora del sistema, una vez registrado este dato no se podrá modificar.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isSaveButtonPressed,
                        builder: (context, isSaving, child) {
                          return ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      _isSaveButtonPressed.value = true;
                                      FocusScope.of(context).unfocus();

                                      try {
                                        await _saveAllDataAndPhotos(context);
                                      } catch (e) {
                                        debugPrint('Error al guardar: $e');
                                        _showSnackBar(
                                            context, 'Error al guardar: $e',
                                            backgroundColor: Colors.red);
                                      } finally {
                                        _isSaveButtonPressed.value = false;
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF195375),
                            ),
                            child: isSaving
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Guardando...',
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  )
                                : const Text('GUARDAR DATOS'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isDataSaved,
                      builder: (context, isSaved, child) {
                        return Expanded(
                          child: ElevatedButton(
                            onPressed: isSaved ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FinServicioScreen(
                                    sessionId: widget.sessionId,
                                    secaValue: widget.secaValue,
                                    codMetrica: widget.codMetrica,
                                    nReca: widget.nReca,
                                  ),
                                ),
                              );
                            }
                            : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSaved
                                  ? const Color(0xFF167D1D)
                                  : Colors.grey,
                              elevation: 4.0,
                            ),
                            child: const Text('SIGUIENTE'),
                          ),
                        );
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        floatingActionButton: _buildSpeedDial(context, balanza),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context, dynamic balanza) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      iconTheme: const IconThemeData(color: Colors.black54),
      backgroundColor: const Color(0xFFead500),
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.info),
          backgroundColor: Colors.blueAccent,
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
                          _buildDetailContainer('Código Métrica', balanza.cod_metrica),
                          _buildDetailContainer('Unidades', balanza.unidad.toString()),
                          _buildDetailContainer('pmax1', balanza.cap_max1),
                          _buildDetailContainer('d1', balanza.d1.toString()),
                          _buildDetailContainer('e1', balanza.e1.toString()),
                          _buildDetailContainer('dec1', balanza.dec1.toString()),
                          _buildDetailContainer('pmax2', balanza.cap_max2),
                          _buildDetailContainer('d2', balanza.d2.toString()),
                          _buildDetailContainer('e2', balanza.e2.toString()),
                          _buildDetailContainer('dec2', balanza.dec2.toString()),
                          _buildDetailContainer('pmax3', balanza.cap_max3),
                          _buildDetailContainer('d3', balanza.d3.toString()),
                          _buildDetailContainer('e3', balanza.e3.toString()),
                          _buildDetailContainer('dec3', balanza.dec3.toString()),
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
          child: const Icon(Icons.restore),
          backgroundColor: Colors.green,
          label: 'Recuperar datos',
          onTap: () => _loadCurrentSessionData(context),
        ),
      ],
    );
  }

  Widget _buildDetailContainer(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSectorSwitch(BuildContext context, String sector) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sugerir "Buen Estado" para $sector',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Llenará automáticamente los campos con "1 Bueno"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _sectorGoodState[sector] ?? false,
              onChanged: (bool value) {
                _showConfirmationDialog(context, sector, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorStatusIndicator() {
    final activeSectors = _sectorGoodState.values.where((state) => state).length;
    if (activeSectors == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$activeSectors sector(es) en Buen Estado',
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    _comentarioGeneralController.dispose();
    _horaController.dispose();
    _horaFinController.dispose();

    _commentControllers.values.forEach((controller) {
      controller.dispose();
    });

    _isSaveButtonPressed.dispose();
    _isDataSaved.dispose();

    super.dispose();
  }
}
