import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:service_met/screens/soporte/modulos/home.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:service_met/screens/soporte/modulos/instalacion/stac_instalacion.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/balanza_model.dart';
import '../../../provider/balanza_provider.dart';

class IdenBalanzaScreen extends StatefulWidget {
  final String selectedPlantaCodigo;
  final String selectedCliente;
  final String selectedPlantaNombre;
  final String dbName;
  final bool loadFromSharedPreferences;
  final String dbPath;
  final String otValue;

  const IdenBalanzaScreen({
    super.key,
    required this.selectedPlantaCodigo,
    required this.selectedCliente,
    required this.selectedPlantaNombre,
    required this.dbName,
    required this.dbPath,
    required this.loadFromSharedPreferences,
    required this.otValue,
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
  String? _clienteSeleccionado;
  String? _clienteNombre;
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

  final List<String> unidadesList = ['kg', 'g', 'mg'];

  final List<String> instrumentosList = [
    'BALANZA DE LABORATORIO',
    'BALANZA DE MESA',
    'BALANZA DE BANCO',
    'BALANZA DE PISO',
    'TANQUE',
    'SILO',
    'ACCESORIOS',
    'TARJETA DE COM RS-485',
    'TARJETA DE COM 4-20 Ma',
    'TARJETA I/O',
    'TERMINAL',
    'PLATAFORMA'
  ];
  String? selectedInstrumento;

  @override
  void initState() {
    super.initState();
    _loadClienteFromDatabase();
    _loadClienteNombre();
    _searchController.addListener(_filterEquipos);
    _fetchEquipos();
    _fetchBalanzas(widget.selectedPlantaCodigo);
    _fetchClienteFromDatabase(); // Llamar a la función para obtener el cliente
    if (widget.loadFromSharedPreferences) {
      _loadSavedData(); // Cargar datos desde SharedPreferences
    } else {
      setState(() {
        _cliente = widget.selectedCliente;
      });
    }
    _fetchBalanzas(widget.selectedPlantaCodigo);
    _cantidadControllers = [];
  }

  void _showNewBalanzaForm() {
    setState(() {
      isNewBalanza = true;
      selectedBalanza = null;
      _clearBalanzaFields();
      _codMetricaController.text = 'NUEVA';
      // Establecer valores por defecto para rangos 2 y 3
      _pmax2Controller.text = '0';
      _d2Controller.text = '0';
      _e2Controller.text = '0';
      _dec2Controller.text = '0';
      _pmax3Controller.text = '0';
      _d3Controller.text = '0';
      _e3Controller.text = '0';
      _dec3Controller.text = '0';
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
    _nCeldasController.clear();
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

  void _toUpperCase(TextEditingController controller) {
    final text = controller.text;
    if (text != text.toUpperCase()) {
      controller.text = text.toUpperCase();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }


  Future<void> _loadClienteFromDatabase() async {
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'inf_cliente_balanza',
        columns: ['cliente'],
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (mounted) {
        setState(() {
          _clienteSeleccionado =
              result.isNotEmpty ? result.first['cliente'] as String? : null;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar cliente: $e');
    } finally {
      await db.close();
    }
  }

  Future<void> _loadClienteNombre() async {
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'inf_cliente_balanza',
        columns: ['cliente'],
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isNotEmpty) {
        setState(() {
          _clienteNombre = result.first['cliente'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar nombre del cliente: $e');
    } finally {
      await db.close();
    }
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
          '${widget.otValue}_${_codMetricaController.text}_FotosIdentificacionInicial.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        final savedPath = await FlutterFileDialog.saveFile(params: params);
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'FOTOGRAFÍAS GUARDADAS CON ÉXITO EN:\n$savedPath',
                style: const TextStyle(color: Colors.white), // Texto blanco
              ),
              backgroundColor: Colors.green, // Fondo verde
            ),
          );
        } else {
          // El usuario canceló la operación
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Guardado de fotografias cancelado por el usuario.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar fotos: $e',
              style: const TextStyle(color: Colors.white), // Texto blanco
            ),
            backgroundColor: Colors.red, // Fondo rojo
          ),
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
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);
    final List<Map<String, dynamic>> results = await db.query(
      'inf_cliente_balanza',
      columns: ['cod_metrica'],
    );
    await db.close();
    return results.map((row) => row['cod_metrica'].toString()).toList();
  }

  void _showBalanzasDialog(BuildContext context) async {
    if (widget.loadFromSharedPreferences) {
      await _loadBalanzasFromSharedPreferences();
    } else {
      await _fetchBalanzas(widget.selectedPlantaCodigo);
    }

    final List<String> codMetricaList = await _getCodMetricaFromDatabase();
    TextEditingController searchBalanzaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Map<String, dynamic>> filteredBalanzas = balanzas.where((balanza) {
              final searchTerm = searchBalanzaController.text.toLowerCase();
              return balanza['cod_metrica'].toString().toLowerCase().contains(searchTerm) ||
                  balanza['serie'].toString().toLowerCase().contains(searchTerm) ||
                  balanza['cod_interno'].toString().toLowerCase().contains(searchTerm);
            }).toList();

            return AlertDialog(
              title: Column(
                children: [
                  const Text(
                    'BUSCAR BALANZA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: searchBalanzaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código, serie o interno',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: filteredBalanzas.isEmpty
                    ? const Center(child: Text('No se encontraron balanzas'))
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredBalanzas.length,
                  itemBuilder: (context, index) {
                    final balanza = filteredBalanzas[index];
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
                          'CÓDIGO: ${balanza['cod_metrica']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
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
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectBalanza(context, balanza);
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Nueva Balanza'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showNewBalanzaForm();
                  },
                ),
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
      },
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

  Future<void> _saveDataToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cliente', _cliente ?? '');
    final balanzasJson = jsonEncode(balanzas);
    await prefs.setString('saved_balanzas', balanzasJson);
  }

  Future<void> _saveBalanzaData(BuildContext context) async {
    if ((_balanzaPhotos['identificacion']?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe tomar al menos una foto de identificación inicial',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_ubicacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingrese la ubicación de la balanza',
            style: TextStyle(color: Colors.white), // Texto blanco
          ),
          backgroundColor: Colors.red, // Fondo rojo
        ),
      );
      return;
    }

    if (isNewBalanza && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balanza nueva registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Guardar los datos en la base de datos
    try {
      if (_balanzaPhotos['identificacion']?.isNotEmpty ?? false) {
        await _savePhotosToZip(context);
      }

      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      final registro = {
        'foto_balanza': _fotosTomadas ? 1 : 0,
        'instrumento': selectedInstrumento ?? '', // Nuevo campo instrumento
        'cod_metrica': _codMetricaController.text.trim().isEmpty
            ? ''
            : _codMetricaController.text.trim(),
        'categoria_balanza': _catBalanzaController.text.trim().isEmpty
            ? ''
            : _catBalanzaController.text.trim(),
        'cod_interno': _codInternoController.text.trim().isEmpty
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
        'num_celdas': _nCeldasController.text.trim().isEmpty
            ? ''
            : _nCeldasController.text.trim(),
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
      };

      // Actualizar la base de datos
      await db.update(
        'inf_cliente_balanza',
        registro,
        where: 'id = ?',
        whereArgs: [1],
      );

      setState(() {
        _isDataSaved = true;
      });

      // Guardar los datos en SharedPreferences
      await _saveDataToSharedPreferences();
      await _loadSavedData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos de la balanza guardados con éxito',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (isNewBalanza) {
        final continuar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'NUEVA BALANZA REGISTRADA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text(
                'Estas registrando una nueva balanza, debe continuar para realizar la instalación de la balanza.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF326B2C),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

        if (continuar == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeStacScreen(
                dbName: widget.dbName,
                dbPath: widget.dbPath,
                otValue: widget.otValue,
                selectedCliente: widget.selectedCliente,
                selectedPlantaNombre: widget.selectedPlantaNombre,
                codMetrica: _codMetricaController.text,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar los datos de la balanza: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    _isNextButtonVisible.value = true;
  }

  Future<void> _fetchClienteFromDatabase() async {
    try {
      String path = join(await getDatabasesPath(), '${widget.dbName}.db');
      final db = await openDatabase(path);

      // Consulta para obtener el valor de la columna 'cliente'
      final List<Map<String, dynamic>> result = await db.query(
        'inf_cliente_balanza',
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

  void _selectBalanza(BuildContext context, Map<String, dynamic> balanza) {
    final selectedBalanza = Balanza(
      cod_metrica: balanza['cod_metrica'].toString(),
      n_celdas: balanza['n_celdas']?.toString() ?? '',
      unidad: balanza['unidad']?.toString() ?? '',
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
    _tipoEquipoController.text =
        balanza['tipo_instrumento']?.toString() ?? ''; // De la tabla inf
    _marcaController.text =
        balanza['marca']?.toString() ?? ''; // De la tabla inf
    _modeloController.text =
        balanza['modelo']?.toString() ?? ''; // De la tabla inf
    _serieController.text =
        balanza['serie']?.toString() ?? ''; // Puede venir de ambas tablas
    _unidadController.text = selectedBalanza.unidad;
    _nCeldasController.text =
        balanza['n_celdas']?.toString() ?? ''; // De la tabla inf
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
  }

  void _searchByCode(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buscar Balanza por Código'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Ingrese código métrica',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _searchBalanzaByCodigoMetrica(context, searchController.text);
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  void _searchBalanzaByCodigoMetrica(
      BuildContext context, String codigoMetrica) {
    final balanza = balanzas.firstWhere(
      (balanza) => balanza['cod_metrica'] == codigoMetrica,
      orElse: () => {},
    );
    if (balanza.isNotEmpty) {
      _selectBalanza(context, balanza);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('Error') ? Colors.red : Colors.green,
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
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Centra el contenido
            children: [
              Text(
                'SOPORTE TÉCNICO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 5.0),
              Text(
                _clienteNombre != null
                    ? 'CLIENTE: $_clienteNombre'
                    : 'CLIENTE: No especificado',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : Colors.white,
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
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
          child: Column(
            children: [
              const Text(
                'IDENTIFICACIÓN DE BALANZA',
                style: TextStyle(
                  fontSize: 16.0,
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
                          text: _clienteNombre ?? 'No especificado'),
                      decoration: buildInputDecoration(
                        'CLIENTE',
                      ),
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black54,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _clienteNombre =
                              value; // Actualiza el valor de _clienteNombre
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Column(
                children: [
                  const Text(
                    'FOTOGRAFÍAS DE IDENTIFICACIÓN INICIAL',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mínimo 1 foto, máximo 5 fotos (${_balanzaPhotos['identificacion']?.length ?? 0}/5)',
                    style: TextStyle(
                      fontSize: 12,
                      color: (_balanzaPhotos['identificacion']?.isEmpty ?? true)
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _takePhoto(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF456349),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.photo_camera_rounded),
                        ),
                        if (_balanzaPhotos['identificacion'] != null)
                          ..._balanzaPhotos['identificacion']!.map((photo) {
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
                                            _balanzaPhotos['identificacion']!.remove(photo);
                                            if (_balanzaPhotos['identificacion']!.isEmpty) {
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
                                    SizedBox(
                                      height: 54.0,
                                      child: ElevatedButton(
                                        onPressed: () => _showBalanzasDialog(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFC300),
                                        ),
                                        child: const Text(
                                          'BALANZAS DISPONIBLES',
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    SizedBox(
                                      height: 54.0,
                                      child: ElevatedButton(
                                        onPressed: _showNewBalanzaForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5cb207),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(FontAwesomeIcons.weightHanging,
                                                color: Colors.white, size: 18),
                                            const SizedBox(width: 1.0),
                                            const Icon(Icons.add, color: Colors.white, size: 18),
                                          ],
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
                                    controller: _codMetricaController,
                                    decoration:
                                        buildInputDecoration('Código Métrica:'),
                                    readOnly: true, // Campo bloqueado
                                    enabled: false, // Deshabilitado visualmente
                                  ),
                                  const SizedBox(height: 14.0),
                                  if (isNewBalanza) // <-- Solo mostrar si es balanza nueva
                                    DropdownButtonFormField<String>(
                                      decoration:
                                          buildInputDecoration('Instrumento:'),
                                      value: selectedInstrumento,
                                      items:
                                          instrumentosList.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedInstrumento = newValue;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Seleccione un instrumento';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _codInternoController,
                                    decoration: buildInputDecoration('Código Interno:'),
                                    onChanged: (value) => _toUpperCase(_codInternoController),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration: buildInputDecoration('Marca:'),
                                    onChanged: (value) => _toUpperCase(_marcaController),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration: buildInputDecoration('Modelo:'),
                                    onChanged: (value) => _toUpperCase(_modeloController),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _serieController,
                                    decoration: buildInputDecoration('Serie:'),
                                    onChanged: (value) => _toUpperCase(_serieController),
                                  ),
                                  const SizedBox(height: 14.0),
                                  isNewBalanza
                                      ? DropdownButtonFormField<String>(
                                    decoration: buildInputDecoration('Unidad:'),
                                    value: _unidadController.text.isNotEmpty
                                        ? _unidadController.text.toLowerCase() // Convertir a minúsculas
                                        : null,
                                    items: unidadesList.map((String unidad) {
                                      return DropdownMenuItem<String>(
                                        value: unidad,
                                        child: Text(unidad.toUpperCase()), // Mostrar en mayúsculas pero valor en minúsculas
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _unidadController.text = newValue ?? '';
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Seleccione una unidad';
                                      }
                                      return null;
                                    },
                                  )
                                      : TextFormField(
                                    controller: _unidadController,
                                    decoration: buildInputDecoration('Unidad:'),
                                    onChanged: (value) => _toUpperCase(_unidadController),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _nCeldasController,
                                    decoration: buildInputDecoration(
                                        'Número de Celdas:'),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _ubicacionController,
                                    decoration: buildInputDecoration('Ubicación:'),
                                    onChanged: (value) => _toUpperCase(_ubicacionController),
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
                                    controller: _pmax1Controller,
                                    decoration:
                                        buildInputDecoration('cap_max1:'),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _d1Controller,
                                    decoration: buildInputDecoration('d1:'),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _e1Controller,
                                    decoration: buildInputDecoration('e1:'),
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _dec1Controller,
                                    decoration: buildInputDecoration('dec1:'),
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
                                    controller: _pmax2Controller,
                                    decoration:
                                        buildInputDecoration('cap_max2:'),
                                    readOnly:
                                        isNewBalanza, // Solo lectura para nueva balanza
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _d2Controller,
                                    decoration: buildInputDecoration('d2:'),
                                    readOnly: isNewBalanza,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _e2Controller,
                                    decoration: buildInputDecoration('e2:'),
                                    readOnly: isNewBalanza,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _dec2Controller,
                                    decoration: buildInputDecoration('dec2:'),
                                    readOnly: isNewBalanza,
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
                                    controller: _pmax3Controller,
                                    decoration:
                                        buildInputDecoration('cap_max3:'),
                                    readOnly: isNewBalanza,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _d3Controller,
                                    decoration: buildInputDecoration('d3:'),
                                    readOnly: isNewBalanza,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _e3Controller,
                                    decoration: buildInputDecoration('e3:'),
                                    readOnly: isNewBalanza,
                                  ),
                                  const SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _dec3Controller,
                                    decoration: buildInputDecoration('dec3:'),
                                    readOnly: isNewBalanza,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              AnimatedSwitcher(
                duration: 400.ms,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: !_isNextButtonVisible.value
                    ? Row(
                        key: const ValueKey('guardar'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if ((_balanzaPhotos['identificacion']?.isEmpty ??
                                  true)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Debe tomar al menos una foto antes de guardar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                _saveBalanzaData(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_balanzaPhotos['identificacion']
                                          ?.isNotEmpty ??
                                      false)
                                  ? Colors.blueAccent
                                  : Colors.grey,
                            ),
                            child: const Text('1: GUARDAR'),
                          ).animate().fadeIn().scale(),
                        ],
                      )
                    : Row(
                        key: const ValueKey('siguiente'),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                              ),
                              child: const Text('1: GUARDAR'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!_isDataSaved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                    builder: (context) => HomeStacScreen(
                                      dbName: widget.dbName,
                                      dbPath: widget.dbPath,
                                      otValue: widget.otValue,
                                      selectedCliente: widget.selectedCliente,
                                      selectedPlantaNombre:
                                          widget.selectedPlantaNombre,
                                      codMetrica: _codMetricaController.text,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('2: SIGUIENTE'),
                            ).animate().fadeIn().slideX(begin: 1),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
