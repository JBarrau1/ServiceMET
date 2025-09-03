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

class RelevamientoDeDatosScreen extends StatefulWidget {
  final String dbName;
  final String dbPath;
  final String otValue;
  final String selectedCliente;
  final String selectedPlantaNombre;
  final String codMetrica;

  const RelevamientoDeDatosScreen({
    super.key,
    required this.dbName,
    required this.dbPath,
    required this.otValue,
    required this.selectedCliente,
    required this.selectedPlantaNombre,
    required this.codMetrica,
  });

  @override
  _RelevamientoDeDatosScreenState createState() =>
      _RelevamientoDeDatosScreenState();
}

class _RelevamientoDeDatosScreenState
    extends State<RelevamientoDeDatosScreen> {
  Timer? _debounceTimer;
  bool _isAutoSaving = false;

  final TextEditingController _comentarioGeneralController =
      TextEditingController();
  String? _selectedRecommendation;

  final TextEditingController _cargaLnController = TextEditingController();
  final TextEditingController _cargaClienteController = TextEditingController();
  final TextEditingController _sumatoriaController = TextEditingController();

  final Map<String, List<File>> _fieldPhotos = {};
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final TextEditingController _cargaExcController = TextEditingController();
  final TextEditingController _carcasaComentarioController =
      TextEditingController();
  final TextEditingController _conectorComentarioController =
      TextEditingController();
  final TextEditingController _alimentacionComentarioController =
      TextEditingController();
  final TextEditingController _pantallaComentarioController =
      TextEditingController();
  final TextEditingController _tecladoComentarioController =
      TextEditingController();
  final TextEditingController _bracketComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaFosaComentarioController =
      TextEditingController();
  final TextEditingController _estadoDrenajeComentarioController =
      TextEditingController();
  final TextEditingController _platoCargaComentarioController =
      TextEditingController();
  final TextEditingController _estructuraComentarioController =
      TextEditingController();
  final TextEditingController _topesCargaComentarioController =
      TextEditingController();
  final TextEditingController _patasComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaComentarioController =
      TextEditingController();
  final TextEditingController _bordesPuntasComentarioController =
      TextEditingController();
  final TextEditingController _entornoComentarioController =
      TextEditingController();
  final TextEditingController _nivelacionComentarioController =
      TextEditingController();
  final TextEditingController _movilizacionComentarioController =
      TextEditingController();
  final TextEditingController _flujoPesadasComentarioController =
      TextEditingController();
  final TextEditingController _celulasComentarioController =
      TextEditingController();
  final TextEditingController _cablesComentarioController =
      TextEditingController();
  final TextEditingController _cubiertaSiliconaComentarioController =
      TextEditingController();
  final TextEditingController _flujoPesasComentarioController =
      TextEditingController();

  final TextEditingController _otrosComentarioController =
      TextEditingController();
  final TextEditingController _cargaController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _oneThirdPmax1Controller =
      TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _retornoCeroValorController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _repetibilidadController1 =
      TextEditingController();
  final TextEditingController _repetibilidadController2 =
      TextEditingController();
  final TextEditingController _repetibilidadController3 =
      TextEditingController();
  final List<TextEditingController> _indicacionControllers1 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoControllers1 =
      List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> _indicacionControllers2 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoControllers2 =
      List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> _indicacionControllers3 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoControllers3 =
      List.generate(10, (index) => TextEditingController(text: '0'));

  final ImagePicker _imagePicker = ImagePicker();
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<String> _retornoCeroDropdownController =
      ValueNotifier<String>('1 Bueno'); // Controlador inicializado
  final ValueNotifier<bool> _isNextButtonEnabled =
      ValueNotifier<bool>(false); // Controlador para el botón "SIGUIENTE"
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();

  bool _showLinealidadFields = false;
  bool _showRepetibilidadFields = false;
  int _selectedRepetibilityCount = 1;
  int _selectedRowCount = 3;
  bool _showPlatformFields = false;
  String _selectedUnit = 'kg';
  String? _selectedPlatform;
  String? _selectedOption;
  String? _selectedImagePath;
  double? _oneThirdpmax1;
  List<TextEditingController> _positionControllers = [];
  List<TextEditingController> _indicationControllers = [];
  List<TextEditingController> _returnControllers =
      List.generate(10, (index) => TextEditingController(text: '0'));
  List<bool> _isDynamicallyAdded = [];
  List<List<String>> _indicationDropdownItems = [];
  final List<Map<String, TextEditingController>> _rows = [];
  DateTime? _lastPressedTime;
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);

  final Map<String, List<String>> _platformOptions = {
    'Rectangular': [
      'Rectangular 3 pts - Ind Derecha',
      'Rectangular 3 pts - Ind Izquierda',
      'Rectangular 3 pts - Ind Frontal',
      'Rectangular 3 pts - Ind Atras',
      'Rectangular 5 pts - Ind Derecha',
      'Rectangular 5 pts - Ind Izquierda',
      'Rectangular 5 pts - Ind Frontal',
      'Rectangular 5 pts - Ind Atras'
    ],
    'Circular': [
      'Circular 5 pts - Ind Derecha',
      'Circular 5 pts - Ind Izquierda',
      'Circular 5 pts - Ind Frontal',
      'Circular 5 pts - Ind Atras',
      'Circular 4 pts - Ind Derecha',
      'Circular 4 pts - Ind Izquierda',
      'Circular 4 pts - Ind Frontal',
      'Circular 4 pts - Ind Atras'
    ],
    'Cuadrada': [
      'Cuadrada - Ind Derecha',
      'Cuadrada - Ind Izquierda',
      'Cuadrada - Ind Frontal',
      'Cuadrada - Ind Atras'
    ],
    'Triangular': [
      'Triangular - Ind Izquierda',
      'Triangular - Ind Frontal',
      'Triangular - Ind Atras',
      'Triangular - Ind Derecha'
    ],
    'Báscula de camión': [
      'Caceta de control Atras',
      'Caceta de control Frontal',
      'Caceta de control Izquierda',
      'Caceta de control Derecha'
    ],
  };

  final Map<String, String> _optionImages = {
    // Rectangular
    'Rectangular 3 pts - Ind Derecha': 'images/Rectangular_3D.png',
    'Rectangular 3 pts - Ind Izquierda': 'images/Rectangular_3I.png',
    'Rectangular 3 pts - Ind Frontal': 'images/Rectangular_3F.png',
    'Rectangular 3 pts - Ind Atras': 'images/Rectangular_3A.png',
    'Rectangular 5 pts - Ind Derecha': 'images/Rectangular_5D.png',
    'Rectangular 5 pts - Ind Izquierda': 'images/Rectangular_5I.png',
    'Rectangular 5 pts - Ind Frontal': 'images/Rectangular_5F.png',
    'Rectangular 5 pts - Ind Atras': 'images/Rectangular_5A.png',

    // Circular
    'Circular 5 pts - Ind Derecha': 'images/Circular_5D.png',
    'Circular 5 pts - Ind Izquierda': 'images/Circular_5I.png',
    'Circular 5 pts - Ind Frontal': 'images/Circular_5F.png',
    'Circular 5 pts - Ind Atras': 'images/Circular_5A.png',
    'Circular 4 pts - Ind Derecha': 'images/Circular_4D.png',
    'Circular 4 pts - Ind Izquierda': 'images/Circular_4I.png',
    'Circular 4 pts - Ind Frontal': 'images/Circular_4F.png',
    'Circular 4 pts - Ind Atras': 'images/Circular_4A.png',

    // Cuadrada
    'Cuadrada - Ind Derecha': 'images/Cuadrada_D.png',
    'Cuadrada - Ind Izquierda': 'images/Cuadrada_I.png',
    'Cuadrada - Ind Frontal': 'images/Cuadrada_F.png',
    'Cuadrada - Ind Atras': 'images/Cuadrada_A.png',

    // Triangular
    'Triangular - Ind Derecha': 'images/Triangular_D.png',
    'Triangular - Ind Izquierda': 'images/Triangular_I.png',
    'Triangular - Ind Frontal': 'images/Triangular_F.png',
    'Triangular - Ind Atras': 'images/Triangular_A.png',

    // Báscula de camión
    'Caceta de control Atras': 'images/Caceta_A.png',
    'Caceta de control Frontal': 'images/Caceta_F.png',
    'Caceta de control Izquierda': 'images/Caceta_I.png',
    'Caceta de control Derecha': 'images/Caceta_D.png',
  };

  @override
  void initState() {
    super.initState();
    _setupAllAutoSaveListeners(); // Agrega esta línea
    _cargaClienteController.addListener(_calcularSumatoria);
    _actualizarCargaDesdeUltimoLT(); // Inicializar carga
    _agregarFila(); // LT 1 vacío
    _agregarFila(); // LT 2 vacío
    _actualizarUltimaCarga();

    _actualizarHora(); // Llama a esta función al iniciar
    _fieldData.addAll({
      'Carcasa': {'value': '4 No aplica'},
      'Conector y Cables': {'value': '4 No aplica'},
      'Alimentación': {'value': '4 No aplica'},
      'Pantalla': {'value': '4 No aplica'},
      'Teclado': {'value': '4 No aplica'},
      'Bracket y columna': {'value': '4 No aplica'},
      'Limpieza de Fosa': {'value': '4 No aplica'},
      'Estado de Drenaje': {'value': '4 No aplica'},
      'Plato de Carga': {'value': '4 No aplica'},
      'Estructura': {'value': '4 No aplica'},
      'Topes de Carga': {'value': '4 No aplica'},
      'Patas': {'value': '4 No aplica'},
      'Limpieza': {'value': '4 No aplica'},
      'Bordes y puntas': {'value': '4 No aplica'},
      'Otros': {'value': '4 No aplica'},
      'Célula(s)': {'value': '4 No aplica'},
      'Cable(s)': {'value': '4 No aplica'},
      'Cubierta de Silicona': {'value': '4 No aplica'},
    });

    // Inicializar comentarios predeterminados
    _limpiezaFosaComentarioController.text = 'Sin Comentario';
    _estadoDrenajeComentarioController.text = 'Sin Comentario';
    _otrosComentarioController.text = 'Sin Comentario';
    _nivelacionComentarioController.text = 'Sin Comentario';
    _movilizacionComentarioController.text = 'Sin Comentario';
    _carcasaComentarioController.text = 'Sin Comentario';
    _conectorComentarioController.text = 'Sin Comentario';
    _alimentacionComentarioController.text = 'Sin Comentario';
    _pantallaComentarioController.text = 'Sin Comentario';
    _tecladoComentarioController.text = 'Sin Comentario';
    _bracketComentarioController.text = 'Sin Comentario';
    _platoCargaComentarioController.text = 'Sin Comentario';
    _estructuraComentarioController.text = 'Sin Comentario';
    _topesCargaComentarioController.text = 'Sin Comentario';
    _patasComentarioController.text = 'Sin Comentario';
    _limpiezaComentarioController.text = 'Sin Comentario';
    _bordesPuntasComentarioController.text = 'Sin Comentario';
    _entornoComentarioController.text = 'Sin Comentario';
    _flujoPesadasComentarioController.text = 'Sin Comentario';
    _celulasComentarioController.text = 'Sin Comentario';
    _cablesComentarioController.text = 'Sin Comentario';
    _cubiertaSiliconaComentarioController.text = 'Sin Comentario';

    // Inicializar controladores adicionales
    _initializeControllers();
  }

  void _initializeControllers() {
    _positionControllers = [];
    _indicationControllers = [];
    _returnControllers =
        List.generate(10, (index) => TextEditingController(text: '0'));
    _isDynamicallyAdded = [];
    _indicationDropdownItems = [];
  }

  void _actualizarUltimaCarga() {
    if (_rows.isEmpty) {
      _cargaLnController.text = '0';
      return;
    }
    // Obtener el último valor de LT (ignorando vacíos)
    for (int i = _rows.length - 1; i >= 0; i--) {
      final ltValue = _rows[i]['lt']?.text.trim();
      if (ltValue != null && ltValue.isNotEmpty) {
        _cargaLnController.text = ltValue;
        return;
      }
    }

    _cargaLnController.text = '0';
  }

  void _agregarFila() {
    setState(() {
      _rows.add({
        'lt': TextEditingController(), // Se inicializa sin texto
        'indicacion': TextEditingController(), // Se inicializa sin texto
        'retorno': TextEditingController(text: '0'),
      });

      // Escuchar cambios en los campos LT
      _rows.last['lt']?.addListener(_actualizarUltimaCarga);
    });
  }

  void _removerFila(BuildContext context, int index) {
    if (_rows.length <= 2) {
      _showSnackBar(context, 'Debe mantener al menos 2 filas');
      return;
    }
    setState(() {
      // Limpiar controladores antes de remover
      _rows[index]['lt']?.dispose();
      _rows[index]['indicacion']?.dispose();
      _rows[index]['retorno']?.dispose();
      _rows.removeAt(index);
      _actualizarUltimaCarga();
    });
  }

  void _guardarCarga(BuildContext context) {
    if (_sumatoriaController.text.isEmpty) {
      _showSnackBar(context, 'Calcule la sumatoria primero');
      return;
    }

    setState(() {
      // Primero buscar filas vacías
      for (var row in _rows) {
        if (row['lt']?.text.isEmpty ?? true) {
          // Llenar la primera fila vacía que encuentre
          row['lt']?.text = _sumatoriaController.text;
          row['indicacion']?.text = _sumatoriaController.text;

          // Limpiar para nueva entrada
          _cargaClienteController.clear();
          _sumatoriaController.clear();
          _actualizarUltimaCarga();
          return;
        }
      }

      // Si no hay filas vacías, agregar nueva fila
      _agregarFila();
      _rows.last['lt']?.text = _sumatoriaController.text;
      _rows.last['indicacion']?.text = _sumatoriaController.text;

      // Limpiar para nueva entrada
      _cargaClienteController.clear();
      _sumatoriaController.clear();
      _actualizarUltimaCarga();
    });
  }

  void _actualizarCargaDesdeUltimoLT() {
    if (_rows.isEmpty) {
      _cargaController.text = '0'; // Valor por defecto
      return;
    }

    final ultimoLT = _rows.last['lt']?.text;
    if (ultimoLT != null && ultimoLT.isNotEmpty) {
      _cargaController.text = ultimoLT;
    }
  }

  void _calcularSumatoria() {
    final cargaLn = double.tryParse(_cargaLnController.text) ?? 0;
    final cargaCliente = double.tryParse(_cargaClienteController.text) ?? 0;
    _sumatoriaController.text = (cargaLn + cargaCliente).toStringAsFixed(2);
  }

  void _updatePositions() {
    if (_selectedOption == null) return;

    int numberOfPositions = _getNumberOfPositions(_selectedOption!);
    _initializeControllers();

    // Usar el controlador correcto para excentricidad (_cargaExcController)
    final cargaValue =
        _cargaExcController.text.isNotEmpty ? _cargaExcController.text : '0';

    for (int i = 0; i < numberOfPositions; i++) {
      _positionControllers.add(TextEditingController(text: (i + 1).toString()));
      _indicationControllers.add(TextEditingController(text: cargaValue));
      _returnControllers.add(TextEditingController(text: '0'));
      _isDynamicallyAdded.add(false);
      _indicationDropdownItems.add([]);

      // Actualizar dropdown items si hay un valor en carga
      final doubleValue = double.tryParse(cargaValue);
      if (doubleValue != null) {
        _updateIndicationDropdownItems(i, doubleValue);
      }
    }

    setState(() {});
  }

  int _getNumberOfPositions(String platform) {
    if (platform == 'Báscula de camión') return 6;
    if (platform.contains('3')) return 3;
    if (platform.contains('4')) return 4;
    if (platform.contains('5')) return 5;
    if (platform.startsWith('Cuadrada')) return 5;
    if (platform.startsWith('Triangular')) return 4;
    return 0;
  }

  Future<bool> _doesTableExist(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<double> _getD1FromDatabase() async {
    try {
      String path = join(await getDatabasesPath(), '${widget.dbName}.db');
      final db = await openDatabase(path);

      // Verificar si la tabla existe primero
      final tableExists = await _doesTableExist(db, 'inf_cliente_balanza');
      if (!tableExists) return 0.1;

      final List<Map<String, dynamic>> result = await db.query(
          'inf_cliente_balanza',
          where: 'id = ?',
          whereArgs: [1],
          columns: ['d1'],
          limit: 1);

      if (result.isNotEmpty && result.first['d1'] != null) {
        return double.tryParse(result.first['d1'].toString()) ?? 0.1;
      }
      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1;
    }
  }

  void _updateIndicationDropdownItems(int index, double value) {
    setState(() {
      _indicationDropdownItems[index] = [
        ...List.generate(5, (i) => (value + (i + 1)).toStringAsFixed(0))
            .reversed,
        value.toStringAsFixed(0),
        ...List.generate(5, (i) => (value - (i + 1)).toStringAsFixed(0)),
      ];
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
            style: TextStyle(color: Colors.white), // Texto blanco
          ),
          backgroundColor: Colors.orange, // Fondo naranja
        ),
      );
      return false;
    }
    return true;
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
                      _autoSaveData();
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

  void _updateIndicacionValues(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionControllers1) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValues2(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionControllers2) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValues3(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionControllers3) {
        controller.text = value;
      }
    });
  }

  Widget _buildRepetibilidadFields() {
    if (!_showRepetibilidadFields) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          'PRUEBAS DE REPETIBILIDAD',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: _selectedRepetibilityCount,
          items: [1, 2, 3]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRepetibilityCount = value ?? 1;
            });
          },
          decoration: _buildInputDecoration('Cantidad de Cargas'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: _selectedRowCount,
          items: [3, 5, 10]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRowCount = value ?? 3;
            });
          },
          decoration: _buildInputDecoration('Cantidad de Pruebas'),
        ),
        const SizedBox(height: 20),
        if (_selectedRepetibilityCount >= 1) ...[
          const Text(
            'CARGA 1',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadController1,
            decoration: _buildInputDecoration('Carga 1'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValues,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Por favor ingrese un valor' : null,
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCount; i++)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<double>(
                        future: _getD1FromDatabase(),
                        builder: (context, snapshot) {
                          // Obtener d1 del Provider primero (más eficiente que la base de datos)
                          final balanza = Provider.of<BalanzaProvider>(context,
                                  listen: false)
                              .selectedBalanza;
                          final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                          // Función para calcular decimales significativos (ignora ceros a la derecha)
                          int getSignificantDecimals(double value) {
                            final parts = value.toString().split('.');
                            if (parts.length == 2) {
                              return parts[1]
                                  .replaceAll(RegExp(r'0+$'), '')
                                  .length;
                            }
                            return 0;
                          }

                          final decimalPlaces = getSignificantDecimals(d1);

                          return TextFormField(
                            controller: _indicacionControllers1[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() => _indicacionControllers1[i]
                                      .text = newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionControllers1[i].text) ??
                                      0.0;

                                  // Generar 11 opciones (-5d1 a +5d1) de forma más eficiente
                                  return List.generate(11, (index) {
                                    final multiplier =
                                        index - 5; // Rango de -5 a +5
                                    final value = baseValue + (multiplier * d1);
                                    final formattedValue =
                                        value.toStringAsFixed(decimalPlaces);

                                    return PopupMenuItem<String>(
                                      value: formattedValue,
                                      child: Text(formattedValue),
                                    );
                                  });
                                },
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un valor';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Valor numérico inválido';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _retornoControllers1[i],
                        decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Por favor ingrese un valor'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
        ],
        if (_selectedRepetibilityCount >= 2) ...[
          const Text(
            'CARGA 2',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadController2,
            decoration: _buildInputDecoration('Carga 2'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValues2,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Por favor ingrese un valor';
              if (value == _repetibilidadController1.text) {
                return 'El valor debe ser diferente de Carga 1';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCount; i++)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<double>(
                        future: _getD1FromDatabase(),
                        builder: (context, snapshot) {
                          // Obtener d1 del Provider primero (más eficiente que la base de datos)
                          final balanza = Provider.of<BalanzaProvider>(context,
                                  listen: false)
                              .selectedBalanza;
                          final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                          // Función para calcular decimales significativos (ignora ceros a la derecha)
                          int getSignificantDecimals(double value) {
                            final parts = value.toString().split('.');
                            if (parts.length == 2) {
                              return parts[1]
                                  .replaceAll(RegExp(r'0+$'), '')
                                  .length;
                            }
                            return 0;
                          }

                          final decimalPlaces = getSignificantDecimals(d1);

                          return TextFormField(
                            controller: _indicacionControllers2[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() => _indicacionControllers2[i]
                                      .text = newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionControllers2[i].text) ??
                                      0.0;

                                  // Generar 11 opciones (-5d1 a +5d1) de forma más eficiente
                                  return List.generate(11, (index) {
                                    final multiplier =
                                        index - 5; // Rango de -5 a +5
                                    final value = baseValue + (multiplier * d1);
                                    final formattedValue =
                                        value.toStringAsFixed(decimalPlaces);

                                    return PopupMenuItem<String>(
                                      value: formattedValue,
                                      child: Text(formattedValue),
                                    );
                                  });
                                },
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese un valor';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Valor numérico inválido';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _retornoControllers2[i],
                        decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Por favor ingrese un valor'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
        ],
        if (_selectedRepetibilityCount == 3) ...[
          const Text(
            'CARGA 3',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadController3,
            decoration: _buildInputDecoration('Carga 3'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValues3,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Por favor ingrese un valor';
              if (value == _repetibilidadController1.text ||
                  value == _repetibilidadController2.text) {
                return 'El valor debe ser diferente de Carga 1 y 2';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCount; i++)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<double>(
                        future: _getD1FromDatabase(),
                        builder: (context, snapshot) {
                          // Obtener d1 del Provider primero (más eficiente que la base de datos)
                          final balanza = Provider.of<BalanzaProvider>(context,
                                  listen: false)
                              .selectedBalanza;
                          final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                          // Función para calcular decimales significativos (ignora ceros a la derecha)
                          int getSignificantDecimals(double value) {
                            final parts = value.toString().split('.');
                            if (parts.length == 2) {
                              return parts[1]
                                  .replaceAll(RegExp(r'0+$'), '')
                                  .length;
                            }
                            return 0;
                          }

                          final decimalPlaces = getSignificantDecimals(d1);

                          return TextFormField(
                            controller: _indicacionControllers3[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() => _indicacionControllers3[i]
                                      .text = newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionControllers3[i].text) ??
                                      0.0;

                                  // Generar 11 opciones (-5d1 a +5d1) de forma más eficiente
                                  return List.generate(11, (index) {
                                    final multiplier =
                                        index - 5; // Rango de -5 a +5
                                    final value = baseValue + (multiplier * d1);
                                    final formattedValue =
                                        value.toStringAsFixed(decimalPlaces);

                                    return PopupMenuItem<String>(
                                      value: formattedValue,
                                      child: Text(formattedValue),
                                    );
                                  });
                                },
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese un valor';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Valor numérico inválido';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _retornoControllers3[i],
                        decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Por favor ingrese un valor'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
        ],
      ],
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

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon, // Agregar el parámetro suffixIcon
    );
  }

  Widget _buildPlatformFields() {
    if (!_showPlatformFields) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'INFORMACIÓN DE PLATAFORMA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedPlatform,
          decoration: _buildInputDecoration('Tipo de Plataforma'),
          items: _platformOptions.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPlatform = newValue;
              _selectedOption = null;
              _selectedImagePath = null;
              _updatePositions();
            });
          },
        ),
        const SizedBox(height: 20),
        if (_selectedPlatform != null)
          DropdownButtonFormField<String>(
            value: _selectedOption,
            decoration: _buildInputDecoration('Puntos e Indicador'),
            items: _platformOptions[_selectedPlatform]!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedOption = newValue;
                _selectedImagePath = _optionImages[newValue!];
                _updatePositions();
              });
            },
          ),
        const SizedBox(height: 20),
        if (_selectedImagePath != null) Image.asset(_selectedImagePath!),
        const SizedBox(height: 20),
        TextFormField(
          controller: _cargaExcController,
          decoration: _buildInputDecoration('Carga'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null) {
              // Actualizar solo los campos de indicación
              for (int i = 0; i < _indicationControllers.length; i++) {
                _indicationControllers[i].text = value;
                _updateIndicationDropdownItems(i, doubleValue);
              }
              // No actualizar los campos de retorno (se mantienen en 0)
            }
          },
          style: TextStyle(
            color: (_cargaController.text.isNotEmpty &&
                    double.tryParse(_cargaController.text) != null &&
                    _oneThirdpmax1 != null &&
                    double.parse(_cargaController.text) < _oneThirdpmax1!)
                ? Colors.red
                : null,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _positionControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionControllers[index],
                      decoration:
                          _buildInputDecoration('Posición ${index + 1}'),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _indicationControllers[index],
                          decoration: buildInputDecoration(
                            'Indicación',
                            suffixIcon: FutureBuilder<double>(
                              future: _getD1FromDatabase(),
                              builder: (context, snapshot) {
                                // Obtener d1 del snapshot o del Provider
                                final balanza = Provider.of<BalanzaProvider>(
                                        context,
                                        listen: false)
                                    .selectedBalanza;
                                final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                                // Función para determinar decimales significativos
                                int getSignificantDecimals(double value) {
                                  String text = value.toString();
                                  if (text.contains('.')) {
                                    return text
                                        .split('.')[1]
                                        .replaceAll(RegExp(r'0*$'), '')
                                        .length;
                                  }
                                  return 0;
                                }

                                final decimalPlaces =
                                    getSignificantDecimals(d1);

                                return PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String newValue) {
                                    setState(() {
                                      _indicationControllers[index].text =
                                          newValue;
                                    });
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final baseValue = double.tryParse(
                                            _indicationControllers[index]
                                                .text) ??
                                        0.0;

                                    List<String> options = [
                                      // Valores incrementados (+1d1 a +5d1)
                                      for (int i = 1; i <= 5; i++)
                                        (baseValue + (i * d1))
                                            .toStringAsFixed(decimalPlaces),
                                      // Valor actual
                                      baseValue.toStringAsFixed(decimalPlaces),
                                      // Valores decrementados (-1d1 a -5d1)
                                      for (int i = 1; i <= 5; i++)
                                        (baseValue - (i * d1))
                                            .toStringAsFixed(decimalPlaces),
                                    ];

                                    return options
                                        .map((value) => PopupMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ))
                                        .toList();
                                  },
                                );
                              },
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese un valor';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Número inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _returnControllers[index],
                          decoration: _buildInputDecoration('Retorno'),
                          keyboardType: TextInputType.number,
                          // Inicializar en 0 y permitir edición manual
                          onChanged: (value) {
                            if (value.isEmpty) {
                              _returnControllers[index].text = '0';
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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

  Widget _buildLinealidadFields(BuildContext context) {
    if (!_showLinealidadFields) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'PRUEBAS DE LINEALIDAD',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Sección de Carga e Incremento
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cargaLnController,
                decoration: _buildInputDecoration('Última Carga de LT'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _cargaClienteController,
                decoration: _buildInputDecoration('Carga'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calcularSumatoria(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sumatoriaController,
                decoration: _buildInputDecoration('Incremento'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _guardarCarga(context); // Pasar el contexto explícitamente
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('GUARDAR CARGA'),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        const Text(
          'CARGAS REGISTRADAS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10.0),

        // Lista de filas
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rows.length,
          itemBuilder: (context, index) {
            return _buildFilaLinealidad(index);
          },
        ),
        const SizedBox(height: 10),

        // Botones de control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _agregarFila,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: () => _removerFila(context, _rows.length - 1),
              icon: const Icon(Icons.remove, color: Colors.white),
              label: const Text('Eliminar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilaLinealidad(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _rows[index]['lt'],
              decoration: _buildInputDecoration('LT ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                // Actualizar indicación automáticamente
                if (value.isNotEmpty) {
                  _rows[index]['indicacion']?.text = value;
                }
                _actualizarUltimaCarga();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _rows[index]['indicacion'],
              decoration: _buildInputDecoration('Indicación ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSaveData({bool force = false}) async {
    if (_isAutoSaving && !force) return;

    // Cancelar el timer anterior si existe
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    // Configurar un nuevo timer con debounce
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      _isAutoSaving = true;

      try {
        final path = join(widget.dbPath, '${widget.dbName}.db');
        final db = await openDatabase(path);

        // Preparar datos para insertar/actualizar
        final Map<String, dynamic> relevamientoData = {
          // Condiciones generales del instrumento
          'carcasa': _fieldData['Carcasa']?['value'] ?? '',
          'carcasa_comentario': _carcasaComentarioController.text,
          'carcasa_foto': _fieldData['Carcasa']?['foto'] ?? '',

          'conector_cables': _fieldData['Conector y Cables']?['value'] ?? '',
          'conector_cables_comentario': _conectorComentarioController.text,
          'conector_cables_foto':
              _fieldData['Conector y Cables']?['foto'] ?? '',

          'alimentacion': _fieldData['Alimentación']?['value'] ?? '',
          'alimentacion_comentario': _alimentacionComentarioController.text,
          'alimentacion_foto': _fieldData['Alimentación']?['foto'] ?? '',

          'pantalla': _fieldData['Pantalla']?['value'] ?? '',
          'pantalla_comentario': _pantallaComentarioController.text,
          'pantalla_foto': _fieldData['Pantalla']?['foto'] ?? '',

          'teclado': _fieldData['Teclado']?['value'] ?? '',
          'teclado_comentario': _tecladoComentarioController.text,
          'teclado_foto': _fieldData['Teclado']?['foto'] ?? '',

          'bracket_columna': _fieldData['Bracket y columna']?['value'] ?? '',
          'bracket_columna_comentario': _bracketComentarioController.text,
          'bracket_columna_foto':
              _fieldData['Bracket y columna']?['foto'] ?? '',

          'plato_carga': _fieldData['Plato de Carga']?['value'] ?? '',
          'plato_carga_comentario': _platoCargaComentarioController.text,
          'plato_carga_foto': _fieldData['Plato de Carga']?['foto'] ?? '',

          'estructura': _fieldData['Estructura']?['value'] ?? '',
          'estructura_comentario': _estructuraComentarioController.text,
          'estructura_foto': _fieldData['Estructura']?['foto'] ?? '',

          'topes_carga': _fieldData['Topes de Carga']?['value'] ?? '',
          'topes_carga_comentario': _topesCargaComentarioController.text,
          'topes_carga_foto': _fieldData['Topes de Carga']?['foto'] ?? '',

          'patas': _fieldData['Patas']?['value'] ?? '',
          'patas_comentario': _patasComentarioController.text,
          'patas_foto': _fieldData['Patas']?['foto'] ?? '',

          'limpieza': _fieldData['Limpieza']?['value'] ?? '',
          'limpieza_comentario': _limpiezaComentarioController.text,
          'limpieza_foto': _fieldData['Limpieza']?['foto'] ?? '',

          'bordes_puntas': _fieldData['Bordes y puntas']?['value'] ?? '',
          'bordes_puntas_comentario': _bordesPuntasComentarioController.text,
          'bordes_puntas_foto': _fieldData['Bordes y puntas']?['foto'] ?? '',

          'celulas': _fieldData['Célula(s)']?['value'] ?? '',
          'celulas_comentario': _celulasComentarioController.text,
          'celulas_foto': _fieldData['Célula(s)']?['foto'] ?? '',

          'cables': _fieldData['Cables']?['value'] ?? '',
          'cables_comentario': _cablesComentarioController.text,
          'cables_foto': _fieldData['Cables']?['foto'] ?? '',

          'cubierta_silicona':
              _fieldData['Cubierta de Silicona']?['value'] ?? '',
          'cubierta_silicona_comentario':
              _cubiertaSiliconaComentarioController.text,
          'cubierta_silicona_foto':
              _fieldData['Cubierta de Silicona']?['foto'] ?? '',

          'entorno': _fieldData['Entorno']?['value'] ?? '',
          'entorno_comentario': _entornoComentarioController.text,
          'entorno_foto': _fieldData['Entorno']?['foto'] ?? '',

          'nivelacion': _fieldData['Nivelación']?['value'] ?? '',
          'nivelacion_comentario': _nivelacionComentarioController.text,
          'nivelacion_foto': _fieldData['Nivelación']?['foto'] ?? '',

          'movilizacion': _fieldData['Movilización']?['value'] ?? '',
          'movilizacion_comentario': _movilizacionComentarioController.text,
          'movilizacion_foto': _fieldData['Movilización']?['foto'] ?? '',

          'flujo_pesas': _fieldData['Flujo de Pesas']?['value'] ?? '',
          'flujo_pesas_comentario': _flujoPesasComentarioController.text,
          'flujo_pesas_foto': _fieldData['Flujo de Pesas']?['foto'] ?? '',

          // Pruebas metrológicas
          'retorno_cero': _retornoCeroDropdownController.value,
          'carga_retorno_cero': _retornoCeroValorController.text,

          // Excentricidad
          'tipo_plataforma': _selectedPlatform ?? '',
          'puntos_ind': _selectedOption ?? '',
          'carga': _cargaExcController.text,

          // Horas
          'hora_inicio': _horaController.text,
          'hora_fin': _horaFinController.text,
        };

        // Agregar datos de posiciones de excentricidad
        for (int i = 0; i < _positionControllers.length; i++) {
          final position = i + 1;
          relevamientoData.addAll({
            'posicion$position': _positionControllers[i].text,
            'indicacion$position': _indicationControllers[i].text,
            'retorno$position': _returnControllers[i].text,
          });
        }

        // Agregar datos de repetibilidad
        if (_showRepetibilidadFields) {
          relevamientoData['repetibilidad1'] = _repetibilidadController1.text;
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion1_$testNum': _indicacionControllers1[i].text,
              'retorno1_$testNum': _retornoControllers1[i].text,
            });
          }

          if (_selectedRepetibilityCount >= 2) {
            relevamientoData['repetibilidad2'] = _repetibilidadController2.text;
            for (int i = 0; i < _selectedRowCount; i++) {
              final testNum = i + 1;
              relevamientoData.addAll({
                'indicacion2_$testNum': _indicacionControllers2[i].text,
                'retorno2_$testNum': _retornoControllers2[i].text,
              });
            }
          }

          if (_selectedRepetibilityCount >= 3) {
            relevamientoData['repetibilidad3'] = _repetibilidadController3.text;
            for (int i = 0; i < _selectedRowCount; i++) {
              final testNum = i + 1;
              relevamientoData.addAll({
                'indicacion3_$testNum': _indicacionControllers3[i].text,
                'retorno3_$testNum': _retornoControllers3[i].text,
              });
            }
          }
        }

        // Agregar datos de linealidad
        if (_showLinealidadFields) {
          for (int i = 0; i < _rows.length; i++) {
            final pointNum = i + 1;
            relevamientoData.addAll({
              'lin$pointNum': _rows[i]['lt']?.text ?? '',
              'ind$pointNum': _rows[i]['indicacion']?.text ?? '',
              'retorno_lin$pointNum': _rows[i]['retorno']?.text ?? '0',
            });
          }
        }

        // Verificar si ya existe un registro
        final existingRecord = await db.query(
          'relevamiento_de_datos',
          where: 'id = ?',
          whereArgs: [1],
        );

        // Guardar o actualizar
        if (existingRecord.isNotEmpty) {
          await db.update(
            'relevamiento_de_datos',
            relevamientoData,
            where: 'id = ?',
            whereArgs: [1],
          );
        } else {
          await db.insert(
            'relevamiento_de_datos',
            relevamientoData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await db.close();
        debugPrint('Datos guardados automáticamente');

        // Actualizar el estado para habilitar el botón "SIGUIENTE"
        if (!_isDataSaved.value) {
          _isDataSaved.value = true;
        }
      } catch (e) {
        debugPrint('Error en autoguardado: $e');
      } finally {
        _isAutoSaving = false;
      }
    });
  }

  Future<void> _saveAllDataAndPhotos(BuildContext context) async {
    // Verificar si hay fotos en alguno de los campos
    bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      // Guardar las fotos en un archivo ZIP
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
          '${widget.otValue}_${widget.codMetrica}_relevamiento_de_datos_fotos.zip';

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
      // Mostrar mensaje si no hay fotos
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

    // Guardar los datos en la base de datos (usando tu función existente)
    await _saveRelevamientoData(context);
  }

  Future<void> _saveRelevamientoData(BuildContext context) async {
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

    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _horaController.text = horaFormateada;

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
      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      // Preparar datos para insertar/actualizar
      final Map<String, dynamic> relevamientoData = {
        'tipo_servicio': 'relevamiento de datos',
        'cod_metrica': widget.codMetrica,
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,
        'comentario_general': _comentarioGeneralController.text,
        'recomendaciones': _selectedRecommendation,

        // Condiciones generales
        'carcasa': _fieldData['Carcasa']?['value'] ?? '',
        'carcasa_comentario': _carcasaComentarioController.text,
        'carcasa_foto': _fieldData['Carcasa']?['foto'] ?? '',

        'conector_cables': _fieldData['Conector y Cables']?['value'] ?? '',
        'conector_cables_comentario': _conectorComentarioController.text,
        'conector_cables_foto': _fieldData['Conector y Cables']?['foto'] ?? '',

        'alimentacion': _fieldData['Alimentación']?['value'] ?? '',
        'alimentacion_comentario': _alimentacionComentarioController.text,
        'alimentacion_foto': _fieldData['Alimentación']?['foto'] ?? '',

        'pantalla': _fieldData['Pantalla']?['value'] ?? '',
        'pantalla_comentario': _pantallaComentarioController.text,
        'pantalla_foto': _fieldData['Pantalla']?['foto'] ?? '',

        'teclado': _fieldData['Teclado']?['value'] ?? '',
        'teclado_comentario': _tecladoComentarioController.text,
        'teclado_foto': _fieldData['Teclado']?['foto'] ?? '',

        'bracket_columna': _fieldData['Bracket y columna']?['value'] ?? '',
        'bracket_columna_comentario': _bracketComentarioController.text,
        'bracket_columna_foto': _fieldData['Bracket y columna']?['foto'] ?? '',

        'plato_carga': _fieldData['Plato de Carga']?['value'] ?? '',
        'plato_carga_comentario': _platoCargaComentarioController.text,
        'plato_carga_foto': _fieldData['Plato de Carga']?['foto'] ?? '',

        'estructura': _fieldData['Estructura']?['value'] ?? '',
        'estructura_comentario': _estructuraComentarioController.text,
        'estructura_foto': _fieldData['Estructura']?['foto'] ?? '',

        'topes_carga': _fieldData['Topes de Carga']?['value'] ?? '',
        'topes_carga_comentario': _topesCargaComentarioController.text,
        'topes_carga_foto': _fieldData['Topes de Carga']?['foto'] ?? '',

        'patas': _fieldData['Patas']?['value'] ?? '',
        'patas_comentario': _patasComentarioController.text,
        'patas_foto': _fieldData['Patas']?['foto'] ?? '',

        'limpieza': _fieldData['Limpieza']?['value'] ?? '',
        'limpieza_comentario': _limpiezaComentarioController.text,
        'limpieza_foto': _fieldData['Limpieza']?['foto'] ?? '',

        'bordes_puntas': _fieldData['Bordes y puntas']?['value'] ?? '',
        'bordes_puntas_comentario': _bordesPuntasComentarioController.text,
        'bordes_puntas_foto': _fieldData['Bordes y puntas']?['foto'] ?? '',

        'celulas': _fieldData['Célula(s)']?['value'] ?? '',
        'celulas_comentario': _celulasComentarioController.text,
        'celulas_foto': _fieldData['Célula(s)']?['foto'] ?? '',

        'cables': _fieldData['Cable(s)']?['value'] ?? '',
        'cables_comentario': _cablesComentarioController.text,
        'cables_foto': _fieldData['Cable(s)']?['foto'] ?? '',

        'cubierta_silicona': _fieldData['Cubierta de Silicona']?['value'] ?? '',
        'cubierta_silicona_comentario': _cubiertaSiliconaComentarioController.text,
        'cubierta_silicona_foto': _fieldData['Cubierta de Silicona']?['foto'] ?? '',

        'entorno': _fieldData['Entorno']?['value'] ?? '',
        'entorno_comentario': _entornoComentarioController.text,
        'entorno_foto': _fieldData['Entorno']?['foto'] ?? '',

        'nivelacion': _fieldData['Nivelación']?['value'] ?? '',
        'nivelacion_comentario': _nivelacionComentarioController.text,
        'nivelacion_foto': _fieldData['Nivelación']?['foto'] ?? '',

        'movilizacion': _fieldData['Movilización']?['value'] ?? '',
        'movilizacion_comentario': _movilizacionComentarioController.text,
        'movilizacion_foto': _fieldData['Movilización']?['foto'] ?? '',

        'flujo_pesas': _fieldData['Flujo de Pesadas']?['value'] ?? '',
        'flujo_pesas_comentario': _flujoPesasComentarioController.text,
        'flujo_pesas_foto': _fieldData['Flujo de Pesas']?['foto'] ?? '',

        // Excentricidad
        'tipo_plataforma': _selectedPlatform ?? '',
        'puntos_ind': _selectedOption ?? '',
        'carga': _cargaExcController.text,
      };

      // Agregar datos de posiciones de excentricidad
      for (int i = 0; i < _positionControllers.length; i++) {
        final position = i + 1;
        relevamientoData.addAll({
          'posicion$position': _positionControllers[i].text,
          'indicacion$position': _indicationControllers[i].text,
          'retorno$position': _returnControllers[i].text,
        });
      }

      // Agregar datos de repetibilidad
      if (_showRepetibilidadFields) {
        // Carga 1
        relevamientoData['repetibilidad1'] = _repetibilidadController1.text;
        for (int i = 0; i < _selectedRowCount; i++) {
          final testNum = i + 1;
          relevamientoData.addAll({
            'indicacion1_$testNum': _indicacionControllers1[i].text,
            'retorno1_$testNum': _retornoControllers1[i].text,
          });
        }

        // Carga 2 (si aplica)
        if (_selectedRepetibilityCount >= 2) {
          relevamientoData['repetibilidad2'] = _repetibilidadController2.text;
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion2_$testNum': _indicacionControllers2[i].text,
              'retorno2_$testNum': _retornoControllers2[i].text,
            });
          }
        }

        // Carga 3 (si aplica)
        if (_selectedRepetibilityCount >= 3) {
          relevamientoData['repetibilidad3'] = _repetibilidadController3.text;
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion3_$testNum': _indicacionControllers3[i].text,
              'retorno3_$testNum': _retornoControllers3[i].text,
            });
          }
        }
      }

      // Agregar datos de linealidad
      if (_showLinealidadFields) {
        for (int i = 0; i < _rows.length; i++) {
          final pointNum = i + 1;
          relevamientoData.addAll({
            'lin$pointNum': _rows[i]['lt']?.text ?? '',
            'ind$pointNum': _rows[i]['indicacion']?.text ?? '',
            'retorno_lin$pointNum': _rows[i]['retorno']?.text ?? '0',
          });
        }
      }

      // Verificar si ya existe un registro
      final existingRecord = await db.query(
        'relevamiento_de_datos',
        where: 'id = ?',
        whereArgs: [1],
      );

      // Guardar o actualizar
      if (existingRecord.isNotEmpty) {
        await db.update(
          'relevamiento_de_datos',
          relevamientoData,
          where: 'id = ?',
          whereArgs: [1],
        );
      } else {
        await db.insert(
          'relevamiento_de_datos',
          relevamientoData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await db.close();

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

  void _setupTextControllerListeners() {
    // Lista de todos los controladores de texto
    final controllers = [
      _carcasaComentarioController,
      _conectorComentarioController,
      _alimentacionComentarioController,
      _pantallaComentarioController,
      _tecladoComentarioController,
      _bracketComentarioController,
      _platoCargaComentarioController,
      _estructuraComentarioController,
      _topesCargaComentarioController,
      _patasComentarioController,
      _limpiezaComentarioController,
      _bordesPuntasComentarioController,
      _celulasComentarioController,
      _cablesComentarioController,
      _cubiertaSiliconaComentarioController,
      _entornoComentarioController,
      _nivelacionComentarioController,
      _movilizacionComentarioController,
      _flujoPesasComentarioController,
      _retornoCeroValorController,
      _horaController,
      _horaFinController,
      _cargaExcController,
      _repetibilidadController1,
      _repetibilidadController2,
      _repetibilidadController3,
      _cargaLnController,
      _cargaClienteController,
      _sumatoriaController,
      _comentarioController,
      _pmax1Controller,
      _oneThirdPmax1Controller,
      _notaController,
    ];

    // Agregar listener a cada controlador
    for (var controller in controllers) {
      controller.addListener(_autoSaveData);
    }

    // Para los controladores en las filas dinámicas
    for (var row in _rows) {
      row['lt']?.addListener(_autoSaveData);
      row['indicacion']?.addListener(_autoSaveData);
      row['retorno']?.addListener(_autoSaveData);
    }

    // Para los controladores de excentricidad
    for (var controller in _positionControllers) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _indicationControllers) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _returnControllers) {
      controller.addListener(_autoSaveData);
    }

    // Para los controladores de repetibilidad
    for (var controller in _indicacionControllers1) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _retornoControllers1) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _indicacionControllers2) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _retornoControllers2) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _indicacionControllers3) {
      controller.addListener(_autoSaveData);
    }
    for (var controller in _retornoControllers3) {
      controller.addListener(_autoSaveData);
    }
  }

  void _removeAllAutoSaveListeners() {
    // Lista de todos los controladores de texto
    final controllers = [
      _carcasaComentarioController,
      _conectorComentarioController,
      _alimentacionComentarioController,
      _pantallaComentarioController,
      _tecladoComentarioController,
      _bracketComentarioController,
      _platoCargaComentarioController,
      _estructuraComentarioController,
      _topesCargaComentarioController,
      _patasComentarioController,
      _limpiezaComentarioController,
      _bordesPuntasComentarioController,
      _celulasComentarioController,
      _cablesComentarioController,
      _cubiertaSiliconaComentarioController,
      _entornoComentarioController,
      _nivelacionComentarioController,
      _movilizacionComentarioController,
      _flujoPesasComentarioController,
      _retornoCeroValorController,
      _horaController,
      _horaFinController,
      _cargaExcController,
      _repetibilidadController1,
      _repetibilidadController2,
      _repetibilidadController3,
      _cargaLnController,
      _cargaClienteController,
      _sumatoriaController,
      _comentarioController,
      _pmax1Controller,
      _oneThirdPmax1Controller,
      _notaController,
    ];

    // Remover listener de cada controlador
    for (var controller in controllers) {
      controller.removeListener(_autoSaveData);
    }

    // Remover listeners de filas dinámicas
    for (var row in _rows) {
      row['lt']?.removeListener(_autoSaveData);
      row['indicacion']?.removeListener(_autoSaveData);
      row['retorno']?.removeListener(_autoSaveData);
    }

    // Remover listeners de excentricidad
    for (var controller in _positionControllers) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _indicationControllers) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _returnControllers) {
      controller.removeListener(_autoSaveData);
    }

    // Remover listeners de repetibilidad
    for (var controller in _indicacionControllers1) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _retornoControllers1) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _indicacionControllers2) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _retornoControllers2) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _indicacionControllers3) {
      controller.removeListener(_autoSaveData);
    }
    for (var controller in _retornoControllers3) {
      controller.removeListener(_autoSaveData);
    }

    // Remover listeners de ValueNotifiers
    _retornoCeroDropdownController.removeListener(_autoSaveData);
    _isDataSaved.removeListener(_autoSaveData);
  }

  Map<String, dynamic> _prepareDataForSave() {
    final data = {
      'cod_metrica': widget.codMetrica,
      'hora_inicio': _horaController.text,
      'hora_fin': _horaFinController.text,
    };

    final conditions = {
      'carcasa': _fieldData['Carcasa']?['value'] ?? '',
      'carcasa_comentario': _carcasaComentarioController.text,
      'carcasa_foto': _fieldData['Carcasa']?['foto'] ?? '',
      'conector_cables': _fieldData['Conector y Cables']?['value'] ?? '',
      'conector_cables_comentario': _conectorComentarioController.text,
      'conector_cables_foto': _fieldData['Conector y Cables']?['foto'] ?? '',
      'alimentacion': _fieldData['Alimentación']?['value'] ?? '',
      'alimentacion_comentario': _alimentacionComentarioController.text,
      'alimentacion_foto': _fieldData['Alimentación']?['foto'] ?? '',
      'pantalla': _fieldData['Pantalla']?['value'] ?? '',
      'pantalla_comentario': _pantallaComentarioController.text,
      'pantalla_foto': _fieldData['Pantalla']?['foto'] ?? '',
      'teclado': _fieldData['Teclado']?['value'] ?? '',
      'teclado_comentario': _tecladoComentarioController.text,
      'teclado_foto': _fieldData['Teclado']?['foto'] ?? '',
      'bracket_columna': _fieldData['Bracket y columna']?['value'] ?? '',
      'bracket_columna_comentario': _bracketComentarioController.text,
      'bracket_columna_foto': _fieldData['Bracket y columna']?['foto'] ?? '',
      'plato_carga': _fieldData['Plato de Carga']?['value'] ?? '',
      'plato_carga_comentario': _platoCargaComentarioController.text,
      'plato_carga_foto': _fieldData['Plato de Carga']?['foto'] ?? '',
      'estructura': _fieldData['Estructura']?['value'] ?? '',
      'estructura_comentario': _estructuraComentarioController.text,
      'estructura_foto': _fieldData['Estructura']?['foto'] ?? '',
      'topes_carga': _fieldData['Topes de Carga']?['value'] ?? '',
      'topes_carga_comentario': _topesCargaComentarioController.text,
      'topes_carga_foto': _fieldData['Topes de Carga']?['foto'] ?? '',
      'patas': _fieldData['Patas']?['value'] ?? '',
      'patas_comentario': _patasComentarioController.text,
      'patas_foto': _fieldData['Patas']?['foto'] ?? '',
      'limpieza': _fieldData['Limpieza']?['value'] ?? '',
      'limpieza_comentario': _limpiezaComentarioController.text,
      'limpieza_foto': _fieldData['Limpieza']?['foto'] ?? '',
      'bordes_puntas': _fieldData['Bordes y puntas']?['value'] ?? '',
      'bordes_puntas_comentario': _bordesPuntasComentarioController.text,
      'bordes_puntas_foto': _fieldData['Bordes y puntas']?['foto'] ?? '',
      'celulas': _fieldData['Célula(s)']?['value'] ?? '',
      'celulas_comentario': _celulasComentarioController.text,
      'celulas_foto': _fieldData['Célula(s)']?['foto'] ?? '',
      'cables': _fieldData['Cable(s)']?['value'] ?? '',
      'cables_comentario': _cablesComentarioController.text,
      'cables_foto': _fieldData['Cable(s)']?['foto'] ?? '',
      'cubierta_silicona': _fieldData['Cubierta de Silicona']?['value'] ?? '',
      'cubierta_silicona_comentario':
          _cubiertaSiliconaComentarioController.text,
      'cubierta_silicona_foto':
          _fieldData['Cubierta de Silicona']?['foto'] ?? '',
      'entorno': _fieldData['Entorno']?['value'] ?? '',
      'entorno_comentario': _entornoComentarioController.text,
      'entorno_foto': _fieldData['Entorno']?['foto'] ?? '',
      'nivelacion': _fieldData['Nivelación']?['value'] ?? '',
      'nivelacion_comentario': _nivelacionComentarioController.text,
      'nivelacion_foto': _fieldData['Nivelación']?['foto'] ?? '',
      'movilizacion': _fieldData['Movilización']?['value'] ?? '',
      'movilizacion_comentario': _movilizacionComentarioController.text,
      'movilizacion_foto': _fieldData['Movilización']?['foto'] ?? '',
      'flujo_pesas': _fieldData['Flujo de Pesas']?['value'] ?? '',
      'flujo_pesas_comentario': _flujoPesasComentarioController.text,
      'flujo_pesas_foto': _fieldData['Flujo de Pesas']?['foto'] ?? '',
    };

    data.addAll(
        conditions.map((key, value) => MapEntry(key, value.toString())));

    final tests = {
      'retorno_cero': _retornoCeroDropdownController.value,
      'carga_retorno_cero': _retornoCeroValorController.text,
    };

    data.addAll(tests);

    // 4. Excentricidad
    if (_showPlatformFields) {
      final eccentricity = {
        'tipo_plataforma': _selectedPlatform ?? '',
        'puntos_ind': _selectedOption ?? '',
        'carga': _cargaExcController.text,
      };

      // Agregar posiciones de excentricidad
      for (int i = 0; i < _positionControllers.length; i++) {
        final position = i + 1;
        eccentricity.addAll({
          'posicion$position': _positionControllers[i].text,
          'indicacion$position': _indicationControllers[i].text,
          'retorno$position': _returnControllers[i].text,
        });
      }

      data.addAll(eccentricity);
    }

    // 5. Repetibilidad
    if (_showRepetibilidadFields) {
      final repeatability = {
        'repetibilidad1': _repetibilidadController1.text,
      };

      for (int i = 0; i < _selectedRowCount; i++) {
        final testNum = i + 1;
        repeatability.addAll({
          'indicacion1_$testNum': _indicacionControllers1[i].text,
          'retorno1_$testNum': _retornoControllers1[i].text,
        });
      }

      if (_selectedRepetibilityCount >= 2) {
        repeatability['repetibilidad2'] = _repetibilidadController2.text;
        for (int i = 0; i < _selectedRowCount; i++) {
          final testNum = i + 1;
          repeatability.addAll({
            'indicacion2_$testNum': _indicacionControllers2[i].text,
            'retorno2_$testNum': _retornoControllers2[i].text,
          });
        }
      }

      if (_selectedRepetibilityCount >= 3) {
        repeatability['repetibilidad3'] = _repetibilidadController3.text;
        for (int i = 0; i < _selectedRowCount; i++) {
          final testNum = i + 1;
          repeatability.addAll({
            'indicacion3_$testNum': _indicacionControllers3[i].text,
            'retorno3_$testNum': _retornoControllers3[i].text,
          });
        }
      }

      data.addAll(repeatability);
    }

    // 6. Linealidad
    if (_showLinealidadFields) {
      for (int i = 0; i < _rows.length; i++) {
        final pointNum = i + 1;
        data.addAll({
          'lin$pointNum': _rows[i]['lt']?.text ?? '',
          'ind$pointNum': _rows[i]['indicacion']?.text ?? '',
          'retorno_lin$pointNum': _rows[i]['retorno']?.text ?? '0',
        });
      }
    }

    return data;
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

  void _setupAllAutoSaveListeners() {
    // Listeners para controladores de texto
    _setupTextControllerListeners();

    // Listeners para ValueNotifiers
    _retornoCeroDropdownController.addListener(_autoSaveData);
    _isDataSaved.addListener(_autoSaveData);
  }

  @override
  void dispose() {
    _removeAllAutoSaveListeners(); // Agrega esta línea
    _debounceTimer?.cancel(); // Agrega esta línea

    for (var row in _rows) {
      row['lt']?.dispose();
      row['indicacion']?.dispose();
      row['retorno']?.dispose();
    }

    _isDataSaved.dispose(); // Añade esta línea

    _otrosComentarioController.dispose();
    _carcasaComentarioController.dispose();
    _limpiezaFosaComentarioController.dispose();
    _estadoDrenajeComentarioController.dispose();
    _nivelacionComentarioController.dispose();
    _movilizacionComentarioController.dispose();
    _conectorComentarioController.dispose();
    _alimentacionComentarioController.dispose();
    _pantallaComentarioController.dispose();
    _tecladoComentarioController.dispose();
    _bracketComentarioController.dispose();
    _platoCargaComentarioController.dispose();
    _estructuraComentarioController.dispose();
    _topesCargaComentarioController.dispose();
    _patasComentarioController.dispose();
    _limpiezaComentarioController.dispose();
    _bordesPuntasComentarioController.dispose();
    _entornoComentarioController.dispose();
    _flujoPesadasComentarioController.dispose();
    _cargaController.dispose();
    _comentarioController.dispose();
    _pmax1Controller.dispose();
    _oneThirdPmax1Controller.dispose();
    _notaController.dispose();
    for (var controller in _positionControllers) {
      controller.dispose();
    }
    for (var controller in _indicationControllers) {
      controller.dispose();
    }
    for (var controller in _returnControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _horaController.text = horaFormateada;
  }

  Future<void> _showRecoveryDialog(BuildContext context) async {
    try {
      // 1. Listar todas las bases de datos en el directorio
      final directory = Directory(widget.dbPath);
      final List<FileSystemEntity> files = await directory.list().toList();

      // Filtrar solo archivos .db
      final List<FileSystemEntity> dbFiles =
          files.where((file) => file.path.endsWith('.db')).toList();

      if (dbFiles.isEmpty) {
        _showSnackBar(
            context, 'No se encontraron bases de datos para recuperar');
        return;
      }

      // 2. Mostrar diálogo con las bases de datos disponibles
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bases de Datos Disponibles'),
            content: SingleChildScrollView(
              child: Column(
                children: dbFiles.map((dbFile) {
                  final dbName = basename(dbFile.path);
                  return ListTile(
                    title: Text(dbName),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _loadSelectedDatabase(dbFile.path, context);
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Error al listar bases de datos: $e');
      debugPrint('Error al listar bases de datos: $e');
    }
  }

  Future<void> _loadSelectedDatabase(
      String dbPath, BuildContext context) async {
    try {
      final db = await openDatabase(dbPath);

      // Verificar si existe la tabla relevamiento_de_datos
      final tableExists = await _doesTableExist(db, 'relevamiento_de_datos');
      if (!tableExists) {
        await db.close();
        _showSnackBar(
            context, 'La base de datos no contiene datos de relevamiento');
        return;
      }

      // Obtener los datos guardados
      final savedData = await db.query('relevamiento_de_datos');
      await db.close();

      if (savedData.isEmpty) {
        _showSnackBar(context, 'No hay datos guardados en esta base de datos');
        return;
      }

      // Mostrar diálogo con los registros disponibles
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registros Disponibles'),
            content: SingleChildScrollView(
              child: Column(
                children: savedData.map((data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['hora_inicio'] != null)
                        Text('Hora inicio: ${data['hora_inicio']}'),
                      if (data['hora_fin'] != null)
                        Text('Hora fin: ${data['hora_fin']}'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _loadSavedData(context, data);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Recuperar este registro'),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Error al cargar la base de datos: $e');
      debugPrint('Error al cargar la base de datos: $e');
    }
  }

  void _loadSavedData(BuildContext context, Map<String, dynamic> data) {
    setState(() {
      // 1. Cargar condiciones generales del instrumento (Terminal)
      if (data['carcasa'] != null) {
        _fieldData['Carcasa'] = {'value': data['carcasa']};
        _carcasaComentarioController.text =
            data['carcasa_comentario'] ?? 'Sin Comentario';
        if (data['carcasa_foto'] != null && data['carcasa_foto'].isNotEmpty) {
          _fieldData['Carcasa']!['foto'] = data['carcasa_foto'];
        }
      }

      if (data['conector_cables'] != null) {
        _fieldData['Conector y Cables'] = {'value': data['conector_cables']};
        _conectorComentarioController.text =
            data['conector_cables_comentario'] ?? 'Sin Comentario';
        if (data['conector_cables_foto'] != null &&
            data['conector_cables_foto'].isNotEmpty) {
          _fieldData['Conector y Cables']!['foto'] =
              data['conector_cables_foto'];
        }
      }

      if (data['alimentacion'] != null) {
        _fieldData['Alimentación'] = {'value': data['alimentacion']};
        _alimentacionComentarioController.text =
            data['alimentacion_comentario'] ?? 'Sin Comentario';
        if (data['alimentacion_foto'] != null &&
            data['alimentacion_foto'].isNotEmpty) {
          _fieldData['Alimentación']!['foto'] = data['alimentacion_foto'];
        }
      }

      if (data['pantalla'] != null) {
        _fieldData['Pantalla'] = {'value': data['pantalla']};
        _pantallaComentarioController.text =
            data['pantalla_comentario'] ?? 'Sin Comentario';
        if (data['pantalla_foto'] != null && data['pantalla_foto'].isNotEmpty) {
          _fieldData['Pantalla']!['foto'] = data['pantalla_foto'];
        }
      }

      if (data['teclado'] != null) {
        _fieldData['Teclado'] = {'value': data['teclado']};
        _tecladoComentarioController.text =
            data['teclado_comentario'] ?? 'Sin Comentario';
        if (data['teclado_foto'] != null && data['teclado_foto'].isNotEmpty) {
          _fieldData['Teclado']!['foto'] = data['teclado_foto'];
        }
      }

      if (data['bracket_columna'] != null) {
        _fieldData['Bracket y columna'] = {'value': data['bracket_columna']};
        _bracketComentarioController.text =
            data['bracket_columna_comentario'] ?? 'Sin Comentario';
        if (data['bracket_columna_foto'] != null &&
            data['bracket_columna_foto'].isNotEmpty) {
          _fieldData['Bracket y columna']!['foto'] =
              data['bracket_columna_foto'];
        }
      }

      // 2. Cargar condiciones de la plataforma
      if (data['plato_carga'] != null) {
        _fieldData['Plato de Carga'] = {'value': data['plato_carga']};
        _platoCargaComentarioController.text =
            data['plato_carga_comentario'] ?? 'Sin Comentario';
        if (data['plato_carga_foto'] != null &&
            data['plato_carga_foto'].isNotEmpty) {
          _fieldData['Plato de Carga']!['foto'] = data['plato_carga_foto'];
        }
      }

      if (data['estructura'] != null) {
        _fieldData['Estructura'] = {'value': data['estructura']};
        _estructuraComentarioController.text =
            data['estructura_comentario'] ?? 'Sin Comentario';
        if (data['estructura_foto'] != null &&
            data['estructura_foto'].isNotEmpty) {
          _fieldData['Estructura']!['foto'] = data['estructura_foto'];
        }
      }

      if (data['topes_carga'] != null) {
        _fieldData['Topes de Carga'] = {'value': data['topes_carga']};
        _topesCargaComentarioController.text =
            data['topes_carga_comentario'] ?? 'Sin Comentario';
        if (data['topes_carga_foto'] != null &&
            data['topes_carga_foto'].isNotEmpty) {
          _fieldData['Topes de Carga']!['foto'] = data['topes_carga_foto'];
        }
      }

      if (data['patas'] != null) {
        _fieldData['Patas'] = {'value': data['patas']};
        _patasComentarioController.text =
            data['patas_comentario'] ?? 'Sin Comentario';
        if (data['patas_foto'] != null && data['patas_foto'].isNotEmpty) {
          _fieldData['Patas']!['foto'] = data['patas_foto'];
        }
      }

      if (data['limpieza'] != null) {
        _fieldData['Limpieza'] = {'value': data['limpieza']};
        _limpiezaComentarioController.text =
            data['limpieza_comentario'] ?? 'Sin Comentario';
        if (data['limpieza_foto'] != null && data['limpieza_foto'].isNotEmpty) {
          _fieldData['Limpieza']!['foto'] = data['limpieza_foto'];
        }
      }

      if (data['bordes_puntas'] != null) {
        _fieldData['Bordes y puntas'] = {'value': data['bordes_puntas']};
        _bordesPuntasComentarioController.text =
            data['bordes_puntas_comentario'] ?? 'Sin Comentario';
        if (data['bordes_puntas_foto'] != null &&
            data['bordes_puntas_foto'].isNotEmpty) {
          _fieldData['Bordes y puntas']!['foto'] = data['bordes_puntas_foto'];
        }
      }

      // 3. Cargar condiciones de celdas de carga
      if (data['celulas'] != null) {
        _fieldData['Célula(s)'] = {'value': data['celulas']};
        _celulasComentarioController.text =
            data['celulas_comentario'] ?? 'Sin Comentario';
        if (data['celulas_foto'] != null && data['celulas_foto'].isNotEmpty) {
          _fieldData['Célula(s)']!['foto'] = data['celulas_foto'];
        }
      }

      if (data['cables'] != null) {
        _fieldData['Cable(s)'] = {'value': data['cables']};
        _cablesComentarioController.text =
            data['cables_comentario'] ?? 'Sin Comentario';
        if (data['cables_foto'] != null && data['cables_foto'].isNotEmpty) {
          _fieldData['Cable(s)']!['foto'] = data['cables_foto'];
        }
      }

      if (data['cubierta_silicona'] != null) {
        _fieldData['Cubierta de Silicona'] = {
          'value': data['cubierta_silicona']
        };
        _cubiertaSiliconaComentarioController.text =
            data['cubierta_silicona_comentario'] ?? 'Sin Comentario';
        if (data['cubierta_silicona_foto'] != null &&
            data['cubierta_silicona_foto'].isNotEmpty) {
          _fieldData['Cubierta de Silicona']!['foto'] =
              data['cubierta_silicona_foto'];
        }
      }

      // 4. Cargar condiciones del entorno
      if (data['entorno'] != null) {
        _fieldData['Entorno'] = {'value': data['entorno']};
        _entornoComentarioController.text =
            data['entorno_comentario'] ?? 'Sin Comentario';
        if (data['entorno_foto'] != null && data['entorno_foto'].isNotEmpty) {
          _fieldData['Entorno']!['foto'] = data['entorno_foto'];
        }
      }

      if (data['nivelacion'] != null) {
        _fieldData['Nivelación'] = {'value': data['nivelacion']};
        _nivelacionComentarioController.text =
            data['nivelacion_comentario'] ?? 'Sin Comentario';
        if (data['nivelacion_foto'] != null &&
            data['nivelacion_foto'].isNotEmpty) {
          _fieldData['Nivelación']!['foto'] = data['nivelacion_foto'];
        }
      }

      if (data['movilizacion'] != null) {
        _fieldData['Movilización'] = {'value': data['movilizacion']};
        _movilizacionComentarioController.text =
            data['movilizacion_comentario'] ?? 'Sin Comentario';
        if (data['movilizacion_foto'] != null &&
            data['movilizacion_foto'].isNotEmpty) {
          _fieldData['Movilización']!['foto'] = data['movilizacion_foto'];
        }
      }

      if (data['flujo_pesas'] != null) {
        _fieldData['Flujo de Pesas'] = {'value': data['flujo_pesas']};
        _flujoPesasComentarioController.text =
            data['flujo_pesas_comentario'] ?? 'Sin Comentario';
        if (data['flujo_pesas_foto'] != null &&
            data['flujo_pesas_foto'].isNotEmpty) {
          _fieldData['Flujo de Pesas']!['foto'] = data['flujo_pesas_foto'];
        }
      }

      // 5. Cargar pruebas metrológicas
      if (data['retorno_cero'] != null) {
        _retornoCeroDropdownController.value = data['retorno_cero'];
        _retornoCeroValorController.text = data['carga_retorno_cero'] ?? '';
      }

      // 6. Cargar excentricidad
      if (data['tipo_plataforma'] != null) {
        _selectedPlatform = data['tipo_plataforma'];
        _selectedOption = data['puntos_ind'];
        _cargaExcController.text = data['carga'] ?? '';
        _showPlatformFields = true;

        // Cargar posiciones de excentricidad
        for (int i = 1; i <= 6; i++) {
          final posKey = 'posicion$i';
          final indKey = 'indicacion$i';
          final retKey = 'retorno$i';

          if (data[posKey] != null && i - 1 < _positionControllers.length) {
            _positionControllers[i - 1].text = data[posKey];
            _indicationControllers[i - 1].text = data[indKey] ?? '';
            _returnControllers[i - 1].text = data[retKey] ?? '0';
          }
        }
      }

      // 7. Cargar repetibilidad
      if (data['repetibilidad1'] != null) {
        _repetibilidadController1.text = data['repetibilidad1'];
        for (int i = 0; i < _selectedRowCount; i++) {
          final testNum = i + 1;
          _indicacionControllers1[i].text = data['indicacion1_$testNum'] ?? '';
          _retornoControllers1[i].text = data['retorno1_$testNum'] ?? '0';
        }
        _showRepetibilidadFields = true;

        if (data['repetibilidad2'] != null) {
          _repetibilidadController2.text = data['repetibilidad2'];
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            _indicacionControllers2[i].text =
                data['indicacion2_$testNum'] ?? '';
            _retornoControllers2[i].text = data['retorno2_$testNum'] ?? '0';
          }
        }

        if (data['repetibilidad3'] != null) {
          _repetibilidadController3.text = data['repetibilidad3'];
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            _indicacionControllers3[i].text =
                data['indicacion3_$testNum'] ?? '';
            _retornoControllers3[i].text = data['retorno3_$testNum'] ?? '0';
          }
        }
      }

      // 8. Cargar linealidad
      for (int i = 1; i <= 10; i++) {
        final linKey = 'lin$i';
        final indKey = 'ind$i';
        final retKey = 'retorno_lin$i';

        if (data[linKey] != null && i - 1 < _rows.length) {
          _rows[i - 1]['lt']?.text = data[linKey];
          _rows[i - 1]['indicacion']?.text = data[indKey] ?? '';
          _rows[i - 1]['retorno']?.text = data[retKey] ?? '0';
        }
      }
      if (data['lin1'] != null) {
        _showLinealidadFields = true;
      }

      // 9. Cargar horas
      if (data['hora_inicio'] != null) {
        _horaController.text = data['hora_inicio'];
      }
      if (data['hora_fin'] != null) {
        _horaFinController.text = data['hora_fin'];
      }

      // Marcar como datos guardados
      _isDataSaved.value = true;
    });

    _showSnackBar(context, 'Datos recuperados exitosamente');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () async {
        // Forzar guardado antes de salir
        await _autoSaveData(force: true);
        return _onWillPop(context); // Tu función existente
      },
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
              const SizedBox(height: 5.0),
              Text(
                'CLIENTE: ${widget.selectedPlantaNombre}\nCÓDIGO: ${widget.codMetrica}', // Aquí se añade el código métrico
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
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
              left: 16.0, // Tu padding horizontal original
              right: 16.0, // Tu padding horizontal original
              bottom: 16.0, // Tu padding inferior original
            ),
            child: Column(
              children: [
                const Text(
                  'RELEVAMIENTO DE DATOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0), // Espacio entre el texto y el campo
                TextFormField(
                  controller: _horaController, // Necesitarás un controller
                  decoration: _buildInputDecoration(
                    'Hora de Inicio de Servicio',
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                  readOnly: true, // Para que no se pueda editar manualmente
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
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TERMINAL:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black54, // Color personalizado
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Carcasa', _carcasaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Conector y Cables',
                    _conectorComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Alimentación', _alimentacionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Pantalla', _pantallaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Teclado', _tecladoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Bracket y columna', _bracketComentarioController),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PLATAFORMA:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black54, // Color personalizado
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Plato de Carga', _platoCargaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Estructura', _estructuraComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Topes de Carga', _topesCargaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Patas', _patasComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Limpieza', _limpiezaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Bordes y puntas',
                    _bordesPuntasComentarioController),
                const SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CELDAS DE CARGA:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black54, // Color personalizado
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Célula(s)', _celulasComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Cable(s)', _cablesComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Cubierta de Silicona',
                    _cubiertaSiliconaComentarioController),
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
                const SizedBox(height: 20.0),
                const Text(
                  'PRUEBAS METROLÓGICAS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDECD00), // Color personalizado
                  ),
                  textAlign: TextAlign.center,
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
                          'Para aplicar alguna de las pruebas metrológicas debe activar el switch de la prueba que desea aplicar, si el switch está desactivado no se guardará la información de la prueba y los datos en el CSV estaran en blanco.',
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
                SwitchListTile(
                  title: const Text('PRUEBAS DE EXCENTRICIDAD',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showPlatformFields,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSaveData(); // <-- Agrega esta línea
                      _showPlatformFields = value;
                      if (!value) {
                        _selectedPlatform = null;
                        _selectedOption = null;
                        _selectedImagePath = null;
                      }
                    });
                  },
                ),
                _buildPlatformFields(),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE REPETIBILIDAD',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showRepetibilidadFields,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSaveData(); // <-- Agrega esta línea
                      _showRepetibilidadFields = value;
                    });
                  },
                ),
                _buildRepetibilidadFields(),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE LINEALIDAD',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showLinealidadFields,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSaveData(); // <-- Agrega esta línea
                      _showLinealidadFields = value;
                    });
                  },
                ),
                _showLinealidadFields
                    ? _buildLinealidadFields(context)
                    : const SizedBox(),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller:
                      _comentarioGeneralController, // Define un controlador para el comentario general
                  decoration: InputDecoration(
                    labelText: 'Comentario General',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  maxLines: 3, // Permite varias líneas para el comentario
                ),
                const SizedBox(height: 20.0), // Espaciado entre los campos
                DropdownButtonFormField<String>(
                  value:
                      _selectedRecommendation, // Variable para almacenar la selección
                  decoration: InputDecoration(
                    labelText: 'Recomendación',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
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
                      _selectedRecommendation =
                          newValue; // Actualiza la selección
                    });
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller:
                      _horaFinController, // Usa el controlador ya definido
                  decoration: _buildInputDecoration(
                    'Hora Final del Servicio',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () {
                        final ahora = DateTime.now();
                        final horaFormateada =
                            DateFormat('HH:mm:ss').format(ahora);
                        _horaFinController.text =
                            horaFormateada; // Actualiza el controlador con la hora actual
                      },
                    ),
                  ),
                  readOnly: true, // Evita que el usuario edite manualmente
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
                          'Para registrar la hora final del servicio debe dar click al icono del reloj, este obtendra la hora del sistema, una vez registrado este dato no se podra modificar.',
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
                                : const Text(
                                    'GUARDAR DATOS',
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          _isDataSaved, // Cambia esto para escuchar _isDataSaved
                      builder: (context, isSaved, child) {
                        return Expanded(
                          child: ElevatedButton(
                            onPressed: isSaved
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FinServicioScreen(
                                          dbName: widget.dbName,
                                          dbPath: widget.dbPath,
                                          otValue: widget.otValue,
                                          selectedCliente:
                                              widget.selectedCliente,
                                          selectedPlantaNombre:
                                              widget.selectedPlantaNombre,
                                          codMetrica: widget.codMetrica,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isSaved ? const Color(0xFF167D1D) : Colors.grey,
                              elevation: 4.0,
                            ),
                            child: const Text(
                              'SIGUIENTE',
                            ),
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
        floatingActionButton: SpeedDial(
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
                              _buildDetailContainer(
                                  'Código Métrica',
                                  balanza.cod_metrica,
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'Unidades',
                                  balanza.unidad.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'pmax1',
                                  balanza.cap_max1,
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'd1',
                                  balanza.d1.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'e1',
                                  balanza.e1.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'dec1',
                                  balanza.dec1.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'pmax2',
                                  balanza.cap_max2,
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'd2',
                                  balanza.d2.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'e2',
                                  balanza.e2.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'dec2',
                                  balanza.dec2.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'pmax3',
                                  balanza.cap_max3,
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'd3',
                                  balanza.d3.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'e3',
                                  balanza.e3.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black,
                                  Colors.grey),
                              _buildDetailContainer(
                                  'dec3',
                                  balanza.dec3.toString(),
                                  Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
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
          ],
        ),
      ),
    );
  }
}
