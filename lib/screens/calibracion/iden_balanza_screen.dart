import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../database/app_database.dart';
import 'servicio_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/balanza_provider.dart';
import '../../models/balanza_model.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class IdenBalanzaScreen extends StatefulWidget {
  final String secaValue;
  final String sessionId;
  final String selectedPlantaCodigo;
  final String selectedCliente;
  final bool loadFromSharedPreferences;

  const IdenBalanzaScreen({
    super.key,
    required this.secaValue,
    required this.sessionId,
    required this.selectedPlantaCodigo,
    required this.selectedCliente,
    required this.loadFromSharedPreferences,
  });

  @override
  _IdenBalanzaScreenState createState() => _IdenBalanzaScreenState();
}

class _IdenBalanzaScreenState extends State<IdenBalanzaScreen> {
  List<Map<String, dynamic>> balanzas = [];
  List<TextEditingController> _cantidadControllers = [];
  Map<String, dynamic>? selectedBalanza;
  Map<String, dynamic>? lastServiceData;
  String? errorMessage;
  String? _cliente;
  String? _codPlanta;
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

  final List<String> marcasBalanzas = [
    'ACCULAB',
    'AIV ELECTRONIC TECH',
    'AIV-ELECTRONIC TECH',
    'AND',
    'ASPIRE',
    'AVERY',
    'BALPER',
    'CAMRY',
    'CARDINAL',
    'CAS',
    'CAUDURO',
    'CLEVER',
    'DAYANG',
    'DIGITAL SCALE',
    'DOLPHIN',
    'ELECTRONIC SCALE',
    'FAIRBANKS',
    'FAIRBANKS MORSE',
    'AOSAI',
    'FAMOCOL',
    'FERTON',
    'FILIZOLA',
    'GRAM',
    'GRAM PRECISION',
    'GSC',
    'GUOMING',
    'HBM',
    'HIWEIGH',
    'HOWE',
    'INESA',
    'JADEVER',
    'JM',
    'KERN',
    'KRETZ',
    'LUTRANA',
    'METTLER',
    'METTLER TOLEDO',
    'MY WEIGH',
    'OHAUS',
    'PRECISA',
    'PRECISION HISPANA',
    'PT Ltd',
    'QUANTUM SCALES',
    'RADWAG',
    'RINSTRUM',
    'SARTORIUS',
    'SCIENTECH',
    'SECA',
    'SHANGAI',
    'SHIMADZU',
    'SIPEL',
    'STAVOL',
    'SYMMETRY',
    'SYSTEL',
    'TOLEDO',
    'TOP BRAND',
    'TOP INSTRUMENTS',
    'TRANSCELL',
    'TRINER',
    'TRINNER SCALES',
    'WATERPROOF',
    'WHITE BIRD',
    'CONSTANT',
    'JEWELLRY SCALE',
    'YAOHUA',
    'PRIX'
  ];

  final List<String> tiposEquipo = [
    'BALANZA',
    'BALANZA ANALIZADORA DE HUMEDAD',
    'BALANZA ANALÍTICA',
    'BALANZA MECÁNICA',
    'BALANZA ELECTROMECÁNICA',
    'BALANZA ELECTRÓNICA DE DOBLE RANGO',
    'BALANZA ELECTRÓNICA DE TRIPLE RANGO',
    'BALANZA ELECTRÓNICA DE DOBLE INTÉRVALO',
    'BALANZA ELECTRÓNICA DE TRIPLE INTÉRVALO',
    'BALANZA SEMIMICROANALÍTICA',
    'BALANZA MICROANALÍTICA',
    'BALANZA SEMIMICROANALÍTICA DE DOBLE RANGO',
    'BALANZA SEMIMICROANALÍTICA DE TRIPLE RANGO',
    'BALANZA SEMIMICROANALÍTICA DE DOBLE INTÉRVALO',
    'BALANZA SEMIMICROANALÍTICA DE TRIPLE INTÉRVALO',
    'BALANZA MICROANALÍTICA DE DOBLE RANGO',
    'BALANZA MICROANALÍTICA DE TRIPLE RANGO',
    'BALANZA MICROANALÍTICA DE DOBLE INTÉRVALO',
    'BALANZA MICROANALÍTICA DE TRIPLE INTÉRVALO'
  ];

  @override
  void initState() {
    super.initState();

    debugPrint('SECA recibido: ${widget.secaValue}');
    debugPrint('Session ID recibido: ${widget.sessionId}');

    _searchController.addListener(_filterEquipos);
    _fetchEquipos();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchClienteFromDatabase();

      // Una vez que tenemos el código de planta, buscar las balanzas
      if (_codPlanta != null && _codPlanta!.isNotEmpty) {
        await _fetchBalanzas(_codPlanta!);
      } else {
        // Si no hay código de planta, usar el que viene del widget
        await _fetchBalanzas(widget.selectedPlantaCodigo);
      }

      if (widget.loadFromSharedPreferences) {
        await _loadSavedData();
      }
    });

    _cantidadControllers = [];
  }

  void _showNewBalanzaForm() {
    final now = DateTime.now();
    final formattedDateTime =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      isNewBalanza = true;
      selectedBalanza = null;
      _clearBalanzaFields();
      _codMetricaController.text = '$_codPlanta-$formattedDateTime';
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

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cliente = prefs.getString('selectedCliente') ?? widget.selectedCliente;
    });
  }

  Future<List<String>> _getCodMetricaFromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final database = await dbHelper.database;
      final List<Map<String, dynamic>> results = await database.query(
        'registros_calibracion',
        columns: ['cod_metrica'],
      );
      return results.map((row) {
        final codMetrica = row['cod_metrica'];
        return codMetrica?.toString() ?? '';
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('Error al obtener cod_metrica desde la BD: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  void _showBalanzasDialog(BuildContext context) async {
    if (widget.loadFromSharedPreferences) {
      await _loadBalanzasFromSharedPreferences();
    } else {
      await _fetchBalanzas(widget.selectedPlantaCodigo);
    }

    final List<String> codMetricaList = await _getCodMetricaFromDatabase();
    TextEditingController searchBalanzaController = TextEditingController();
    final calibradasCount = balanzas
        .where((b) => codMetricaList.contains(b['cod_metrica'].toString()))
        .length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Map<String, dynamic>> filteredBalanzas =
                balanzas.where((balanza) {
              final searchTerm = searchBalanzaController.text.toLowerCase();
              return balanza['cod_metrica']
                      .toString()
                      .toLowerCase()
                      .contains(searchTerm) ||
                  balanza['serie']
                      .toString()
                      .toLowerCase()
                      .contains(searchTerm) ||
                  balanza['cod_interno']
                      .toString()
                      .toLowerCase()
                      .contains(searchTerm);
            }).toList();
            return AlertDialog(
              title: Column(
                children: [
                  const Text(
                    'BUSCAR BALANZA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5.0),
                  Text('Balanzas registradas Calibradas: $calibradasCount',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 15),
                  _buildSearchField(searchBalanzaController, setState),
                ],
              ),
              content: _buildBalanzaList(
                context,
                filteredBalanzas,
                codMetricaList,
                _selectBalanza,
              ),
              actions: _buildDialogActions(context, _showNewBalanzaForm),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField(TextEditingController controller,
      void Function(void Function()) setState) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por código, serie o interno',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildBalanzaList(
    BuildContext context,
    List<Map<String, dynamic>> balanzas,
    List<String> codMetricaList,
    Function(BuildContext, Map<String, dynamic>) onTapBalanza,
  ) {
    if (balanzas.isEmpty) {
      return const SizedBox(
        width: double.maxFinite,
        child: Center(child: Text('No se encontraron balanzas')),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: balanzas.length,
        itemBuilder: (context, index) {
          final balanza = balanzas[index];
          final isChecked =
              codMetricaList.contains(balanza['cod_metrica'].toString());
          return _buildBalanzaTile(context, balanza, isChecked, onTapBalanza);
        },
      ),
    );
  }

  Widget _buildBalanzaTile(
    BuildContext context,
    Map<String, dynamic> balanza,
    bool isChecked,
    Function(BuildContext, Map<String, dynamic>) onTapBalanza,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Text(
          'CÓDIGO: ${balanza['cod_metrica']}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serie: ${balanza['serie'] ?? 'N/A'}'),
            Text('Interno: ${balanza['cod_interno'] ?? 'N/A'}'),
            Text('Marca: ${balanza['marca'] ?? 'N/A'}'),
            Text('Modelo: ${balanza['modelo'] ?? 'N/A'}'),
          ],
        ),
        trailing: isChecked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () => onTapBalanza(context, balanza),
      ),
    );
  }

  List<Widget> _buildDialogActions(
      BuildContext context, VoidCallback onNewBalanza) {
    return [
      TextButton(
        child: const Text('Nueva Balanza'),
        onPressed: () {
          Navigator.of(context).pop();
          onNewBalanza();
        },
      ),
      TextButton(
        child: const Text('Cerrar'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  Future<void> _saveDataToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cliente', _cliente ?? '');
    final balanzasJson = jsonEncode(balanzas);
    await prefs.setString('saved_balanzas', balanzasJson);
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    // ====== VALIDACIONES ======
    if (_nRecaController.text.isEmpty) {
      _showSnackBar(context, 'Por favor ingrese el N° Reca');
      return;
    }

    if (_stickerController.text.isEmpty) {
      _showSnackBar(context, 'Por favor ingrese el N° de Sticker');
      return;
    }

    if (_ubicacionController.text.isEmpty) {
      _showSnackBar(context, 'Por favor ingrese la ubicación de la balanza');
      return;
    }

    if (selectedEquipos.isEmpty) {
      _showSnackBar(context, 'Por favor seleccione al menos una pesa patrón');
      return;
    }

    // Validar cantidades
    for (int i = 0; i < selectedEquipos.length; i++) {
      final cantidad = selectedEquipos[i]['cantidad']?.trim() ?? '';
      final cantidadNum = int.tryParse(cantidad) ?? 0;

      if (cantidad.isEmpty || cantidadNum <= 0) {
        _showSnackBar(
          context,
          'Por favor ingrese una cantidad válida para la pesa patrón ${i + 1}',
        );
        return;
      }
    }

    // Confirmación si es balanza nueva
    if (isNewBalanza) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'REGISTRANDO BALANZA NUEVA',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            content: const Text(
              'Está registrando una balanza nueva. Revise bien los datos antes de continuar.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
    } else if (selectedBalanza == null) {
      _showSnackBar(context, 'Por favor seleccione una balanza');
      return;
    }

    // ====== GUARDADO EN BASE DE DATOS ======
    try {
      if (_balanzaPhotos['identificacion']?.isNotEmpty ?? false) {
        await _savePhotosToZip(context);
      }

      final dbHelper = AppDatabase();

      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

      // Registro base
      final registro = {
        'seca': widget.secaValue,
        'session_id': widget.sessionId,
        'foto_balanza': _fotosTomadas ? 1 : 0,
        'cod_metrica': _codMetricaController.text.trim(),
        'categoria_balanza': _catBalanzaController.text.trim(),
        'cod_int': _codInternoController.text.trim(),
        'tipo_equipo': _tipoEquipoController.text.trim(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'serie': _serieController.text.trim(),
        'unidades': _unidadController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'cap_max1': _pmax1Controller.text.trim(),
        'd1': _d1Controller.text.trim(),
        'e1': _e1Controller.text.trim(),
        'dec1': _dec1Controller.text.trim(),
        'cap_max2': _pmax2Controller.text.trim(),
        'd2': _d2Controller.text.trim(),
        'e2': _e2Controller.text.trim(),
        'dec2': _dec2Controller.text.trim(),
        'cap_max3': _pmax3Controller.text.trim(),
        'd3': _d3Controller.text.trim(),
        'e3': _e3Controller.text.trim(),
        'dec3': _dec3Controller.text.trim(),
        'n_reca': _nRecaController.text.trim(),
        'sticker': _stickerController.text.trim(),
      };

      // Agregar equipos
      for (int i = 0; i < selectedEquipos.length; i++) {
        final equipo = selectedEquipos[i];
        if (equipo['tipo'] == 'pesa') {
          registro['equipo${i + 1}'] = equipo['cod_instrumento']?.trim() ?? '';
          registro['certificado${i + 1}'] = equipo['cert_fecha']?.trim() ?? '';
          registro['ente_calibrador${i + 1}'] =
              equipo['ente_calibrador']?.trim() ?? '';
          registro['estado${i + 1}'] = equipo['estado']?.trim() ?? '';
          registro['cantidad${i + 1}'] = equipo['cantidad']?.trim() ?? '1';
        }
      }

      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      setState(() {
        _isDataSaved = true;
      });

      await _saveDataToSharedPreferences();
      await _loadSavedData();

      _showSnackBar(context,
          'Datos de la balanza e instrumentos de calibración guardados correctamente');
      _isNextButtonVisible.value = true;
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Ocurrió un error: $e', isError: true);
      debugPrint('Error al guardar: $e');
      debugPrint('StackTrace: $stackTrace');
    }
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

  Future<void> _fetchClienteFromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final database = await dbHelper.database;

      // ✅ BUSCAR POR SECA Y SESSION_ID ACTUAL
      final List<Map<String, dynamic>> result = await database.query(
        'registros_calibracion',
        columns: ['cliente', 'cod_planta', 'razon_social', 'planta'],
        where: 'seca = ? AND session_id = ?',
        whereArgs: [widget.secaValue, widget.sessionId],
      );

      if (result.isNotEmpty) {
        final registro = result.first;
        setState(() {
          _cliente = registro['cliente']?.toString() ?? 'Cliente no encontrado';
          _codPlanta = registro['cod_planta']?.toString() ?? 'Código planta no encontrado';
        });
        return;
      }

      // ✅ SI NO ENCUENTRA, BUSCAR EL ÚLTIMO REGISTRO DEL SECA
      final List<Map<String, dynamic>> resultBySeca = await database.query(
        'registros_calibracion',
        columns: ['cliente', 'cod_planta', 'razon_social', 'planta'],
        where: 'seca = ?',
        whereArgs: [widget.secaValue],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (resultBySeca.isNotEmpty) {
        final registro = resultBySeca.first;
        setState(() {
          _cliente = registro['cliente']?.toString() ?? widget.selectedCliente;
          _codPlanta = registro['cod_planta']?.toString() ?? widget.selectedPlantaCodigo;
        });
      } else {
        // ✅ USAR LOS VALORES POR DEFECTO
        setState(() {
          _cliente = widget.selectedCliente;
          _codPlanta = widget.selectedPlantaCodigo;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error al obtener cliente desde la BD: $e');
      debugPrint('StackTrace: $stackTrace');
      setState(() {
        _cliente = widget.selectedCliente;
        _codPlanta = widget.selectedPlantaCodigo;
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

  // Función para filtrar y ordenar las pesas patrón
  List<Map<String, dynamic>> _filtrarYOrdenarPesas(List<dynamic> equipos) {
    // Filtrar solo pesas patrón (excluyendo termohigrómetros)
    final pesasPatron = equipos.where((equipo) {
      final instrumento = equipo['instrumento']?.toString() ?? '';
      return !instrumento.contains('Termohigrómetro') &&
          !instrumento.contains('Termohigrobarómetro');
    }).toList();

    // Obtener la versión más reciente de cada pesa (por código)
    final Map<String, Map<String, dynamic>> uniquePesas = {};
    for (var pesa in pesasPatron) {
      final codInstrumento = pesa['cod_instrumento'].toString();
      final certFecha = DateTime.parse(pesa['cert_fecha']);

      if (!uniquePesas.containsKey(codInstrumento) ||
          certFecha.isAfter(
              DateTime.parse(uniquePesas[codInstrumento]!['cert_fecha']))) {
        uniquePesas[codInstrumento] = pesa;
      }
    }

    // Convertir a lista y ordenar alfabéticamente
    return uniquePesas.values.toList()
      ..sort((a, b) => (a['cod_instrumento']?.toString() ?? '')
          .compareTo(b['cod_instrumento']?.toString() ?? ''));
  }

// Función para determinar la cantidad automática
  String _determinarCantidadAutomatica(Map<String, dynamic> pesa) {
    final codInstrumento = pesa['cod_instrumento']?.toString() ?? '';
    // Si NO empieza con 'M', cantidad automática = 1
    return !codInstrumento.startsWith('M') ? '1' : '';
  }

// Función para construir un ítem de la lista de pesas

  void _showPesasPatronSelection(BuildContext context) {
    final pesasUnicas = _filtrarYOrdenarPesas(equipos);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
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
                      final pesa = pesasUnicas[index];
                      final isSelected = selectedEquipos.any((e) =>
                          e['cod_instrumento'] == pesa['cod_instrumento'] &&
                          e['tipo'] == 'pesa');

                      return _buildPesaItem(
                        context,
                        pesa,
                        isSelected,
                        (bool? value) {
                          setModalState(() {
                            _handlePesaSelection(value ?? false, pesa);
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                _buildConfirmationButton(context),
                const SizedBox(height: 16.0),
              ],
            );
          },
        );
      },
    );
  }

// Función para manejar la selección/deselección de pesas
  void _handlePesaSelection(bool isSelected, Map<String, dynamic> pesa) {
    if (isSelected) {
      if (selectedEquipos.where((e) => e['tipo'] == 'pesa').length < 5) {
        selectedEquipos.add({
          ...pesa,
          'cantidad': _determinarCantidadAutomatica(pesa),
          'tipo': 'pesa'
        });
        _cantidadControllers.add(TextEditingController(
          text: _determinarCantidadAutomatica(pesa),
        ));
      } else {}
    } else {
      final index = selectedEquipos.indexWhere((e) =>
          e['cod_instrumento'] == pesa['cod_instrumento'] &&
          e['tipo'] == 'pesa');
      if (index != -1) {
        selectedEquipos.removeAt(index);
        _cantidadControllers.removeAt(index);
      }
    }
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
    Navigator.of(context).pop();
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
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
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
          actions: [],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight +
                MediaQuery.of(context).padding.top +
                40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
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
                      controller: TextEditingController(
                          text: _cliente ?? 'Cargando...'),
                      decoration: buildInputDecoration('CLIENTE:'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
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
                            _takePhoto(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                            backgroundColor: const Color(
                                0xFFc0101a), // Color de fondo del círculo
                            foregroundColor: Colors
                                .white, // Color del ícono (y texto si lo hubiera)
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),
                        if (_balanzaPhotos['identificacion'] != null)
                          ..._balanzaPhotos['identificacion']!.map((photo) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () =>
                                    _showFullScreenPhoto(context, photo),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                          Image.file(photo, fit: BoxFit.cover),
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
                                            if (_balanzaPhotos[
                                                    'identificacion']!
                                                .isEmpty) {
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 54.0,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _showBalanzasDialog(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF326677),
                                          ),
                                          child: const Text(
                                            'VER BALANZAS',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 54.0,
                                        child: ElevatedButton(
                                          onPressed: _showNewBalanzaForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF327734),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'images/iconos/icono_balanza_industrial.png',
                                                width: 40,
                                                height: 40,
                                                color: Colors
                                                    .white, // Quita esto si tu imagen ya es blanca
                                              ),
                                              const FaIcon(
                                                FontAwesomeIcons.plus,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                    controller: _codMetricaController,
                                    decoration: buildInputDecoration(
                                      'Código Metrica:',
                                    ),
                                    readOnly: true,
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
                                  _buildTipoEquipoField(),
                                  const SizedBox(height: 14.0),
                                  _buildMarcaField(),
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
                                    backgroundColor: const Color(0xFF773243),
                                  ),
                                  child: const Text(
                                    ' SELECCIONAR PESAS PATRÓN',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            const Text(
                              'INFORMACIÓN DE LOS INSTRUMENTOS SELECCIONADOS',
                              style: TextStyle(
                                fontSize: 16,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveDataToDatabase(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007195),
                        ),
                        child: const Text('1: GUARDAR'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
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
                                ? ElevatedButton(
                                    key: const ValueKey('next_button'),
                                    onPressed: () async {
                                      if (!_isDataSaved) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Debe guardar los datos antes de continuar'),
                                          ),
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
                                      backgroundColor: const Color(0xFF3e7732),
                                    ),
                                    child: const Text('2: SIGUIENTE'),
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarcaField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return marcasBalanzas.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _marcaController.text = selection;
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        // Asignar el valor inicial del _marcaController
        if (textEditingController.text.isEmpty &&
            _marcaController.text.isNotEmpty) {
          textEditingController.text = _marcaController.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: buildInputDecoration(
            'Marca:',
          ).copyWith(
            suffixIcon: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (String value) {
                textEditingController.text = value;
                _marcaController.text = value;
              },
              itemBuilder: (BuildContext context) {
                return marcasBalanzas
                    .map<PopupMenuItem<String>>((String value) {
                  return PopupMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList();
              },
            ),
          ),
          onChanged: (value) {
            _marcaController.text = value;
          },
        );
      },
    );
  }

  Widget _buildPesaItem(
    BuildContext context,
    Map<String, dynamic> pesa,
    bool isSelected,
    Function(bool?) onChanged,
  ) {
    final certFecha = DateTime.parse(pesa['cert_fecha']);
    final difference = DateTime.now().difference(certFecha).inDays;

    return CheckboxListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${pesa['cod_instrumento']}'),
          Text(
            'Certificado: ${pesa['cert_fecha']} ($difference días)',
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
      subtitle: Text('Ente calibrador: ${pesa['ente_calibrador']}'),
      value: isSelected,
      onChanged: onChanged,
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
          'Equipamiento ${index + 1}:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  Widget _buildConfirmationButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (selectedEquipos.any((e) => e['tipo'] == 'pesa')) {
          setState(() {});
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Seleccione al menos una pesa patrón')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: const Text('CONFIRMAR SELECCIÓN'),
    );
  }

  Widget _buildTipoEquipoField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return tiposEquipo.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _tipoEquipoController.text = selection;
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text.isEmpty &&
            _tipoEquipoController.text.isNotEmpty) {
          textEditingController.text = _tipoEquipoController.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: buildInputDecoration(
            'Tipo de Equipo:',
          ).copyWith(
            suffixIcon: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (String value) {
                textEditingController.text = value;
                _tipoEquipoController.text = value;
              },
              itemBuilder: (BuildContext context) {
                return tiposEquipo.map<PopupMenuItem<String>>((String value) {
                  return PopupMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList();
              },
            ),
          ),
          onChanged: (value) {
            _tipoEquipoController.text = value;
          },
        );
      },
    );
  }
}
