import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:service_met/screens/soporte/componentes/test_container.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/verificaciones_internas/fin_servicio_vinternas.dart';
import 'package:sqflite/sqflite.dart';

class StacVerificacionesInternasScreen extends StatefulWidget {
  final String nReca;
  final String secaValue;
  final String sessionId;
  final String codMetrica;

  const StacVerificacionesInternasScreen({
    super.key,
    required this.nReca,
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
  });

  @override
  State<StacVerificacionesInternasScreen> createState() =>
      _StacVerificacionesInternasScreenState();
}

class _StacVerificacionesInternasScreenState
    extends State<StacVerificacionesInternasScreen> {
  final TextEditingController _reporteFallaController = TextEditingController();
  final TextEditingController _evaluacionController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final List<TextEditingController> _comentariosControllers = [];
  final List<FocusNode> _comentariosFocusNodes = [];
  int _comentariosCount = 0;

  late Map<String, dynamic> _initialTestsData;
  late Map<String, dynamic> _finalTestsData;
  late String _selectedUnitInicial;
  late String _selectedUnitFinal;

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final Map<String, List<File>> _fieldPhotos = {};
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);
  DateTime? _lastPressedTime;

  final List<File> _fotosGenerales = []; // Nueva lista para fotos generales

  String _excentricidadValue = 'Cumple';
  String _repetibilidadValue = 'Cumple';
  String _linealidadValue = 'Cumple';

  @override
  void initState() {
    super.initState();
    _actualizarHora();
    // Inicialización de unidades y datos de pruebas
    _selectedUnitInicial = 'kg';
    _selectedUnitFinal = 'kg';
    _initialTestsData = <String, dynamic>{};
    _finalTestsData = <String, dynamic>{};

    // Forzar actualización de la UI después de la inicialización
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });

    final List<String> camposEstadoGeneral = [
      'Vibración',
      'Polvo',
      'Temperatura',
      'Humedad',
      'Mesada',
      'Iluminación',
      'Limpieza de Fosa',
      'Estado de Drenaje',
      'Carcasa',
      'Teclado Fisico',
      'Display Fisico',
      'Fuente de poder',
      'Bateria operacional',
      'Bracket',
      'Teclado Operativo',
      'Display Operativo',
      'Contector de celda',
      'Bateria de memoria',
      'Limpieza general',
      'Golpes al terminal',
      'Nivelacion',
      'Limpieza receptor',
      'Golpes al receptor de carga',
      'Encendido',
      'Limitador de movimiento',
      'Suspensión',
      'Limitador de carga',
      'Celda de carga',
      'Tapa de caja sumadora',
      'Humedad Interna',
      'Estado de prensacables',
      'Estado de borneas'
    ];

    for (final campo in camposEstadoGeneral) {
      _fieldData[campo] = {
        'initial_value': '4 No aplica', // Estado inicial
        'solution_value': 'No aplica' // Estado final/solución
      };
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: textColor ?? Colors.black), // Texto blanco por defecto
        ),
        backgroundColor:
            backgroundColor ?? Colors.grey, // Fondo naranja por defecto
      ),
    );
  }

  void _agregarComentario(BuildContext context) {
    if (_comentariosCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 10 comentarios permitidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _comentariosControllers.add(TextEditingController());
      _comentariosFocusNodes.add(FocusNode());
      _comentariosCount++;
    });
  }

  void _eliminarComentario(int index) {
    setState(() {
      _comentariosControllers[index].dispose();
      _comentariosFocusNodes[index].dispose();
      _comentariosControllers.removeAt(index);
      _comentariosFocusNodes.removeAt(index);
      _comentariosCount--;
    });
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _horaController.text = horaFormateada;
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Presione nuevamente para retroceder. Los datos registrados se perderán.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveAllDataAndPhotos(BuildContext context) async {
    // Verificar si el widget está montado antes de continuar
    if (!mounted) return;

    _isSaveButtonPressed.value = true; // Mostrar indicador de carga

    try {
      // Verificar si hay fotos en alguno de los campos
      bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

      if (hasPhotos) {
        // Guardar las fotos en un archivo ZIP
        final archive = Archive();
        _fieldPhotos.forEach((label, photos) {
          for (var i = 0; i < photos.length; i++) {
            final file = photos[i];
            final fileName = '${label}_${i + 1}.jpg';
            archive.addFile(ArchiveFile(
                fileName, file.lengthSync(), file.readAsBytesSync()));
          }
        });

        final zipEncoder = ZipEncoder();
        final zipData = zipEncoder.encode(archive);

        final uint8ListData = Uint8List.fromList(zipData);
        final zipFileName =
            '${widget.otValue}_${widget.codMetrica}_diagnostico.zip';

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

      // Validar campos requeridos
      if (_horaController.text.isEmpty) {
        _showSnackBar(context, 'Por favor ingrese la hora de inicio',
            backgroundColor: Colors.red);
        return;
      }

      if (_horaFinController.text.isEmpty) {
        _showSnackBar(context, 'Por favor ingrese la hora final',
            backgroundColor: Colors.red);
        return;
      }

      // Guardar los datos en la base de datos
      await _saveAllMetrologicalTests(context);
    } catch (e) {
      _showSnackBar(context, 'Error al guardar: ${e.toString()}');
      debugPrint('Error al guardar: $e');
    } finally {
      if (mounted) {
        _isSaveButtonPressed.value =
            false; // Asegurarse de ocultar el indicador de carga
      }
    }
  }

  Future<void> _saveAllMetrologicalTests(BuildContext context) async {
    try {
      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      String getFotosString(String label) {
        return _fieldPhotos[label]?.map((f) => basename(f.path)).join(',') ??
            '';
      }

      final Map<String, dynamic> comentariosData = {};
      for (int i = 0; i < _comentariosControllers.length; i++) {
        comentariosData['comentario_${i + 1}'] =
            _comentariosControllers[i].text.isNotEmpty
                ? _comentariosControllers[i].text
                : null;
      }

      // Convertir todos los datos a un mapa para la base de datos
      final Map<String, dynamic> dbData = {
        'tipo_servicio': 'verificaciones internas',
        'cod_metrica': widget.codMetrica,
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,
        'reporte': _reporteFallaController.text,
        'evaluacion': _evaluacionController.text,
        'excentricidad_estado_general': _excentricidadValue,
        'repetibilidad_estado_general': _repetibilidadValue,
        'linealidad_estado_general': _linealidadValue,
        // Datos de pruebas metrológicas iniciales
        ..._convertTestDataToDbFormat(_initialTestsData, 'inicial'),

        //comentarios
        ...comentariosData,
        // Retorno a Cero
        'retorno_cero_inicial_valoracion':
            _fieldData['Retorno a cero']?['initial_value'] ?? '',
        'retorno_cero_inicial_carga':
            _fieldData['Retorno a cero']?['initial_load'] ?? '',
        'retorno_cero_inicial_unidad':
            _fieldData['Retorno a cero']?['initial_unit'] ?? '',
        // Sección Estructural
        // Entorno de instalación
      };

      // Verificar si ya existe un registro
      final existing = await db.query(
        'verificaciones_internas',
        where: 'cod_metrica = ?',
        whereArgs: [widget.codMetrica],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'verificaciones_internas',
          dbData,
          where: 'cod_metrica = ?',
          whereArgs: [widget.codMetrica],
        );
      } else {
        await db.insert(
          'verificaciones_internas',
          dbData,
        );
      }

      await db.close();
      _showSnackBar(
        context,
        'Datos guardados exitosamente',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _isDataSaved.value = true;
    } catch (e) {
      _showSnackBar(
        context,
        'Error al guardar: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Error al guardar: $e');
      _isDataSaved.value =
          false; // Asegurarse de mantenerlo en false si hay error
    }
  }

  Map<String, dynamic> _convertTestDataToDbFormat(
    Map<String, dynamic> testData,
    String testType,
  ) {
    final Map<String, dynamic> result = {};

    // Excentricidad
    if (testData['eccentricity'] != null) {
      final ecc = testData['eccentricity'];
      result['excentricidad_${testType}_tipo_plataforma'] =
          ecc['platform'] ?? '';
      result['excentricidad_${testType}_opcion_prueba'] = ecc['option'] ?? '';
      result['excentricidad_${testType}_carga'] =
          double.tryParse(ecc['load']?.toString() ?? '0') ?? 0;
      result['excentricidad_${testType}_ruta_imagen'] = ecc['imagePath'] ?? '';
      final positions = ecc['positions'] ?? [];
      result['excentricidad_${testType}_cantidad_posiciones'] =
          positions.length.toString();

      // Si es báscula de camión, guarda ida/vuelta
      if ((ecc['platform'] ?? '').toString().toLowerCase().contains('camion')) {
        for (int i = 0; i < positions.length; i++) {
          final pos = positions[i];
          final label =
              pos['label'] ?? (i < (positions.length ~/ 2) ? 'Ida' : 'Vuelta');
          final prefix =
              'excentricidad_${testType}_punto${i + 1}_${label.toLowerCase()}';
          final indicacion =
              double.tryParse(pos['indication']?.toString() ?? '0') ?? 0;
          final retorno =
              double.tryParse(pos['return']?.toString() ?? '0') ?? 0;

          result['${prefix}_numero'] = pos['position']?.toString() ?? '';
          result['${prefix}_indicacion'] = indicacion;
          result['${prefix}_retorno'] = retorno;
        }
      } else {
        // Lógica estándar para otras plataformas (máximo 6 posiciones)
        for (int i = 0; i < positions.length && i < 6; i++) {
          final pos = positions[i];
          final prefix = 'excentricidad_${testType}_pos${i + 1}';
          final indicacion =
              double.tryParse(pos['indication']?.toString() ?? '0') ?? 0;
          final posicion =
              double.tryParse(pos['position']?.toString() ?? '0') ?? 0;
          final retorno =
              double.tryParse(pos['return']?.toString() ?? '0') ?? 0;

          result['${prefix}_numero'] = pos['position']?.toString() ?? '';
          result['${prefix}_indicacion'] = indicacion;
          result['${prefix}_retorno'] = retorno;
          result['${prefix}_error'] = indicacion - posicion;
        }
      }
    }

    // Repetibilidad
    if (testData['repeatability'] != null) {
      final rep = testData['repeatability'];
      final loadCount = rep['repetibilityCount'] ?? 1;
      final rowCount = rep['rowCount'] ?? 3;

      result['repetibilidad_${testType}_cantidad_cargas'] =
          loadCount.toString();
      result['repetibilidad_${testType}_cantidad_pruebas'] =
          rowCount.toString();

      final loads = rep['loads'] ?? [];

      for (int i = 0; i < loads.length && i < 3; i++) {
        final load = loads[i];
        final loadPrefix = 'repetibilidad_${testType}_carga${i + 1}';
        result['${loadPrefix}_valor'] =
            double.tryParse(load['value']?.toString() ?? '0') ?? 0;

        final indications = load['indications'] ?? [];

        for (int j = 0; j < indications.length && j < 10; j++) {
          final indication =
              double.tryParse(indications[j]['value']?.toString() ?? '0') ?? 0;
          final returnVal =
              double.tryParse(indications[j]['return']?.toString() ?? '0') ?? 0;

          final testPrefix = '${loadPrefix}_prueba${j + 1}';
          result['${testPrefix}_indicacion'] = indication;
          result['${testPrefix}_retorno'] = returnVal;
        }
      }
    }

    return result;
  }

  Future<void> _showCommentDialog(BuildContext context, String label) async {
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    // No necesitamos marcar 'foto_tomada' ya que verificamos directamente _fieldPhotos
                  },
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

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'FINALIZAR SERVICIO',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          content: const Text('¿Estas seguro de los datos registrados?\n'
              'Si no es así, puedes volver atrás y corregirlos.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinServicioVinternasScreen(
                      dbName: widget.dbName,
                      dbPath: widget.dbPath,
                      otValue: widget.otValue,
                      selectedCliente: widget.selectedCliente,
                      selectedPlantaNombre: widget.selectedPlantaNombre,
                      codMetrica: widget.codMetrica,
                    ),
                  ),
                );
              },
              child: const Text('IR A FINALIZAR SERVICIO'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
              const SizedBox(height: 5),
              Text(
                'CLIENTE: ${widget.selectedPlantaNombre}\nCÓDIGO: ${widget.codMetrica}',
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
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                )
              : null,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
          child: Column(
            children: [
              const Text(
                'VERIFICACIONES INTERNAS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _horaController,
                decoration: InputDecoration(
                  labelText: 'Hora de Inicio de Servicio',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La hora se extrae automáticamente del sistema, este campo no es editable.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8.0),
              MetrologicalTestsContainer(
                testType: 'Inicial',
                initialData: _initialTestsData,
                onTestsDataChanged: (data) {
                  setState(() {
                    _initialTestsData = data;
                  });
                },
                selectedUnit: _selectedUnitInicial,
                onUnitChanged: (unit) {
                  setState(() {
                    _selectedUnitInicial = unit;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              const Text(
                'COMENTARIOS, OBSERVACIONES Y RECOMENDACIONES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf5b041),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Botón para agregar comentarios
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _agregarComentario(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Agregar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFeCA400),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _fotosGenerales.length >= 10
                        ? null
                        : () async {
                            final XFile? photo = await _imagePicker.pickImage(
                                source: ImageSource.camera);
                            if (photo != null) {
                              setState(() {
                                _fotosGenerales.add(File(photo.path));
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Foto agregada (${_fotosGenerales.length}/10)'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: Text('Fotos (${_fotosGenerales.length}/10)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // Lista de comentarios
              Column(
                children:
                    List.generate(_comentariosControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _comentariosControllers[index],
                            focusNode: _comentariosFocusNodes[index],
                            decoration: InputDecoration(
                              labelText: 'Comentario ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixText:
                                  '${_comentariosControllers[index].text.length}/200',
                              suffixStyle: TextStyle(
                                color:
                                    _comentariosControllers[index].text.length >
                                            200
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                            maxLength: 200,
                            maxLines: 3,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarComentario(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              if (_comentariosControllers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay comentarios agregados',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              const Text(
                'ESTADO GENERAL DEL INSTRUMENTO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15.0),
              DropdownButtonFormField<String>(
                value: _excentricidadValue,
                decoration: _buildInputDecoration(
                  'Excentricidad',
                ),
                items: const [
                  DropdownMenuItem(value: 'Cumple', child: Text('Cumple')),
                  DropdownMenuItem(
                      value: 'No cumple', child: Text('No cumple')),
                ],
                onChanged: (value) {
                  setState(() {
                    _excentricidadValue = value!;
                  });
                },
              ),
              const SizedBox(height: 15.0),
              DropdownButtonFormField<String>(
                value: _repetibilidadValue,
                decoration: _buildInputDecoration(
                  'Repetibilidad',
                ),
                items: const [
                  DropdownMenuItem(value: 'Cumple', child: Text('Cumple')),
                  DropdownMenuItem(
                      value: 'No cumple', child: Text('No cumple')),
                ],
                onChanged: (value) {
                  setState(() {
                    _repetibilidadValue = value!;
                  });
                },
              ),
              const SizedBox(height: 15.0),
              DropdownButtonFormField<String>(
                value: _linealidadValue,
                decoration: _buildInputDecoration(
                  'Linealidad',
                ),
                items: const [
                  DropdownMenuItem(value: 'Cumple', child: Text('Cumple')),
                  DropdownMenuItem(
                      value: 'No cumple', child: Text('No cumple')),
                ],
                onChanged: (value) {
                  setState(() {
                    _linealidadValue = value!;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _horaFinController,
                decoration: InputDecoration(
                  labelText: 'Hora Final del Servicio',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () {
                      final ahora = DateTime.now();
                      final horaFormateada =
                          DateFormat('HH:mm:ss').format(ahora);
                      _horaFinController.text = horaFormateada;
                    },
                  ),
                ),
                readOnly: true,
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
                              : () => _saveAllDataAndPhotos(context),
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
                          onPressed: isSaved
                              ? () => _showConfirmationDialog(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isSaved ? const Color(0xFF167D1D) : Colors.grey,
                          ),
                          child: const Text('SIGUIENTE'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon, // Agregar el parámetro suffixIcon
    );
  }

  @override
  void dispose() {
    for (var controller in _comentariosControllers) {
      controller.dispose();
    }
    for (var focusNode in _comentariosFocusNodes) {
      focusNode.dispose();
    }
    _horaController.dispose();
    _horaFinController.dispose();
    _isSaveButtonPressed.dispose();
    _isDataSaved.dispose();
    super.dispose();
  }
}
