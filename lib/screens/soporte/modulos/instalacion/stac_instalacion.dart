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
import 'package:service_met/screens/soporte/modulos/instalacion/fin_servicio_instalacion.dart';

import '../../../../database/soporte_tecnico/database_helper_instalacion.dart';

class StacInstalacionScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName; // ✅ AGREGAR
  final String clienteId; // ✅ AGREGAR
  final String plantaCodigo; // ✅ AGREGAR
  const StacInstalacionScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName, // ✅ AGREGAR
    required this.clienteId, // ✅ AGREGAR
    required this.plantaCodigo, // ✅ AGREGAR
  });

  @override
  State<StacInstalacionScreen> createState() => _StacInstalacionScreenState();
}

class _StacInstalacionScreenState extends State<StacInstalacionScreen> {
  final TextEditingController _entornoComentarioController = TextEditingController();
  final TextEditingController _nivelacionComentarioController = TextEditingController();
  final TextEditingController _movilizacionComentarioController = TextEditingController();
  final TextEditingController _flujoPesadasComentarioController = TextEditingController();
  final TextEditingController _celulasComentarioController = TextEditingController();
  final TextEditingController _cablesComentarioController = TextEditingController();
  final TextEditingController _cubiertaSiliconaComentarioController = TextEditingController();
  final TextEditingController _flujoPesasComentarioController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final List<TextEditingController> _comentariosControllers = [];
  final List<FocusNode> _comentariosFocusNodes = [];
  int _comentariosCount = 0;

  String? _selectedRecommendation;
  String? _selectedFisico;
  String? _selectedOperacional;
  String? _selectedMetrologico;

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
            '${widget.secaValue}_${widget.codMetrica}_ajustes_verificaciones.zip';

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
      // ✅ Usar DatabaseHelperSop
      final dbHelper = DatabaseHelperInstalacion();

      // Preparar comentarios
      final Map<String, dynamic> comentariosData = {};
      for (int i = 0; i < _comentariosControllers.length; i++) {
        comentariosData['comentario_${i + 1}'] =
        _comentariosControllers[i].text.isNotEmpty
            ? _comentariosControllers[i].text
            : null;
      }

      // ✅ Convertir todos los datos a un mapa para la base de datos
      final Map<String, dynamic> dbData = {
        // ✅ AGREGAR CAMPOS CLAVE
        'session_id': widget.sessionId,
        'cod_metrica': widget.codMetrica,
        'otst': widget.secaValue,

        // Campos existentes
        'tipo_servicio': 'instalacion',
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,

        // Datos de pruebas metrológicas iniciales
        ..._convertTestDataToDbFormat(_initialTestsData, 'inicial'),

        // Comentarios
        ...comentariosData,

        // Retorno a Cero (si existe)
        'retorno_cero_inicial_valoracion': _fieldData['Retorno a cero']?['initial_value'] ?? '',
        'retorno_cero_inicial_carga': _fieldData['Retorno a cero']?['initial_load'] ?? '',
        'retorno_cero_inicial_unidad': _fieldData['Retorno a cero']?['initial_unit'] ?? '',

        // Condiciones del entorno
        'entorno_valor': _fieldData['Entorno']?['value'] ?? '',
        'entorno_comentario': _entornoComentarioController.text,
        'nivelacion_valor': _fieldData['Nivelación']?['value'] ?? '',
        'nivelacion_comentario': _nivelacionComentarioController.text,
        'movilizacion_valor': _fieldData['Movilización']?['value'] ?? '',
        'movilizacion_comentario': _movilizacionComentarioController.text,
        'flujo_pesadas_valor': _fieldData['Flujo de Pesadas']?['value'] ?? '',
        'flujo_pesadas_comentario': _flujoPesadasComentarioController.text,
      };

      // ✅ Agregar fotos de campos si existen
      _fieldData.forEach((label, fieldData) {
        final fotos = _fieldPhotos[label]?.map((f) => basename(f.path)).join(',') ?? '';
        if (fotos.isNotEmpty) {
          final key = _getFieldKey(label);
          dbData['${key}_foto'] = fotos;
        }
      });

      // ✅ USAR UPSERT (actualiza si existe, inserta si no)
      await dbHelper.upsertRegistroRelevamiento(dbData);

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
        'Error al guardar: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Error al guardar: $e');
      _isDataSaved.value = false;
    }
  }

  String _getFieldKey(String label) {
    // Convertir etiquetas a claves de base de datos
    return label
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('/', '_');
  }

  Map<String, dynamic> _convertTestDataToDbFormat(
    Map<String, dynamic> testData,
    String testType,
  ) {
    final Map<String, dynamic> result = {};

    // Retorno a Cero
    if (testData['return_to_zero'] != null) {
      final rtz = testData['return_to_zero'];
      result['retorno_cero_${testType}_valoracion'] = rtz['value'] ?? '';
      result['retorno_cero_${testType}_carga'] =
          double.tryParse(rtz['load']?.toString() ?? '0') ?? 0;
      result['retorno_cero_${testType}_unidad'] = rtz['unit'] ?? 'kg';
    }

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

      for (int i = 0; i < positions.length && i < 6; i++) {
        final pos = positions[i];
        final prefix = 'excentricidad_${testType}_pos${i + 1}';
        final indicacion =
            double.tryParse(pos['indication']?.toString() ?? '0') ?? 0;
        final posicion =
            double.tryParse(pos['position']?.toString() ?? '0') ?? 0;
        final retorno = double.tryParse(pos['return']?.toString() ?? '0') ?? 0;

        result['${prefix}_numero'] = pos['position']?.toString() ?? '';
        result['${prefix}_indicacion'] = indicacion;
        result['${prefix}_retorno'] = retorno;
        result['${prefix}_error'] = indicacion - posicion;
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
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
              const SizedBox(height: 5),
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
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                )
              : null,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'INSTALACIÓN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20.0),
              const Text(
                'CONDICIONES GENERALES DEL ENTORNO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4a85cb), // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                context,
                'Entorno',
                _entornoComentarioController,
                customOptions: [
                  'Seco',
                  'Polvoso',
                  'Muy polvoso',
                  'Húmedo parcial',
                  'Húmedo constante'
                ],
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                context,
                'Nivelación',
                _nivelacionComentarioController,
                customOptions: [
                  'Irregular',
                  'Liso',
                  'Nivelación correcta',
                  'Nivelación deficiente'
                ],
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                context,
                'Movilización',
                _movilizacionComentarioController,
                customOptions: [
                  'Ninguna',
                  'Dentro el área',
                  'Fuera del área',
                  'Fuera del sector'
                ],
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                context,
                'Flujo de Pesadas',
                _flujoPesadasComentarioController,
                customOptions: [
                  '1 a 10 por día',
                  '10 a 50 por día',
                  '50 a 100 por día',
                  'Más de 100 por día'
                ],
              ),
              // Pruebas Metrológicas Iniciales
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

              // Estado Final de la Balanza
              const SizedBox(height: 20.0),
              const Text(
                'COMENTARIOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf5b041),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Botón para agregar comentarios
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _agregarComentario(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Agregar Comentario',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFeCA400),
                    foregroundColor: Colors.white,
                  ),
                ),
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
                          onPressed: isSaved ? ()
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FinServicioInstalacionScreen(
                                  nReca: widget.nReca,
                                  secaValue: widget.secaValue,
                                  sessionId: widget.sessionId,
                                  codMetrica: widget.codMetrica,
                                  userName: widget.userName,
                                  clienteId: widget.clienteId,
                                  plantaCodigo: widget.plantaCodigo,
                                  tableName: 'instalacion',
                                ),
                              ),
                            );
                          }
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

  Widget _buildDropdownFieldWithComment(
    BuildContext context,
    String label,
    TextEditingController commentController, {
    List<String>? customOptions,
  }) {
    // Usar las opciones personalizadas si se proporcionan, de lo contrario usar las estándar
    final List<String> options =
        customOptions ?? ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'];

    // Asegurarse de que el valor actual existe en las opciones
    String currentValue = _fieldData[label]?['value'] ?? options.first;
    if (!options.contains(currentValue)) {
      currentValue = options.first;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentValue, // Usar el valor validado
                decoration: _buildInputDecoration(label),
                items: options.map((String value) {
                  // Solo mostrar texto simple si son opciones personalizadas
                  if (customOptions != null) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case '1 Bueno':
                      textColor = Colors.green;
                      icon =
                          const Icon(Icons.check_circle, color: Colors.green);
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
                controller: commentController,
                decoration: _buildInputDecoration('Comentario $label'),
                onTap: () {
                  if (commentController.text == 'Sin Comentario') {
                    commentController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
