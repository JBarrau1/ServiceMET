import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../models/balanza_model.dart';
import '../../../provider/balanza_provider.dart';
import '../servicio_screen.dart';

class IdenBalanzaQrScreen extends StatefulWidget {
  final String secaValue;
  final String sessionId;
  final String dbName;
  final bool loadFromSharedPreferences;

  const IdenBalanzaQrScreen({
    super.key,
    required this.dbName,
    required this.sessionId,
    required this.secaValue,
    required this.loadFromSharedPreferences,
  });

  @override
  _IdenBalanzaQrScreenState createState() => _IdenBalanzaQrScreenState();
}

class _IdenBalanzaQrScreenState extends State<IdenBalanzaQrScreen> {
  List<Map<String, dynamic>> balanzas = [];
  List<TextEditingController> _cantidadControllers = [];
  Map<String, dynamic>? selectedBalanza;
  Map<String, dynamic>? lastServiceData;
  String? errorMessage;
  String? _cliente;
  String? _codBalanza;
  bool _isDataSaved =
      false; // Variable para rastrear si los datos se han guardado
  DatabaseHelper? _dbHelper;
  List<dynamic> equipos = [];
  List<dynamic> filteredEquipos = [];
  List<Map<String, dynamic>> selectedEquipos = [];
  DateTime? _lastPressedTime;
  bool isNewBalanza = false; // Variable para controlar si es una balanza nueva

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final TextEditingController _codMetricaController = TextEditingController();
  final TextEditingController _codInternoController = TextEditingController();
  final TextEditingController _tipoEquipoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _nCeldasController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _d1Controller = TextEditingController();
  final TextEditingController _e1Controller = TextEditingController();
  final TextEditingController _dec1Controller = TextEditingController();
  final TextEditingController _pmax2Controller = TextEditingController();
  final TextEditingController _d2Controller = TextEditingController();
  final TextEditingController _e2Controller = TextEditingController();
  final TextEditingController _dec2Controller = TextEditingController();
  final TextEditingController _pmax3Controller = TextEditingController();
  final TextEditingController _d3Controller = TextEditingController();
  final TextEditingController _e3Controller = TextEditingController();
  final TextEditingController _dec3Controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nRecaController = TextEditingController();
  final TextEditingController _stickerController = TextEditingController();
  final TextEditingController _catBalanzaController = TextEditingController();
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _isNextButtonVisible = ValueNotifier<bool>(false);

  final Map<String, List<File>> _balanzaPhotos = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool _fotosTomadas = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEquipos);
    _fetchEquipos();

    _fetchClienteFromDatabase();

    _cantidadControllers = [];
  }

// Nuevo método para cargar datos de la balanza
  void _loadBalanzaData(Map<String, dynamic> balanzaData) {
    setState(() {
      selectedBalanza = balanzaData;
      _codMetricaController.text = balanzaData['cod_metrica']?.toString() ?? '';
      _catBalanzaController.text = balanzaData['categoria']?.toString() ?? '';
      _codInternoController.text = balanzaData['cod_interno']?.toString() ?? '';
      _nCeldasController.text = balanzaData['n_celdas']?.toString() ?? '';
      _tipoEquipoController.text =
          balanzaData['tipo_instrumento']?.toString() ?? '';
      _marcaController.text = balanzaData['marca']?.toString() ?? '';
      _modeloController.text = balanzaData['modelo']?.toString() ?? '';
      _serieController.text = balanzaData['serie']?.toString() ?? '';
      _unidadController.text = balanzaData['unidad']?.toString() ?? '';
      _ubicacionController.text = balanzaData['ubicacion']?.toString() ?? '';
      _pmax1Controller.text = balanzaData['cap_max1']?.toString() ?? '';
      _d1Controller.text = balanzaData['d1']?.toString() ?? '';
      _e1Controller.text = balanzaData['e1']?.toString() ?? '';
      _dec1Controller.text = balanzaData['dec1']?.toString() ?? '';
      _pmax2Controller.text = balanzaData['cap_max2']?.toString() ?? '';
      _d2Controller.text = balanzaData['d2']?.toString() ?? '';
      _e2Controller.text = balanzaData['e2']?.toString() ?? '';
      _dec2Controller.text = balanzaData['dec2']?.toString() ?? '';
      _pmax3Controller.text = balanzaData['cap_max3']?.toString() ?? '';
      _d3Controller.text = balanzaData['d3']?.toString() ?? '';
      _e3Controller.text = balanzaData['e3']?.toString() ?? '';
      _dec3Controller.text = balanzaData['dec3']?.toString() ?? '';
    });
  }

  void _showNewBalanzaForm() {
    setState(() {
      isNewBalanza = true;
      selectedBalanza = null; // Limpiar la balanza seleccionada
      _clearBalanzaFields(); // Limpiar los campos del formulario
      _codMetricaController.text =
          'NUEVA'; // Llenar el campo de Código Metrica con "NUEVA"
    });
  }

  void _clearBalanzaFields() {
    _catBalanzaController.clear();
    _codMetricaController.clear();
    _codInternoController.clear();
    _tipoEquipoController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _serieController.clear();
    _unidadController.clear();
    _ubicacionController.clear();
    _pmax1Controller.clear();
    _d1Controller.clear();
    _e1Controller.clear();
    _dec1Controller.clear();
    _pmax2Controller.clear();
    _d2Controller.clear();
    _e2Controller.clear();
    _dec2Controller.clear();
    _pmax3Controller.clear();
    _d3Controller.clear();
    _e3Controller.clear();
    _dec3Controller.clear();
  }

  Future<void> _takePhoto(BuildContext context) async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _balanzaPhotos['identificacion'] ??= [];
        if (_balanzaPhotos['identificacion']!.length < 5) {
          _balanzaPhotos['identificacion']!.add(File(photo.path));
          _fotosTomadas = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máximo 5 fotos alcanzado')),
          );
        }
      });
    }
  }

  Future<void> _savePhotosToZip(BuildContext context) async {
    if (_balanzaPhotos['identificacion']?.isNotEmpty ?? false) {
      final archive = Archive();
      for (var i = 0; i < _balanzaPhotos['identificacion']!.length; i++) {
        final file = _balanzaPhotos['identificacion']![i];
        final fileName = 'identificacion_${i + 1}.jpg';
        archive.addFile(
            ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName =
          '${widget.secaValue}_${_codMetricaController.text}_FotosIdentificacionInicial.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        await FlutterFileDialog.saveFile(params: params);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar fotos: $e')),
        );
      }
    }
  }

  Future<void> _loadBalanzasFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final balanzasJson = prefs.getString('saved_balanzas');
    if (balanzasJson != null) {
      setState(() {
        balanzas = List<Map<String, dynamic>>.from(jsonDecode(balanzasJson));
      });
    }
  }

  Future<List<String>> _getCodMetricaFromDatabase() async {
    String path = join(await getDatabasesPath(), '${widget.dbName}.db');
    final db = await openDatabase(path);
    final List<Map<String, dynamic>> results = await db.query(
      'registros_calibracion',
      columns: ['cod_metrica'],
    );
    await db.close();
    return results.map((row) => row['cod_metrica'].toString()).toList();
  }

  void _showBalanzasDialog(BuildContext context) async {
    final List<String> codMetricaList = await _getCodMetricaFromDatabase();

    if (balanzas.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Alerta',
              style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text(
                'El cliente seleccionado no tiene balanzas disponibles. puede registrar una nueva, esta no se guardara en el DATAMET.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(
              child: Text(
                'BALANZAS DISPONIBLES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: balanzas.map((balanza) {
                  final bool isChecked = codMetricaList
                      .contains(balanza['cod_metrica'].toString());
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      title: Text(
                        'CÓDIGO METRICA: ${balanza['cod_metrica']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        'Marca: ${balanza['marca']}\n'
                        'Modelo: ${balanza['modelo']}\n'
                        'Serie: ${balanza['serie']}\n'
                        'Código Interno: ${balanza['cod_interno']}\n'
                        'Categoria: ${balanza['instrumento']}',
                      ),
                      trailing: isChecked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        _selectBalanza(context, balanza);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveDataToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cliente', _cliente ?? '');
    final balanzasJson = jsonEncode(balanzas);
    await prefs.setString('saved_balanzas', balanzasJson);
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    // Validaciones previas
    if (_nRecaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el N° Reca')),
      );
      return;
    }

    if (_stickerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el N° de Sticker')),
      );
      return;
    }

    if (_ubicacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingrese la ubicación de la balanza')),
      );
      return;
    }

    if (selectedEquipos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor seleccione al menos una pesa patrón')),
      );
      return;
    }

    // Validar que todas las cantidades de las pesas patrón sean válidas
    for (int i = 0; i < selectedEquipos.length; i++) {
      final cantidad = selectedEquipos[i]['cantidad']?.trim() ?? '';
      final cantidadNum = int.tryParse(cantidad) ?? 0;

      if (cantidad.isEmpty || cantidadNum <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Por favor ingrese una cantidad válida para la pesa patrón ${i + 1}')),
        );
        return;
      }
    }

    // Si es una balanza nueva, mostrar un diálogo de confirmación
    if (isNewBalanza) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'REGISTRANDO BALANZA NUEVA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            content: const Text(
              'Está registrando una balanza nueva. Revise bien los datos antes de continuar.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.yellow
                        : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false); // No confirmar
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirmar
                },
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return; // Si el usuario cancela, no continuar
      }
    } else if (selectedBalanza == null) {
      // Si no es una balanza nueva y no se ha seleccionado una balanza, mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione una balanza')),
      );
      return;
    }

    // Guardar los datos en la base de datos
    try {
      if (_balanzaPhotos['identificacion']?.isNotEmpty ?? false) {
        await _savePhotosToZip(context);
      }

      String path = join(await getDatabasesPath(), '${widget.dbName}.db');
      final db = await openDatabase(path);

      final registro = {
        'foto_balanza': _fotosTomadas ? 1 : 0,
        'cod_metrica': _codMetricaController.text.trim().isEmpty
            ? ''
            : _codMetricaController.text.trim(),
        'categoria_balanza': _catBalanzaController.text.trim().isEmpty
            ? ''
            : _catBalanzaController.text.trim(),
        'cod_int': _codInternoController.text.trim().isEmpty
            ? ''
            : _codInternoController.text.trim(),
        'tipo_equipo': _tipoEquipoController.text.trim().isEmpty
            ? ''
            : _tipoEquipoController.text.trim(),
        'marca': _marcaController.text.trim().isEmpty
            ? ''
            : _marcaController.text.trim(),
        'modelo': _modeloController.text.trim().isEmpty
            ? ''
            : _modeloController.text.trim(),
        'serie': _serieController.text.trim().isEmpty
            ? ''
            : _serieController.text.trim(),
        'unidades': _unidadController.text.trim().isEmpty
            ? ''
            : _unidadController.text.trim(),
        'ubicacion': _ubicacionController.text.trim().isEmpty
            ? ''
            : _ubicacionController.text.trim(),
        'cap_max1': _pmax1Controller.text.trim().isEmpty
            ? ''
            : _pmax1Controller.text.trim(),
        'd1':
            _d1Controller.text.trim().isEmpty ? '' : _d1Controller.text.trim(),
        'e1':
            _e1Controller.text.trim().isEmpty ? '' : _e1Controller.text.trim(),
        'dec1': _dec1Controller.text.trim().isEmpty
            ? ''
            : _dec1Controller.text.trim(),
        'cap_max2': _pmax2Controller.text.trim().isEmpty
            ? ''
            : _pmax2Controller.text.trim(),
        'd2':
            _d2Controller.text.trim().isEmpty ? '' : _d2Controller.text.trim(),
        'e2':
            _e2Controller.text.trim().isEmpty ? '' : _e2Controller.text.trim(),
        'dec2': _dec2Controller.text.trim().isEmpty
            ? ''
            : _dec2Controller.text.trim(),
        'cap_max3': _pmax3Controller.text.trim().isEmpty
            ? ''
            : _pmax3Controller.text.trim(),
        'd3':
            _d3Controller.text.trim().isEmpty ? '' : _d3Controller.text.trim(),
        'e3':
            _e3Controller.text.trim().isEmpty ? '' : _e3Controller.text.trim(),
        'dec3': _dec3Controller.text.trim().isEmpty
            ? ''
            : _dec3Controller.text.trim(),
        'n_reca': _nRecaController.text.trim().isEmpty
            ? ''
            : _nRecaController.text.trim(),
        'sticker': _stickerController.text.trim().isEmpty
            ? ''
            : _stickerController.text.trim(),
      };

      // Guardar los datos de los equipos seleccionados
      // Dentro de _saveDataToDatabase, modifica la parte donde guardas los equipos:
      for (int i = 0; i < selectedEquipos.length; i++) {
        final equipo = selectedEquipos[i];

        if (equipo['tipo'] == 'pesa') {
          // Guardar en equipos 1-5
          registro['equipo${i + 1}'] = equipo['cod_instrumento']?.trim() ?? '';
          registro['certificado${i + 1}'] = equipo['cert_fecha']?.trim() ?? '';
          registro['ente_calibrador${i + 1}'] =
              equipo['ente_calibrador']?.trim() ?? '';
          registro['estado${i + 1}'] = equipo['estado']?.trim() ?? '';
          registro['cantidad${i + 1}'] = equipo['cantidad']?.trim() ?? '1';
        } else if (equipo['tipo'] == 'termohigrometro') {
          // Guardar en equipos 6-7
          final termoIndex = selectedEquipos
              .where((e) => e['tipo'] == 'termohigrometro')
              .toList()
              .indexOf(equipo);
          registro['equipo${6 + termoIndex}'] =
              equipo['cod_instrumento']?.trim() ?? '';
          registro['certificado${6 + termoIndex}'] =
              equipo['cert_fecha']?.trim() ?? '';
          registro['ente_calibrador${6 + termoIndex}'] =
              equipo['ente_calibrador']?.trim() ?? '';
          registro['estado${6 + termoIndex}'] = equipo['estado']?.trim() ?? '';
          registro['cantidad${6 + termoIndex}'] =
              '1'; // Cantidad fija para termohigrómetros
        }
      }

      // Actualizar la base de datos
      await db.update(
        'registros_calibracion',
        registro,
        where: 'id = ?',
        whereArgs: [1],
      );

      setState(() {
        _isDataSaved = true;
      });

      // Guardar los datos en SharedPreferences
      await _saveDataToSharedPreferences();

      _showSnackBar(context,
          'Datos de la balanza e instrumentos de calibración guardados correctamente');
    } catch (e) {
      _showSnackBar(context, 'Ocurrió un error', isError: true);
    }
    _isNextButtonVisible.value = true;
  }

  Future<void> _fetchClienteFromDatabase() async {
    try {
      String path = join(await getDatabasesPath(), '${widget.dbName}.db');
      final db = await openDatabase(path);

      // Consulta para obtener el valor de la columna 'cliente'
      final List<Map<String, dynamic>> result = await db.query(
        'registros_calibracion',
        columns: ['cliente'],
        where: 'id = ?',
        whereArgs: [1], // Suponiendo que el registro que buscas tiene id = 1
      );

      if (result.isNotEmpty) {
        setState(() {
          _cliente =
              result.first['cliente']?.toString() ?? 'Cliente no encontrado';
        });
      } else {
        setState(() {
          _cliente = 'Cliente no encontrado';
        });
      }

      await db.close();
    } catch (e) {
      setState(() {
        _cliente = 'Error al obtener cliente: $e';
      });
    }
  }

  Future<void> _fetchBalanzas(String plantaCodigo) async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      // Consulta para obtener los códigos métrica que coincidan con el patrón de plantaCodigo
      final List<Map<String, dynamic>> balanzasList = await db.query(
        'balanzas',
        where: 'cod_metrica LIKE ?',
        whereArgs: ['$plantaCodigo%'],
      );

      List<Map<String, dynamic>> processedBalanzas = [];

      for (var balanza in balanzasList) {
        final codMetrica = balanza['cod_metrica'].toString();

        // Consultar la tabla 'inf' para obtener los detalles adicionales
        final List<Map<String, dynamic>> infDetails = await db.query(
          'inf',
          where: 'cod_metrica = ?',
          whereArgs: [codMetrica],
        );

        if (infDetails.isNotEmpty) {
          // Combinar datos de ambas tablas
          processedBalanzas.add({
            ...balanza, // Datos de la tabla balanzas
            ...infDetails.first, // Datos de la tabla inf
          });
        } else {
          // Si no hay datos en la tabla inf, usar solo los de balanzas
          processedBalanzas.add(balanza);
        }
      }

      setState(() {
        balanzas = processedBalanzas;
        errorMessage = null;
      });

      await db.close();
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener balanzas: $e';
      });
    }
  }

  Future<void> _fetchEquipos() async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      // Obtener todos los equipamientos que no estén DESACTIVADOS
      final List<Map<String, dynamic>> equiposList = await db.query(
        'equipamientos',
        where: "estado != 'DESACTIVADO'",
      );

      setState(() {
        equipos = equiposList;
        filteredEquipos = equiposList;
        errorMessage = null;
      });

      await db.close();
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los equipos de ayuda: $e';
      });
    }
  }

  void _filterEquipos() {
    setState(() {
      filteredEquipos = equipos
          .where((equipo) => equipo['cod_instrumento']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _showPesasPatronSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final pesasPatron = equipos.where((equipo) {
          final instrumento = equipo['instrumento']?.toString() ?? '';
          return !instrumento.contains('Termohigrómetro') &&
              !instrumento.contains('Termohigrobarómetro');
        }).toList();

        final Map<String, Map<String, dynamic>> uniquePesas = {};
        for (var pesa in pesasPatron) {
          final codInstrumento = pesa['cod_instrumento'].toString();
          final certFecha = DateTime.parse(pesa['cert_fecha']);

          if (!uniquePesas.containsKey(codInstrumento)) {
            uniquePesas[codInstrumento] = pesa;
          } else {
            final currentFecha =
                DateTime.parse(uniquePesas[codInstrumento]!['cert_fecha']);
            if (certFecha.isAfter(currentFecha)) {
              uniquePesas[codInstrumento] = pesa;
            }
          }
        }

        final List<Map<String, dynamic>> pesasUnicas =
            uniquePesas.values.toList();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                const SizedBox(height: 16.0),
                const Text(
                  'SELECCIONAR PESAS PATRÓN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Seleccione las pesas patrón para el servicio (máximo 5)',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: pesasUnicas.length,
                    itemBuilder: (context, index) {
                      final equipo = pesasUnicas[index];
                      final certFecha = DateTime.parse(equipo['cert_fecha']);
                      final difference =
                          DateTime.now().difference(certFecha).inDays;

                      return CheckboxListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${equipo['cod_instrumento']}'),
                            Text(
                              'Certificado: ${equipo['cert_fecha']} ($difference días)',
                              style: TextStyle(
                                fontSize: 12,
                                color: difference > 365
                                    ? Colors.red
                                    : difference > 300
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                            'Ente calibrador: ${equipo['ente_calibrador']}'),
                        value: selectedEquipos.any((e) =>
                            e['cod_instrumento'] == equipo['cod_instrumento'] &&
                            e['tipo'] == 'pesa'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              if (selectedEquipos
                                      .where((e) => e['tipo'] == 'pesa')
                                      .length <
                                  5) {
                                selectedEquipos.add({
                                  ...equipo,
                                  'cantidad': '',
                                  'tipo': 'pesa'
                                });
                                _cantidadControllers
                                    .add(TextEditingController());
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Máximo 5 pesas patrón permitidas')),
                                );
                              }
                            } else {
                              final index = selectedEquipos.indexWhere((e) =>
                                  e['cod_instrumento'] ==
                                      equipo['cod_instrumento'] &&
                                  e['tipo'] == 'pesa');
                              if (index != -1) {
                                selectedEquipos.removeAt(index);
                                _cantidadControllers.removeAt(index);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (selectedEquipos.any((e) => e['tipo'] == 'pesa')) {
                      setState(
                          () {}); // Actualiza el estado de la pantalla principal
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Seleccione al menos una pesa patrón')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('CONFIRMAR SELECCIÓN'),
                ),
                const SizedBox(height: 16.0),
              ],
            );
          },
        );
      },
    );
  }

  void _showTermohigrometrosSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final termohigrometros = equipos.where((equipo) {
          final instrumento = equipo['instrumento']?.toString() ?? '';
          return instrumento.contains('Termohigrómetro') ||
              instrumento.contains('Termohigrobarómetro');
        }).toList();

        final Map<String, Map<String, dynamic>> uniqueTermos = {};
        for (var termo in termohigrometros) {
          final codInstrumento = termo['cod_instrumento'].toString();
          final certFecha = DateTime.parse(termo['cert_fecha']);

          if (!uniqueTermos.containsKey(codInstrumento)) {
            uniqueTermos[codInstrumento] = termo;
          } else {
            final currentFecha =
                DateTime.parse(uniqueTermos[codInstrumento]!['cert_fecha']);
            if (certFecha.isAfter(currentFecha)) {
              uniqueTermos[codInstrumento] = termo;
            }
          }
        }

        final List<Map<String, dynamic>> termosUnicos =
            uniqueTermos.values.toList();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                const SizedBox(height: 16.0),
                const Text(
                  'SELECCIONAR TERMOHIGRÓMETROS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Seleccione los termohigrómetros para el servicio (1-2)',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: termosUnicos.length,
                    itemBuilder: (context, index) {
                      final equipo = termosUnicos[index];
                      final certFecha = DateTime.parse(equipo['cert_fecha']);
                      final difference =
                          DateTime.now().difference(certFecha).inDays;

                      return CheckboxListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${equipo['cod_instrumento']}'),
                            Text(
                              'Certificado: ${equipo['cert_fecha']} ($difference días)',
                              style: TextStyle(
                                fontSize: 12,
                                color: difference > 365
                                    ? Colors.red
                                    : difference > 300
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                            'Ente calibrador: ${equipo['ente_calibrador']}'),
                        value: selectedEquipos.any((e) =>
                            e['cod_instrumento'] == equipo['cod_instrumento'] &&
                            e['tipo'] == 'termohigrometro'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              if (selectedEquipos
                                      .where(
                                          (e) => e['tipo'] == 'termohigrometro')
                                      .length <
                                  2) {
                                selectedEquipos.add({
                                  ...equipo,
                                  'cantidad': '1',
                                  'tipo': 'termohigrometro'
                                });
                                _cantidadControllers
                                    .add(TextEditingController(text: '1'));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Máximo 2 termohigrómetros permitidos')),
                                );
                              }
                            } else {
                              final index = selectedEquipos.indexWhere((e) =>
                                  e['cod_instrumento'] ==
                                      equipo['cod_instrumento'] &&
                                  e['tipo'] == 'termohigrometro');
                              if (index != -1) {
                                selectedEquipos.removeAt(index);
                                _cantidadControllers.removeAt(index);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (selectedEquipos
                        .any((e) => e['tipo'] == 'termohigrometro')) {
                      setState(
                          () {}); // Actualiza el estado de la pantalla principal
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Seleccione al menos un termohigrómetro')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('CONFIRMAR SELECCIÓN'),
                ),
                const SizedBox(height: 16.0),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildEquipoCard(
      BuildContext context, Map<String, dynamic> equipo, int index) {
    final certFecha = DateTime.parse(equipo['cert_fecha']);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(certFecha).inDays;

    Color getColor() {
      if (difference > 365) {
        return Colors.red;
      } else if (difference > 300) {
        return Colors.orange;
      } else {
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
      }
    }

    if (index >= _cantidadControllers.length) {
      _cantidadControllers.add(TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Text(
          'EQUIPAMIENTO ${index + 1}:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.blue[900],
          ),
        ),
        const SizedBox(height: 15.0),
        TextFormField(
          initialValue: equipo['cod_instrumento'],
          decoration: buildInputDecoration('Código del Equipo'),
          readOnly: true,
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          initialValue: equipo['instrumento'],
          decoration: buildInputDecoration('Tipo de Instrumento'),
          readOnly: true,
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          initialValue: equipo['cert_fecha'],
          decoration: buildInputDecoration('Fecha de certificación'),
          readOnly: true,
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          initialValue: '$difference días',
          decoration: buildInputDecoration('Días desde certificación').copyWith(
            labelStyle: TextStyle(color: getColor()),
          ),
          readOnly: true,
          style: TextStyle(color: getColor()),
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          initialValue: equipo['ente_calibrador'],
          decoration: buildInputDecoration('Ente calibrador'),
          readOnly: true,
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          initialValue: equipo['estado'],
          decoration: buildInputDecoration('Estado'),
          readOnly: true,
        ),
        const SizedBox(height: 10.0),
        TextFormField(
          controller: _cantidadControllers[index],
          decoration: buildInputDecoration('Cantidad'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la cantidad';
            }
            final cantidad = int.tryParse(value);
            if (cantidad == null || cantidad <= 0) {
              return 'La cantidad debe ser un número válido y mayor que 0';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              selectedEquipos[index]['cantidad'] = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _fetchLastServiceData(
      BuildContext context, String codMetrica) async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);

      final List<Map<String, dynamic>> allServices = await db.query(
        'servicios',
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
      );

      if (allServices.isNotEmpty) {
        allServices.sort((a, b) => DateTime.parse(b['reg_fecha'])
            .compareTo(DateTime.parse(a['reg_fecha'])));
        final lastServiceData = allServices.first;
        Provider.of<BalanzaProvider>(context, listen: false)
            .setLastServiceData(lastServiceData);
      }

      await db.close();
    } catch (e) {
      throw Exception('Error al obtener servicios: $e');
    }
  }

  void _selectBalanza(BuildContext context, Map<String, dynamic> balanza) {
    final selectedBalanza = Balanza(
      cod_metrica: balanza['cod_metrica'].toString(),
      unidad: balanza['unidad']?.toString() ?? '',
      n_celdas: balanza['n_celdas']?.toString() ?? '',
      cap_max1: balanza['cap_max1']?.toString() ?? '',
      d1: double.tryParse(balanza['d1']?.toString() ?? '0') ?? 0,
      e1: double.tryParse(balanza['e1']?.toString() ?? '0') ?? 0,
      dec1: double.tryParse(balanza['dec1']?.toString() ?? '0') ?? 0,
      cap_max2: balanza['cap_max2']?.toString() ?? '',
      d2: double.tryParse(balanza['d2']?.toString() ?? '0') ?? 0,
      e2: double.tryParse(balanza['e2']?.toString() ?? '0') ?? 0,
      dec2: double.tryParse(balanza['dec2']?.toString() ?? '0') ?? 0,
      cap_max3: balanza['cap_max3']?.toString() ?? '',
      d3: double.tryParse(balanza['d3']?.toString() ?? '0') ?? 0,
      e3: double.tryParse(balanza['e3']?.toString() ?? '0') ?? 0,
      dec3: double.tryParse(balanza['dec3']?.toString() ?? '0') ?? 0,
      exc: 0.0,
    );

    // Actualizar los controladores con los datos de la balanza seleccionada
    _codMetricaController.text = selectedBalanza.cod_metrica;
    _catBalanzaController.text =
        balanza['categoria']?.toString() ?? ''; // De la tabla balanzas
    _codInternoController.text = balanza['cod_interno']?.toString() ?? '';
    _nCeldasController.text =
        balanza['n_celdas']?.toString() ?? ''; // De la tabla inf
    _tipoEquipoController.text =
        balanza['tipo_instrumento']?.toString() ?? ''; // De la tabla inf
    _marcaController.text =
        balanza['marca']?.toString() ?? ''; // De la tabla inf
    _modeloController.text =
        balanza['modelo']?.toString() ?? ''; // De la tabla inf
    _serieController.text =
        balanza['serie']?.toString() ?? ''; // Puede venir de ambas tablas
    _unidadController.text = selectedBalanza.unidad;
    _ubicacionController.text =
        balanza['ubicacion']?.toString() ?? ''; // De la tabla inf
    _pmax1Controller.text = selectedBalanza.cap_max1;
    _d1Controller.text = selectedBalanza.d1.toString();
    _e1Controller.text = selectedBalanza.e1.toString();
    _dec1Controller.text = selectedBalanza.dec1.toString();
    _pmax2Controller.text = selectedBalanza.cap_max2;
    _d2Controller.text = selectedBalanza.d2.toString();
    _e2Controller.text = selectedBalanza.e2.toString();
    _dec2Controller.text = selectedBalanza.dec2.toString();
    _pmax3Controller.text = selectedBalanza.cap_max3;
    _d3Controller.text = selectedBalanza.d3.toString();
    _e3Controller.text = selectedBalanza.e3.toString();
    _dec3Controller.text = selectedBalanza.dec3.toString();

    Provider.of<BalanzaProvider>(context, listen: false)
        .setSelectedBalanza(selectedBalanza);
    setState(() {
      this.selectedBalanza = balanza;
    });

    _fetchLastServiceData(context, balanza['cod_metrica']).then((_) {
      if (lastServiceData != null && lastServiceData!['exc'] != null) {
        setState(() {
          selectedBalanza.exc =
              double.parse(lastServiceData!['exc'].toString());
        });
      }
    });
  }

  void _searchBalanzaByCodigoMetrica(
      BuildContext context, String codigoMetrica) {
    final balanza = balanzas.firstWhere(
      (balanza) => balanza['cod_metrica'] == codigoMetrica,
      orElse: () => {},
    );

    if (balanza.isNotEmpty) {
      _selectBalanza(context, balanza);
    } else {
      _showBalanzaNoEncontradaDialog(context);
    }
  }

  void _showBalanzaNoEncontradaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('BALANZA NO ENCONTRADA'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String formatNumber(dynamic number, {int decimals = 2}) {
    if (number == null) return 'DATO NO REGISTRADO';
    return number?.toString() ?? '';
  }

  @override
  void dispose() {
    _nRecaController.dispose();
    _stickerController.dispose();
    _searchController.dispose();
    _isNextButtonVisible.dispose();
    super.dispose();
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

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDarkMode ? Colors.white : Colors.black;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Text(
            'CALIBRACIÓN',
            style: TextStyle(
              fontSize: 17.0,
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
                      color: Colors.black.withOpacity(0.5),
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
          actions: [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'IDENTIFICACIÓN DE BALANZA',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _cliente ?? 'Cargando...',
                      decoration: buildInputDecoration(
                        'CLIENTE:',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nRecaController,
                      decoration: buildInputDecoration(
                        'N° RECA',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un número de RECA válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TextFormField(
                      controller: _stickerController,
                      decoration: buildInputDecoration(
                        'N° STICKER',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un número de Sticker válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5.0),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info, // Ícono de información
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                          size: 16.0, // Tamaño del ícono
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            'Ingrese el N°RECA',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontStyle: FontStyle.italic, // Texto inclinado
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info, // Ícono de información
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                          size: 16.0, // Tamaño del ícono
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            'Ingrese el N°STICKER',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontStyle: FontStyle.italic, // Texto inclinado
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Column(
                children: [
                  const Text(
                    'FOTOGRAFÍAS DE IDENTIFICACIÓN INICIAL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Máximo 5 fotos (${_balanzaPhotos['identificacion']?.length ?? 0}/5)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _takePhoto(
                                context); // Llama a la función asíncrona desde una función síncrona
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),
                        if (_balanzaPhotos['identificacion'] != null)
                          ..._balanzaPhotos['identificacion']!.map((photo) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                                          _balanzaPhotos['identificacion']!
                                              .remove(photo);
                                          if (_balanzaPhotos['identificacion']!
                                              .isEmpty) {
                                            _fotosTomadas = false;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              SmoothPageIndicator(
                controller: _pageController,
                count: 2,
                effect: const WormEffect(
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
              const SizedBox(height: 5.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'Deslice hacia la izquierda para ir a seleccionar los equipos de ayuda',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontStyle: FontStyle.italic, // Texto inclinado
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black87
                          .withOpacity(0.2) // Fondo más oscuro en modo oscuro
                      : Colors.black54
                          .withOpacity(0.1), // Fondo más claro en modo claro
                  borderRadius: BorderRadius.circular(12.0), // Borde redondeado
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: PageView(
                    controller: _pageController,
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      height: 54.0,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showBalanzasDialog(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellow,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0,
                                            vertical: 15.0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                        ),
                                        child: const Text(
                                          'BALANZAS DISPONIBLES',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 54.0,
                                      child: ElevatedButton(
                                        onPressed: _showNewBalanzaForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0,
                                            vertical: 15.0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                        ),
                                        child: const Text(
                                          'BALANZA NUEVA',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            if (isNewBalanza || selectedBalanza != null)
                              Column(
                                children: [
                                  const Text(
                                    'INFORMACIÓN DE LA BALANZA',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _codMetricaController,
                                    decoration: buildInputDecoration(
                                      'Código Métrica:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _catBalanzaController,
                                    decoration: buildInputDecoration(
                                      'Categoría:',
                                    ),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _codInternoController,
                                    decoration: buildInputDecoration(
                                      'Código Interno:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _tipoEquipoController,
                                    decoration: buildInputDecoration(
                                      'Tipo de Equipo:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration: buildInputDecoration(
                                      'Marca:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration: buildInputDecoration(
                                      'Modelo:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _serieController,
                                    decoration: buildInputDecoration(
                                      'Serie:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _unidadController,
                                    decoration: buildInputDecoration(
                                      'Unidad:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _ubicacionController,
                                    decoration: buildInputDecoration(
                                      'Ubicación:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 20.0),
                                  const Text(
                                    'RANGO O INTERVALO 1',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _pmax1Controller,
                                    decoration: buildInputDecoration(
                                      'cap_max1:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _d1Controller,
                                    decoration: buildInputDecoration(
                                      'd1:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _e1Controller,
                                    decoration: buildInputDecoration(
                                      'e1:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _dec1Controller,
                                    decoration: buildInputDecoration(
                                      'dec1:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 20.0),
                                  const Text(
                                    'RANGO O INTERVALO 2',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _pmax2Controller,
                                    decoration: buildInputDecoration(
                                      'cap_max2:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _d2Controller,
                                    decoration: buildInputDecoration(
                                      'd2:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _e2Controller,
                                    decoration: buildInputDecoration(
                                      'e2:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _dec2Controller,
                                    decoration: buildInputDecoration(
                                      'dec2:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 20.0),
                                  const Text(
                                    'RANGO O INTERVALO 3',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _pmax3Controller,
                                    decoration: buildInputDecoration(
                                      'cap_max3:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _d3Controller,
                                    decoration: buildInputDecoration(
                                      'd3:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _e3Controller,
                                    decoration: buildInputDecoration(
                                      'e3:',
                                    ),
                                    readOnly: false,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    keyboardType: const TextInputType
                                        .numberWithOptions(
                                        decimal:
                                            true), // Permite solo números con punto decimal
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(
                                          r'^\d*\.?\d*')), // Solo permite números y el punto decimal
                                    ],
                                    controller: _dec3Controller,
                                    decoration: buildInputDecoration(
                                      'dec3:',
                                    ),
                                    readOnly: false,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 5.0),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showPesasPatronSelection(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 17.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'PESAS PATRÓN',
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showTermohigrometrosSelection(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 17.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'EQUIPOS DE MEDICIÓN',
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            const Text(
                              'INFORMACIÓN DE LOS INSTRUMENTOS SELECCIONADOS',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10.0),
                            if (selectedEquipos.isNotEmpty)
                              Column(
                                children: selectedEquipos
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final equipo = entry.value;
                                  return buildEquipoCard(
                                      context, equipo, index);
                                }).toList(),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _saveDataToDatabase(
                            context); // Llamar directamente a la función de guardado
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text('1: GUARDAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isNextButtonVisible,
                    builder: (context, isVisible, child) {
                      return Expanded(
                        child: Visibility(
                          visible: isVisible,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_isDataSaved) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Debe guardar los datos antes de continuar')),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServicioScreen(
                                    codMetrica: _codMetricaController.text,
                                    nReca: _nRecaController.text,
                                    secaValue: widget.secaValue,
                                    sessionId: widget.sessionId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: const Text('2: SIGUIENTE'),
                          ),
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
}
