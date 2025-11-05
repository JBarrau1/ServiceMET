import 'dart:io';
import 'dart:ui';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/fin_servicio_stil.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';

class StilMntPrvAvanzadoStacScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName; // ✅ AGREGAR
  final String clienteId; // ✅ AGREGAR
  final String plantaCodigo; // ✅ AGREGAR

  const StilMntPrvAvanzadoStacScreen({
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
  _StilMntPrvAvanzadoStacScreenState createState() =>
      _StilMntPrvAvanzadoStacScreenState();
}

class _StilMntPrvAvanzadoStacScreenState
    extends State<StilMntPrvAvanzadoStacScreen> {
  //funcionalidades extras
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, List<File>> _fieldPhotos = {};
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final _formKey = GlobalKey<FormState>();
  DateTime? _lastPressedTime;
  final TextEditingController _horaController = TextEditingController();
  //controladores para los comentarios
  final TextEditingController _vibracionComentarioController = TextEditingController();
  final TextEditingController _polvoComentarioController = TextEditingController();
  final TextEditingController _teperaturaComentarioController = TextEditingController();
  final TextEditingController _humedadComentarioController = TextEditingController();
  final TextEditingController _mesadaComentarioController = TextEditingController();
  final TextEditingController _iluminacionComentarioController = TextEditingController();
  final TextEditingController _limpiezaFosaComentarioController = TextEditingController();
  final TextEditingController _estadoDrenajeComentarioController = TextEditingController();
  final TextEditingController _carcasaComentarioController = TextEditingController();
  final TextEditingController _tecladoFisicoComentarioController = TextEditingController();
  final TextEditingController _displayFisicoComentarioController = TextEditingController();
  final TextEditingController _fuentePoderComentarioController = TextEditingController();
  final TextEditingController _bateriaOperacionalComentarioController = TextEditingController();
  final TextEditingController _bracketComentarioController = TextEditingController();
  final TextEditingController _tecladoOperativoComentarioController = TextEditingController();
  final TextEditingController _displayOperativoComentarioController = TextEditingController();
  final TextEditingController _contectorCeldaComentarioController = TextEditingController();
  final TextEditingController _bateriaMemoriaComentarioController = TextEditingController();
  final TextEditingController _limpiezaGeneralComentarioController = TextEditingController();
  final TextEditingController _golpesTerminalComentarioController = TextEditingController();
  final TextEditingController _nivelacionComentarioController = TextEditingController();
  final TextEditingController _limpiezaReceptorComentarioController = TextEditingController();
  final TextEditingController _golpesReceptorComentarioController = TextEditingController();
  final TextEditingController _encendidoComentarioController = TextEditingController();
  final TextEditingController _limitadorMovimientoComentarioController = TextEditingController();
  final TextEditingController _suspensionComentarioController = TextEditingController();
  final TextEditingController _limitadorCargaComentarioController = TextEditingController();
  final TextEditingController _celdaCargaComentarioController = TextEditingController();
  final TextEditingController _tapaCajaComentarioController = TextEditingController();
  final TextEditingController _humedadInternaComentarioController = TextEditingController();
  final TextEditingController _estadoPrensacablesComentarioController = TextEditingController();
  final TextEditingController _estadoBorneasComentarioController = TextEditingController();
  final TextEditingController _pintadoComentarioController = TextEditingController();
  final TextEditingController _limpiezaProfundaComentarioController = TextEditingController();

  //pruebas metrológicas iniciales
  //Controladores excentricidad
  final ValueNotifier<String> _retornoCeroInicialDropdownController = ValueNotifier<String>('1 Bueno'); // Controlador inicializado
  final TextEditingController _retornoCeroInicialValorController = TextEditingController();
  final TextEditingController _cargaExcInicialController = TextEditingController();
  final TextEditingController _cargaInicialController = TextEditingController();
  final TextEditingController _oneThirdPmax1InicialController = TextEditingController();
  double? _oneThirdpmax1Inicial;
  String _selectedUnitInicial = 'kg';
  bool _showPlatformFieldsInicial = false;
  String? _selectedPlatformInicial;
  String? _selectedOptionInicial;
  String? _selectedImagePathInicial;
  List<TextEditingController> _positionInicialControllers = [];
  List<TextEditingController> _indicationInicialControllers = [];
  List<TextEditingController> _returnInicialControllers =
      List.generate(10, (index) => TextEditingController(text: '0'));
  List<bool> _isDynamicallyAddedInicial = [];
  List<List<String>> _indicationDropdownItemsInicial = [];

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

  //controladores repetibilidad
  bool _showRepetibilidadFieldsInicial = false;
  int _selectedRepetibilityCountInicial = 1;
  int _selectedRowCountInicial = 3;
  final TextEditingController _repetibilidadInicialController1 =
      TextEditingController();
  final TextEditingController _repetibilidadInicialController2 =
      TextEditingController();
  final TextEditingController _repetibilidadInicialController3 =
      TextEditingController();
  final List<TextEditingController> _indicacionInicialControllers1 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoInicialControllers1 =
      List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> _indicacionInicialControllers2 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoInicialControllers2 =
      List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> _indicacionInicialControllers3 =
      List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> _retornoInicialControllers3 =
      List.generate(10, (index) => TextEditingController(text: '0'));
  //controladores linealidad
  bool _showLinealidadFieldsInicial = false;
  final TextEditingController _cargaLnInicialController =
      TextEditingController();
  final TextEditingController _cargaClienteInicialController =
      TextEditingController();
  final TextEditingController _sumatoriaInicialController =
      TextEditingController();
  final List<Map<String, TextEditingController>> _rowsInicial = [];

  //PRUEBAS METROLOGCIAS FINALES
  final ValueNotifier<String> _retornoCeroDropdownController =
      ValueNotifier<String>('1 Bueno'); // Controlador inicializado
  final TextEditingController _retornoCeroValorController =
      TextEditingController();
  String _selectedUnit = 'kg';
  //pruebas de excentricidad finales
  bool _showPlatformFields = false;
  String? _selectedPlatform;
  String? _selectedOption;
  String? _selectedImagePath;
  final TextEditingController _cargaExcController = TextEditingController();
  final List<TextEditingController> _indicationControllers = [];
  final List<List<String>> _indicationDropdownItems = [];
  final TextEditingController _cargaController = TextEditingController();
  final TextEditingController _oneThirdPmax1Controller =
      TextEditingController();
  double? _oneThirdpmax1;
  final List<TextEditingController> _positionControllers = [];
  final List<TextEditingController> _returnControllers =
      List.generate(10, (index) => TextEditingController(text: '0'));
  bool _showRepetibilidadFields = false;
  int _selectedRepetibilityCount = 1;
  int _selectedRowCount = 3;
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
  bool _showLinealidadFields = false;
  final TextEditingController _cargaLnController = TextEditingController();
  final TextEditingController _cargaClienteController = TextEditingController();
  final TextEditingController _sumatoriaController = TextEditingController();
  final List<Map<String, TextEditingController>> _rows = [];

  //OTROS CONTROLADORES DE CAMPOS ADICIONALES
  final TextEditingController _comentarioGeneralController =
      TextEditingController();
  String? _selectedRecommendation;
  String? _selectedFisico;
  String? _selectedOperacional;
  String? _selectedMetrologico;
  final TextEditingController _horaFinController = TextEditingController();
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _actualizarHora(); // Establece la hora actual

    // Inicializar campos de "ESTADO GENERAL DEL INSTRUMENTO" con "4 No aplica" en ambos campos
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
      'Estado de borneas',
      'Limpieza profunda',
      'Pintado'
    ];

    for (final campo in camposEstadoGeneral) {
      _fieldData[campo] = {
        'initial_value': '4 No aplica', // Estado inicial
        'solution_value': 'No aplica' // Estado final/solución
      };
    }

    // Inicializar controladores de comentarios con valor vacío ("")
    _vibracionComentarioController.text = "Sin comentario";
    _polvoComentarioController.text = "Sin comentario";
    _teperaturaComentarioController.text = "Sin comentario";
    _humedadComentarioController.text = "Sin comentario";
    _mesadaComentarioController.text = "Sin comentario";
    _iluminacionComentarioController.text = "Sin comentario";
    _limpiezaFosaComentarioController.text = "Sin comentario";
    _estadoDrenajeComentarioController.text = "Sin comentario";
    _carcasaComentarioController.text = "Sin comentario";
    _tecladoFisicoComentarioController.text = "Sin comentario";
    _displayFisicoComentarioController.text = "Sin comentario";
    _fuentePoderComentarioController.text = "Sin comentario";
    _bateriaOperacionalComentarioController.text = "Sin comentario";
    _bracketComentarioController.text = "Sin comentario";
    _tecladoOperativoComentarioController.text = "Sin comentario";
    _displayOperativoComentarioController.text = "Sin comentario";
    _contectorCeldaComentarioController.text = "Sin comentario";
    _bateriaMemoriaComentarioController.text = "Sin comentario";
    _limpiezaGeneralComentarioController.text = "Sin comentario";
    _golpesTerminalComentarioController.text = "Sin comentario";
    _nivelacionComentarioController.text = "Sin comentario";
    _limpiezaReceptorComentarioController.text = "Sin comentario";
    _golpesReceptorComentarioController.text = "Sin comentario";
    _encendidoComentarioController.text = "Sin comentario";
    _limitadorMovimientoComentarioController.text = "Sin comentario";
    _suspensionComentarioController.text = "Sin comentario";
    _limitadorCargaComentarioController.text = "Sin comentario";
    _celdaCargaComentarioController.text = "Sin comentario";
    _tapaCajaComentarioController.text = "Sin comentario";
    _humedadInternaComentarioController.text = "Sin comentario";
    _estadoPrensacablesComentarioController.text = "Sin comentario";
    _estadoBorneasComentarioController.text = "Sin comentario";
    _pintadoComentarioController.text = "Sin comentario";
    _limpiezaProfundaComentarioController.text = "Sin comentario";
  }

  void _initializeControllersInicial() {
    _positionInicialControllers = [];
    _indicationInicialControllers = [];
    _returnInicialControllers =
        List.generate(10, (index) => TextEditingController(text: '0'));
    _isDynamicallyAddedInicial = [];
    _indicationDropdownItemsInicial = [];
  }

  //widgets y otros
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
    // Opciones para el estado inicial
    final List<String> initialOptions =
        customOptions ?? ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'];

    // Opciones para el estado final (solución)
    final List<String> solutionOptions = [
      'Sí',
      'Se intentó',
      'No',
      'No aplica'
    ];

    // Validar y obtener valor actual para estado inicial
    String currentInitialValue =
        _fieldData[label]?['initial_value'] ?? initialOptions.first;
    if (!initialOptions.contains(currentInitialValue)) {
      currentInitialValue = initialOptions.first;
    }

    // Validar y obtener valor actual para estado final (solución)
    String currentSolutionValue =
        _fieldData[label]?['solution_value'] ?? solutionOptions.first;
    if (!solutionOptions.contains(currentSolutionValue)) {
      currentSolutionValue = solutionOptions.first;
    }

    return Column(
      children: [
        // Dropdown para estado inicial
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentInitialValue,
                decoration: _buildInputDecoration('Estado inicial $label'),
                items: initialOptions.map((String value) {
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
                      _fieldData[label]!['initial_value'] = newValue;
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

        // Dropdown para estado final (solución)
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentSolutionValue,
                decoration: _buildInputDecoration('¿Se solucionó el problema?'),
                items: solutionOptions.map((String value) {
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case 'Sí':
                      textColor = Colors.green;
                      icon = const Icon(Icons.check_circle_outline,
                          color: Colors.green);
                      break;
                    case 'Se intentó':
                      textColor = Colors.orange;
                      icon = const Icon(Icons.build_circle_outlined,
                          color: Colors.orange);
                      break;
                    case 'No':
                      textColor = Colors.red;
                      icon =
                          const Icon(Icons.cancel_rounded, color: Colors.red);
                      break;
                    case 'No aplica':
                      textColor = Colors.grey;
                      icon =
                          const Icon(Icons.block_outlined, color: Colors.grey);
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
                      _fieldData[label]!['solution_value'] = newValue;
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
            const Expanded(
                flex: 1, child: SizedBox()), // Espacio vacío para alinear
          ],
        ),

        const SizedBox(height: 12.0),

        // Campo de comentario
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

  void _updatePositions() {
    if (_selectedOptionInicial == null) return;

    int numberOfPositions = _getNumberOfPositions(_selectedOptionInicial!);
    _initializeControllersInicial();

    // Usar el controlador correcto para excentricidad (_cargaExcController)
    final cargaValue = _cargaExcInicialController.text.isNotEmpty
        ? _cargaExcInicialController.text
        : '0';

    for (int i = 0; i < numberOfPositions; i++) {
      _positionInicialControllers
          .add(TextEditingController(text: (i + 1).toString()));
      _indicationInicialControllers
          .add(TextEditingController(text: cargaValue));
      _returnInicialControllers.add(TextEditingController(text: '0'));
      _isDynamicallyAddedInicial.add(false);
      _indicationDropdownItemsInicial.add([]);

      // Actualizar dropdown items si hay un valor en carga
      final doubleValue = double.tryParse(cargaValue);
      if (doubleValue != null) {
        _updateIndicationInicialDropdownItems(i, doubleValue);
      }
    }

    setState(() {});
  }

  void _updateIndicationInicialDropdownItems(int index, double value) {
    setState(() {
      _indicationDropdownItemsInicial[index] = [
        ...List.generate(5, (i) => (value + (i + 1)).toStringAsFixed(0))
            .reversed,
        value.toStringAsFixed(0),
        ...List.generate(5, (i) => (value - (i + 1)).toStringAsFixed(0)),
      ];
    });
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

  Widget _buildPlatformFieldsInicial() {
    if (!_showPlatformFieldsInicial) return const SizedBox();

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
          value: _selectedPlatformInicial,
          decoration: _buildInputDecoration('Tipo de Plataforma'),
          items: _platformOptions.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPlatformInicial = newValue;
              _selectedOptionInicial = null;
              _selectedImagePathInicial = null;
              _updatePositions();
            });
          },
        ),
        const SizedBox(height: 20),
        if (_selectedPlatformInicial != null)
          DropdownButtonFormField<String>(
            value: _selectedOptionInicial,
            decoration: _buildInputDecoration('Puntos e Indicador'),
            items:
                _platformOptions[_selectedPlatformInicial]!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedOptionInicial = newValue;
                _selectedImagePathInicial = _optionImages[newValue!];
                _updatePositions();
              });
            },
          ),
        const SizedBox(height: 20),
        if (_selectedImagePathInicial != null)
          Image.asset(_selectedImagePathInicial!),
        const SizedBox(height: 20),
        TextFormField(
          controller: _cargaExcInicialController,
          decoration: _buildInputDecoration('Carga'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null) {
              // Actualizar solo los campos de indicación
              for (int i = 0; i < _indicationInicialControllers.length; i++) {
                _indicationInicialControllers[i].text = value;
                _updateIndicationInicialDropdownItems(i, doubleValue);
              }
              // No actualizar los campos de retorno (se mantienen en 0)
            }
          },
          style: TextStyle(
            color: (_cargaInicialController.text.isNotEmpty &&
                    double.tryParse(_cargaInicialController.text) != null &&
                    double.parse(_cargaInicialController.text) <
                        _oneThirdpmax1Inicial!)
                ? Colors.red
                : null,
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _positionInicialControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionInicialControllers[index],
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
                          controller: _indicationInicialControllers[index],
                          decoration: _buildInputDecoration(
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
                                      _indicationInicialControllers[index]
                                          .text = newValue;
                                    });
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final baseValue = double.tryParse(
                                            _indicationInicialControllers[index]
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
                          controller: _returnInicialControllers[index],
                          decoration: _buildInputDecoration('Retorno'),
                          keyboardType: TextInputType.number,
                          // Inicializar en 0 y permitir edición manual
                          onChanged: (value) {
                            if (value.isEmpty) {
                              _returnInicialControllers[index].text = '0';
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

  Future<bool> _doesTableExist(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // dart
  Future<double> _getD1FromDatabase() async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStil();
      Database? db;

      // Intentar obtener la BD desde la helper (compatible con distintas API)
      try {
        db = await (dbHelper as dynamic).database;
      } catch (_) {
        try {
          db = await (dbHelper as dynamic).getDatabase();
        } catch (__) {
          db = null;
        }
      }

      // Si no se pudo obtener la DB desde el helper, devolver valor por defecto
      if (db == null) {
        debugPrint('No se pudo obtener la instancia de Database desde DatabaseHelperSop');
        return 0.1;
      }

      // Verificar si la tabla existe
      final tableExists = await _doesTableExist(db, 'mnt_prv_avanzado_stil');
      if (!tableExists) return 0.1;

      final List<Map<String, dynamic>> result = await db.query(
        'mnt_prv_avanzado_stil',
        where: 'id = ?',
        whereArgs: [1],
        columns: ['d1'],
        limit: 1,
      );

      if (result.isNotEmpty && result.first['d1'] != null) {
        return double.tryParse(result.first['d1'].toString()) ?? 0.1;
      }

      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1;
    }
  }


  void _updateIndicacionValuesInicial(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionInicialControllers1) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValuesInicial2(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionInicialControllers2) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValuesInicial3(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in _indicacionInicialControllers3) {
        controller.text = value;
      }
    });
  }

  Widget _buildRepetibilidadFieldsInicial() {
    if (!_showRepetibilidadFieldsInicial) return const SizedBox();

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
          value: _selectedRepetibilityCountInicial,
          items: [1, 2, 3]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRepetibilityCountInicial = value ?? 1;
            });
          },
          decoration: _buildInputDecoration('Cantidad de Cargas'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: _selectedRowCountInicial,
          items: [3, 5, 10]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRowCountInicial = value ?? 3;
            });
          },
          decoration: _buildInputDecoration('Cantidad de Pruebas'),
        ),
        const SizedBox(height: 20),
        if (_selectedRepetibilityCountInicial >= 1) ...[
          const Text(
            'CARGA 1',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadInicialController1,
            decoration: _buildInputDecoration('Carga 1'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValuesInicial,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Por favor ingrese un valor' : null,
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCountInicial; i++)
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
                            controller: _indicacionInicialControllers1[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() =>
                                      _indicacionInicialControllers1[i].text =
                                          newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionInicialControllers1[i]
                                              .text) ??
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
                        controller: _retornoInicialControllers1[i],
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
        if (_selectedRepetibilityCountInicial >= 2) ...[
          const Text(
            'CARGA 2',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadInicialController2,
            decoration: _buildInputDecoration('Carga 2'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValuesInicial2,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Por favor ingrese un valor';
              if (value == _repetibilidadInicialController1.text) {
                return 'El valor debe ser diferente de Carga 1';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCountInicial; i++)
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
                            controller: _indicacionInicialControllers2[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() =>
                                      _indicacionInicialControllers2[i].text =
                                          newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionInicialControllers2[i]
                                              .text) ??
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
                        controller: _retornoInicialControllers2[i],
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
        if (_selectedRepetibilityCountInicial == 3) ...[
          const Text(
            'CARGA 3',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _repetibilidadInicialController3,
            decoration: _buildInputDecoration('Carga 3'),
            keyboardType: TextInputType.number,
            onChanged: _updateIndicacionValuesInicial3,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Por favor ingrese un valor';
              if (value == _repetibilidadInicialController1.text ||
                  value == _repetibilidadInicialController2.text) {
                return 'El valor debe ser diferente de Carga 1 y 2';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selectedRowCountInicial; i++)
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
                            controller: _indicacionInicialControllers3[i],
                            decoration:
                                _buildInputDecoration('Indicación ${i + 1}')
                                    .copyWith(
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (String newValue) {
                                  setState(() =>
                                      _indicacionInicialControllers3[i].text =
                                          newValue);
                                },
                                itemBuilder: (BuildContext context) {
                                  final baseValue = double.tryParse(
                                          _indicacionInicialControllers3[i]
                                              .text) ??
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
                        controller: _retornoInicialControllers3[i],
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

  Widget _buildLinealidadFieldsInicial(BuildContext context) {
    if (!_showLinealidadFieldsInicial) return const SizedBox();

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
                controller: _cargaLnInicialController,
                decoration: _buildInputDecoration('Última Carga de LT'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _cargaClienteInicialController,
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
                controller: _sumatoriaInicialController,
                decoration: _buildInputDecoration('Incremento'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _guardarCargaInicial(
                    context); // Pasar el contexto explícitamente
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
          itemCount: _rowsInicial.length,
          itemBuilder: (context, index) {
            return _buildFilaLinealidadInicial(index);
          },
        ),
        const SizedBox(height: 10),

        // Botones de control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _agregarFilaInicial,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _removerFilaInicial(context, _rowsInicial.length - 1),
              icon: const Icon(Icons.remove, color: Colors.white),
              label: const Text('Eliminar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  void _actualizarUltimaCargaInicial() {
    if (_rowsInicial.isEmpty) {
      _cargaLnInicialController.text = '0';
      return;
    }
    // Obtener el último valor de LT (ignorando vacíos)
    for (int i = _rowsInicial.length - 1; i >= 0; i--) {
      final ltValue = _rowsInicial[i]['lt']?.text.trim();
      if (ltValue != null && ltValue.isNotEmpty) {
        _cargaLnInicialController.text = ltValue;
        return;
      }
    }

    _cargaLnInicialController.text = '0';
  }

  void _agregarFilaInicial() {
    setState(() {
      _rowsInicial.add({
        'lt': TextEditingController(), // Se inicializa sin texto
        'indicacion': TextEditingController(), // Se inicializa sin texto
        'retorno': TextEditingController(text: '0'),
      });

      // Escuchar cambios en los campos LT
      _rowsInicial.last['lt']?.addListener(_actualizarUltimaCargaInicial);
    });
  }

  void _removerFilaInicial(BuildContext context, int index) {
    if (_rowsInicial.length <= 2) {
      _showSnackBar(context, 'Debe mantener al menos 2 filas');
      return;
    }
    setState(() {
      // Limpiar controladores antes de remover
      _rowsInicial[index]['lt']?.dispose();
      _rowsInicial[index]['indicacion']?.dispose();
      _rowsInicial[index]['retorno']?.dispose();
      _rowsInicial.removeAt(index);
      _actualizarUltimaCargaInicial();
    });
  }

  Widget _buildFilaLinealidadInicial(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _rowsInicial[index]['lt'],
              decoration: _buildInputDecoration('LT ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                // Actualizar indicación automáticamente
                if (value.isNotEmpty) {
                  _rowsInicial[index]['indicacion']?.text = value;
                }
                _actualizarUltimaCargaInicial();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _rowsInicial[index]['indicacion'],
              decoration: _buildInputDecoration('Indicación ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  void _guardarCargaInicial(BuildContext context) {
    if (_sumatoriaInicialController.text.isEmpty) {
      _showSnackBar(context, 'Calcule la sumatoria primero');
      return;
    }

    setState(() {
      // Primero buscar filas vacías
      for (var row in _rowsInicial) {
        if (row['lt']?.text.isEmpty ?? true) {
          // Llenar la primera fila vacía que encuentre
          row['lt']?.text = _sumatoriaInicialController.text;
          row['indicacion']?.text = _sumatoriaInicialController.text;

          // Limpiar para nueva entrada
          _cargaClienteInicialController.clear();
          _sumatoriaInicialController.clear();
          _actualizarUltimaCargaInicial();
          return;
        }
      }

      // Si no hay filas vacías, agregar nueva fila
      _agregarFilaInicial();
      _rowsInicial.last['lt']?.text = _sumatoriaInicialController.text;
      _rowsInicial.last['indicacion']?.text = _sumatoriaInicialController.text;

      // Limpiar para nueva entrada
      _cargaClienteInicialController.clear();
      _sumatoriaInicialController.clear();
      _actualizarUltimaCargaInicial();
    });
  }

  void _calcularSumatoria() {
    final cargaLn = double.tryParse(_cargaLnInicialController.text) ?? 0;
    final cargaCliente =
        double.tryParse(_cargaClienteInicialController.text) ?? 0;
    _sumatoriaInicialController.text =
        (cargaLn + cargaCliente).toStringAsFixed(2);
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
        const SizedBox(height: 20),
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
                          decoration: _buildInputDecoration(
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
          '${widget.secaValue}_${widget.codMetrica}_mnt_prv_avanzado_stil.zip';

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
    await _savemnt_prv_regular_stilData(context);
  }

  Future<void> _savemnt_prv_regular_stilData(BuildContext context) async {
    if (_comentarioGeneralController.text.isEmpty) {
      _showSnackBar(
        context,
        'Por favor complete el campo "Comentario General"',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // âœ… USAR DatabaseHelperSop
      final dbHelper = DatabaseHelperMntPrvAvanzadoStil();

      // Convertir listas de fotos a strings separados por comas
      String getFotosString(String label) {
        return _fieldPhotos[label]?.map((f) => basename(f.path)).join(',') ?? '';
      }

      // Preparar datos para insertar/actualizar
      final Map<String, dynamic> dbData = {
        // âœ… CAMPOS CLAVE PARA IDENTIFICAR LA SESIÓN
        'session_id': widget.sessionId,
        'cod_metrica': widget.codMetrica,

        // Campos existentes
        'tipo_servicio': 'mnt prv avanzado stil',
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,
        'comentario_general': _comentarioGeneralController.text,
        'recomendacion': _selectedRecommendation ?? '',
        'estado_fisico': _selectedFisico ?? '',
        'estado_operacional': _selectedOperacional ?? '',
        'estado_metrologico': _selectedMetrologico ?? '',

        // Entorno de instalación
        'vibracion_estado': _fieldData['Vibración']?['initial_value'] ?? '',
        'vibracion_solucion': _fieldData['Vibración']?['solution_value'] ?? '',
        'vibracion_comentario': _vibracionComentarioController.text,
        'vibracion_foto': getFotosString('Vibración'),

        'polvo_estado': _fieldData['Polvo']?['initial_value'] ?? '',
        'polvo_solucion': _fieldData['Polvo']?['solution_value'] ?? '',
        'polvo_comentario': _polvoComentarioController.text,
        'polvo_foto': getFotosString('Polvo'),

        'temperatura_estado': _fieldData['Temperatura']?['initial_value'] ?? '',
        'temperatura_solucion': _fieldData['Temperatura']?['solution_value'] ?? '',
        'temperatura_comentario': _teperaturaComentarioController.text,
        'temperatura_foto': getFotosString('Temperatura'),

        'humedad_estado': _fieldData['Humedad']?['initial_value'] ?? '',
        'humedad_solucion': _fieldData['Humedad']?['solution_value'] ?? '',
        'humedad_comentario': _humedadComentarioController.text,
        'humedad_foto': getFotosString('Humedad'),

        'mesada_estado': _fieldData['Mesada']?['initial_value'] ?? '',
        'mesada_solucion': _fieldData['Mesada']?['solution_value'] ?? '',
        'mesada_comentario': _mesadaComentarioController.text,
        'mesada_foto': getFotosString('Mesada'),

        'iluminacion_estado': _fieldData['Iluminación']?['initial_value'] ?? '',
        'iluminacion_solucion': _fieldData['Iluminación']?['solution_value'] ?? '',
        'iluminacion_comentario': _iluminacionComentarioController.text,
        'iluminacion_foto': getFotosString('Iluminación'),

        'limpieza_fosa_estado': _fieldData['Limpieza de Fosa']?['initial_value'] ?? '',
        'limpieza_fosa_solucion': _fieldData['Limpieza de Fosa']?['solution_value'] ?? '',
        'limpieza_fosa_comentario': _limpiezaFosaComentarioController.text,
        'limpieza_fosa_foto': getFotosString('Limpieza de Fosa'),

        'estado_drenaje_estado': _fieldData['Estado de Drenaje']?['initial_value'] ?? '',
        'estado_drenaje_solucion': _fieldData['Estado de Drenaje']?['solution_value'] ?? '',
        'estado_drenaje_comentario': _estadoDrenajeComentarioController.text,
        'estado_drenaje_foto': getFotosString('Estado de Drenaje'),

        // Terminal de pesaje
        'carcasa_estado': _fieldData['Carcasa']?['initial_value'] ?? '',
        'carcasa_solucion': _fieldData['Carcasa']?['solution_value'] ?? '',
        'carcasa_comentario': _carcasaComentarioController.text,
        'carcasa_foto': getFotosString('Carcasa'),

        'teclado_fisico_estado': _fieldData['Teclado Fisico']?['initial_value'] ?? '',
        'teclado_fisico_solucion': _fieldData['Teclado Fisico']?['solution_value'] ?? '',
        'teclado_fisico_comentario': _tecladoFisicoComentarioController.text,
        'teclado_fisico_foto': getFotosString('Teclado Fisico'),

        'display_fisico_estado': _fieldData['Display Fisico']?['initial_value'] ?? '',
        'display_fisico_solucion': _fieldData['Display Fisico']?['solution_value'] ?? '',
        'display_fisico_comentario': _displayFisicoComentarioController.text,
        'display_fisico_foto': getFotosString('Display Fisico'),

        'fuente_poder_estado': _fieldData['Fuente de poder']?['initial_value'] ?? '',
        'fuente_poder_solucion': _fieldData['Fuente de poder']?['solution_value'] ?? '',
        'fuente_poder_comentario': _fuentePoderComentarioController.text,
        'fuente_poder_foto': getFotosString('Fuente de poder'),

        'bateria_operacional_estado': _fieldData['Bateria operacional']?['initial_value'] ?? '',
        'bateria_operacional_solucion': _fieldData['Bateria operacional']?['solution_value'] ?? '',
        'bateria_operacional_comentario': _bateriaOperacionalComentarioController.text,
        'bateria_operacional_foto': getFotosString('Bateria operacional'),

        'bracket_estado': _fieldData['Bracket']?['initial_value'] ?? '',
        'bracket_solucion': _fieldData['Bracket']?['solution_value'] ?? '',
        'bracket_comentario': _bracketComentarioController.text,
        'bracket_foto': getFotosString('Bracket'),

        'teclado_operativo_estado': _fieldData['Teclado Operativo']?['initial_value'] ?? '',
        'teclado_operativo_solucion': _fieldData['Teclado Operativo']?['solution_value'] ?? '',
        'teclado_operativo_comentario': _tecladoOperativoComentarioController.text,
        'teclado_operativo_foto': getFotosString('Teclado Operativo'),

        'display_operativo_estado': _fieldData['Display Operativo']?['initial_value'] ?? '',
        'display_operativo_solucion': _fieldData['Display Operativo']?['solution_value'] ?? '',
        'display_operativo_comentario': _displayOperativoComentarioController.text,
        'display_operativo_foto': getFotosString('Display Operativo'),

        'conector_celda_estado': _fieldData['Contector de celda']?['initial_value'] ?? '',
        'conector_celda_solucion': _fieldData['Contector de celda']?['solution_value'] ?? '',
        'conector_celda_comentario': _contectorCeldaComentarioController.text,
        'conector_celda_foto': getFotosString('Contector de celda'),

        'bateria_memoria_estado': _fieldData['Bateria de memoria']?['initial_value'] ?? '',
        'bateria_memoria_solucion': _fieldData['Bateria de memoria']?['solution_value'] ?? '',
        'bateria_memoria_comentario': _bateriaMemoriaComentarioController.text,
        'bateria_memoria_foto': getFotosString('Bateria de memoria'),

        // Estado general de la balanza
        'limpieza_general_estado': _fieldData['Limpieza general']?['initial_value'] ?? '',
        'limpieza_general_solucion': _fieldData['Limpieza general']?['solution_value'] ?? '',
        'limpieza_general_comentario': _limpiezaGeneralComentarioController.text,
        'limpieza_general_foto': getFotosString('Limpieza general'),

        'golpes_terminal_estado': _fieldData['Golpes al terminal']?['initial_value'] ?? '',
        'golpes_terminal_solucion': _fieldData['Golpes al terminal']?['solution_value'] ?? '',
        'golpes_terminal_comentario': _golpesTerminalComentarioController.text,
        'golpes_terminal_foto': getFotosString('Golpes al terminal'),

        'nivelacion_estado': _fieldData['Nivelacion']?['initial_value'] ?? '',
        'nivelacion_solucion': _fieldData['Nivelacion']?['solution_value'] ?? '',
        'nivelacion_comentario': _nivelacionComentarioController.text,
        'nivelacion_foto': getFotosString('Nivelacion'),

        'limpieza_receptor_estado': _fieldData['Limpieza receptor']?['initial_value'] ?? '',
        'limpieza_receptor_solucion': _fieldData['Limpieza receptor']?['solution_value'] ?? '',
        'limpieza_receptor_comentario': _limpiezaReceptorComentarioController.text,
        'limpieza_receptor_foto': getFotosString('Limpieza receptor'),

        'golpes_receptor_estado': _fieldData['Golpes al receptor de carga']?['initial_value'] ?? '',
        'golpes_receptor_solucion': _fieldData['Golpes al receptor de carga']?['solution_value'] ?? '',
        'golpes_receptor_comentario': _golpesReceptorComentarioController.text,
        'golpes_receptor_foto': getFotosString('Golpes al receptor de carga'),

        'encendido_estado': _fieldData['Encendido']?['initial_value'] ?? '',
        'encendido_solucion': _fieldData['Encendido']?['solution_value'] ?? '',
        'encendido_comentario': _encendidoComentarioController.text,
        'encendido_foto': getFotosString('Encendido'),

        // Balanza/Plataforma
        'limitador_movimiento_estado': _fieldData['Limitador de movimiento']?['initial_value'] ?? '',
        'limitador_movimiento_solucion': _fieldData['Limitador de movimiento']?['solution_value'] ?? '',
        'limitador_movimiento_comentario': _limitadorMovimientoComentarioController.text,
        'limitador_movimiento_foto': getFotosString('Limitador de movimiento'),

        'suspension_estado': _fieldData['Suspensión']?['initial_value'] ?? '',
        'suspension_solucion': _fieldData['Suspensión']?['solution_value'] ?? '',
        'suspension_comentario': _suspensionComentarioController.text,
        'suspension_foto': getFotosString('Suspensión'),

        'limitador_carga_estado': _fieldData['Limitador de carga']?['initial_value'] ?? '',
        'limitador_carga_solucion': _fieldData['Limitador de carga']?['solution_value'] ?? '',
        'limitador_carga_comentario': _limitadorCargaComentarioController.text,
        'limitador_carga_foto': getFotosString('Limitador de carga'),

        'celda_carga_estado': _fieldData['Celda de carga']?['initial_value'] ?? '',
        'celda_carga_solucion': _fieldData['Celda de carga']?['solution_value'] ?? '',
        'celda_carga_comentario': _celdaCargaComentarioController.text,
        'celda_carga_foto': getFotosString('Celda de carga'),

        // Caja sumadora
        'tapa_caja_estado': _fieldData['Tapa de caja sumadora']?['initial_value'] ?? '',
        'tapa_caja_solucion': _fieldData['Tapa de caja sumadora']?['solution_value'] ?? '',
        'tapa_caja_comentario': _tapaCajaComentarioController.text,
        'tapa_caja_foto': getFotosString('Tapa de caja sumadora'),

        'humedad_interna_estado': _fieldData['Humedad Interna']?['initial_value'] ?? '',
        'humedad_interna_solucion': _fieldData['Humedad Interna']?['solution_value'] ?? '',
        'humedad_interna_comentario': _humedadInternaComentarioController.text,
        'humedad_interna_foto': getFotosString('Humedad Interna'),

        'estado_prensacables_estado': _fieldData['Estado de prensacables']?['initial_value'] ?? '',
        'estado_prensacables_solucion': _fieldData['Estado de prensacables']?['solution_value'] ?? '',
        'estado_prensacables_comentario': _estadoPrensacablesComentarioController.text,
        'estado_prensacables_foto': getFotosString('Estado de prensacables'),

        'estado_borneas_estado': _fieldData['Estado de borneas']?['initial_value'] ?? '',
        'estado_borneas_solucion': _fieldData['Estado de borneas']?['solution_value'] ?? '',
        'estado_borneas_comentario': _estadoBorneasComentarioController.text,
        'estado_borneas_foto': getFotosString('Estado de borneas'),

        'pintado_estado': _fieldData['Pintado']?['initial_value'] ?? '',
        'pintado_solucion': _fieldData['Pintado']?['solution_value'] ?? '',
        'pintado_comentario': _pintadoComentarioController.text,
        'pintado_foto': getFotosString('Pintado'),

        'limpieza_profunda_estado': _fieldData['Limpieza profunda']?['initial_value'] ?? '',
        'limpieza_profunda_solucion': _fieldData['Limpieza profunda']?['solution_value'] ?? '',
        'limpieza_profunda_comentario': _limpiezaProfundaComentarioController.text,
        'limpieza_profunda_foto': getFotosString('Limpieza profunda'),

        // PRUEBAS METROLÓGICAS INICIALES
        'retorno_cero_inicial': _retornoCeroInicialDropdownController.value,
        'carga_retorno_cero_inicial': _retornoCeroInicialValorController.text,
        'unidad_retorno_cero_inicial': _selectedUnitInicial,
      };

      // Agregar datos de pruebas metrológicas iniciales si están activas
      if (_showPlatformFieldsInicial) {
        dbData.addAll({
          'tipo_plataforma_inicial': _selectedPlatformInicial ?? '',
          'puntos_ind_inicial': _selectedOptionInicial ?? '',
          'carga_exc_inicial': _cargaExcInicialController.text,
        });

        // Posiciones de excentricidad inicial
        for (int i = 0; i < _positionInicialControllers.length; i++) {
          final position = i + 1;
          dbData.addAll({
            'posicion_inicial_$position': _positionInicialControllers[i].text,
            'indicacion_inicial_$position': _indicationInicialControllers[i].text,
            'retorno_inicial_$position': _returnInicialControllers[i].text,
          });
        }
      }

      if (_showRepetibilidadFieldsInicial) {
        // Carga 1 inicial
        dbData['repetibilidad1_inicial'] = _repetibilidadInicialController1.text;
        for (int i = 0; i < _selectedRowCountInicial; i++) {
          final testNum = i + 1;
          dbData.addAll({
            'indicacion1_inicial_$testNum': _indicacionInicialControllers1[i].text,
            'retorno1_inicial_$testNum': _retornoInicialControllers1[i].text,
          });
        }

        // Carga 2 inicial (si aplica)
        if (_selectedRepetibilityCountInicial >= 2) {
          dbData['repetibilidad2_inicial'] = _repetibilidadInicialController2.text;
          for (int i = 0; i < _selectedRowCountInicial; i++) {
            final testNum = i + 1;
            dbData.addAll({
              'indicacion2_inicial_$testNum': _indicacionInicialControllers2[i].text,
              'retorno2_inicial_$testNum': _retornoInicialControllers2[i].text,
            });
          }
        }

        // Carga 3 inicial (si aplica)
        if (_selectedRepetibilityCountInicial >= 3) {
          dbData['repetibilidad3_inicial'] = _repetibilidadInicialController3.text;
          for (int i = 0; i < _selectedRowCountInicial; i++) {
            final testNum = i + 1;
            dbData.addAll({
              'indicacion3_inicial_$testNum': _indicacionInicialControllers3[i].text,
              'retorno3_inicial_$testNum': _retornoInicialControllers3[i].text,
            });
          }
        }
      }

      if (_showLinealidadFieldsInicial) {
        for (int i = 0; i < _rowsInicial.length; i++) {
          final pointNum = i + 1;
          dbData.addAll({
            'lin_inicial_$pointNum': _rowsInicial[i]['lt']?.text ?? '',
            'ind_inicial_$pointNum': _rowsInicial[i]['indicacion']?.text ?? '',
            'retorno_lin_inicial_$pointNum': _rowsInicial[i]['retorno']?.text ?? '0',
          });
        }
      }

      // PRUEBAS METROLÓGICAS FINALES
      dbData.addAll({
        'retorno_cero_final': _retornoCeroDropdownController.value,
        'carga_retorno_cero_final': _retornoCeroValorController.text,
        'unidad_retorno_cero_final': _selectedUnit,
      });

      // Agregar datos de pruebas metrológicas finales si están activas
      if (_showPlatformFields) {
        dbData.addAll({
          'tipo_plataforma_final': _selectedPlatform ?? '',
          'puntos_ind_final': _selectedOption ?? '',
          'carga_exc_final': _cargaExcController.text,
        });

        // Posiciones de excentricidad final
        for (int i = 0; i < _positionControllers.length; i++) {
          final position = i + 1;
          dbData.addAll({
            'posicion_final_$position': _positionControllers[i].text,
            'indicacion_final_$position': _indicationControllers[i].text,
            'retorno_final_$position': _returnControllers[i].text,
          });
        }
      }

      if (_showRepetibilidadFields) {
        dbData['repetibilidad_count_final'] = _selectedRepetibilityCount;
        dbData['repetibilidad_rows_final'] = _selectedRowCount;

        // Carga 1 final
        dbData['repetibilidad1_final'] = _repetibilidadController1.text;
        for (int i = 0; i < _selectedRowCount; i++) {
          final testNum = i + 1;
          dbData.addAll({
            'indicacion1_final_$testNum': _indicacionControllers1[i].text,
            'retorno1_final_$testNum': _retornoControllers1[i].text,
          });
        }

        // Carga 2 final (si aplica)
        if (_selectedRepetibilityCount >= 2) {
          dbData['repetibilidad2_final'] = _repetibilidadController2.text;
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            dbData.addAll({
              'indicacion2_final_$testNum': _indicacionControllers2[i].text,
              'retorno2_final_$testNum': _retornoControllers2[i].text,
            });
          }
        }

        // Carga 3 final (si aplica)
        if (_selectedRepetibilityCount >= 3) {
          dbData['repetibilidad3_final'] = _repetibilidadController3.text;
          for (int i = 0; i < _selectedRowCount; i++) {
            final testNum = i + 1;
            dbData.addAll({
              'indicacion3_final_$testNum': _indicacionControllers3[i].text,
              'retorno3_final_$testNum': _retornoControllers3[i].text,
            });
          }
        }
      }

      if (_showLinealidadFields) {
        for (int i = 0; i < _rows.length; i++) {
          final pointNum = i + 1;
          dbData.addAll({
            'lin_final_$pointNum': _rows[i]['lt']?.text ?? '',
            'ind_final_$pointNum': _rows[i]['indicacion']?.text ?? '',
            'retorno_lin_final_$pointNum': _rows[i]['retorno']?.text ?? '0',
          });
        }
      }

      // ✅ USAR upsertRegistro del helper (actualiza si existe, inserta si no)
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
        'Error al guardar los datos: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Error al guardar relevamiento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () async {
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
                'CÓDIGO MET: ${widget.codMetrica}', // Aquí se añade el código métrico
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
                  'MNT PRV AVANZADO STIL',
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
                  'PRUEBAS METROLÓGICAS INICIALES',
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
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _retornoCeroInicialDropdownController,
                        builder: (context, selectedValue, child) {
                          final options = [
                            '1 Bueno',
                            '2 Aceptable',
                            '3 Malo',
                            '4 No aplica'
                          ];
                          final validValue = options.contains(selectedValue)
                              ? selectedValue
                              : options.first;

                          return DropdownButtonFormField<String>(
                            value:
                                selectedValue, // Valor controlado por el ValueNotifier
                            decoration: _buildInputDecoration(
                              'Retorno a cero inicial',
                            ),
                            items: [
                              '1 Bueno',
                              '2 Aceptable',
                              '3 Malo',
                              '4 No aplica'
                            ].map((String value) {
                              Color textColor;
                              Icon? icon;
                              switch (value) {
                                case '1 Bueno':
                                  textColor = Colors.green;
                                  icon = const Icon(Icons.check_circle,
                                      color: Colors.green);
                                  break;
                                case '2 Aceptable':
                                  textColor = Colors.orange;
                                  icon = const Icon(Icons.warning,
                                      color: Colors.orange);
                                  break;
                                case '3 Malo':
                                  textColor = Colors.red;
                                  icon = const Icon(Icons.error,
                                      color: Colors.red);
                                  break;
                                case '4 No aplica':
                                  textColor = Colors.grey;
                                  icon = const Icon(Icons.block,
                                      color: Colors.grey);
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
                                    Text(value,
                                        style: TextStyle(color: textColor)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _retornoCeroInicialDropdownController.value =
                                    value; // Actualizar el controlador
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _retornoCeroInicialValorController,
                        decoration: _buildInputDecoration(
                          'Carga de Prueba Inicial',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnitInicial,
                                items: ['kg', 'g'].map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(unit),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedUnitInicial = newValue;
                                      // Actualizar solo la unidad manteniendo el valor numérico
                                      final numericValue =
                                          _retornoCeroInicialValorController
                                              .text
                                              .replaceAll(
                                                  RegExp(r'[^0-9]'), '');
                                      _retornoCeroInicialValorController
                                          .text = numericValue
                                              .isNotEmpty
                                          ? '$numericValue $_selectedUnitInicial'
                                          : '';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.arrow_drop_down),
                                elevation: 2,
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          // Solo actualizar el valor numérico (la unidad se mantiene)
                          final numericValue =
                              value.replaceAll(RegExp(r'[^0-9]'), '');
                          _retornoCeroInicialValorController.text =
                              numericValue.isNotEmpty
                                  ? '$numericValue $_selectedUnitInicial'
                                  : '';
                        },
                      ),
                    ),
                  ],
                ),
                //SWITCH DE LAS PRUEBAS
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE EXCENTRICIDAD INICIAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showPlatformFieldsInicial,
                  onChanged: (bool value) {
                    setState(() {
                      _showPlatformFieldsInicial = value;
                      if (!value) {
                        _selectedPlatformInicial = null;
                        _selectedOptionInicial = null;
                        _selectedImagePathInicial = null;
                      }
                    });
                  },
                ),
                _buildPlatformFieldsInicial(),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE REPETIBILIDAD INICIAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showRepetibilidadFieldsInicial,
                  onChanged: (bool value) {
                    setState(() {
                      _showRepetibilidadFieldsInicial = value;
                    });
                  },
                ),
                _buildRepetibilidadFieldsInicial(),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE LINEALIDAD INICIAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showLinealidadFieldsInicial,
                  onChanged: (bool value) {
                    setState(() {
                      _showLinealidadFieldsInicial = value;
                    });
                  },
                ),
                _showLinealidadFieldsInicial
                    ? _buildLinealidadFieldsInicial(context)
                    : const SizedBox(),
                const SizedBox(height: 20.0),
                const Text(
                  'ESTADO GENERAL DEL INSTRUMENTO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9DEAE5), // Color personalizado
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ENTORNO DE INSTALACIÓN:',
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
                    context, 'Vibración', _vibracionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Polvo', _polvoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Temperatura', _teperaturaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Humedad', _humedadComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Mesada', _mesadaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Iluminación', _iluminacionComentarioController),
                const SizedBox(height: 10.0),
                _buildDropdownFieldWithComment(context, 'Limpieza de Fosa',
                    _limpiezaFosaComentarioController),
                const SizedBox(height: 10.0),
                _buildDropdownFieldWithComment(context, 'Estado de Drenaje',
                    _estadoDrenajeComentarioController),
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TERMINAL DE PESAJE:',
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
                _buildDropdownFieldWithComment(context, 'Teclado Fisico',
                    _tecladoFisicoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Display Fisico',
                    _displayFisicoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Fuente de poder',
                    _fuentePoderComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Bateria operacional',
                    _bateriaOperacionalComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Bracket', _bracketComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Teclado Operativo',
                    _tecladoOperativoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Display Operativo',
                    _displayOperativoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Contector de celda',
                    _contectorCeldaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Bateria de memoria',
                    _bateriaMemoriaComentarioController),
                const SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ESTADO GENERAL DE LA BALANZA:',
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
                _buildDropdownFieldWithComment(context, 'Limpieza general',
                    _limpiezaGeneralComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Golpes al terminal',
                    _golpesTerminalComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Nivelacion', _nivelacionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Limpieza receptor',
                    _limpiezaReceptorComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Golpes al receptor de carga',
                    _golpesReceptorComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Encendido', _encendidoComentarioController),
                const SizedBox(height: 20.0),
                const Text(
                  'BALANZA | PLATAFORMA:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16a085), // Color personalizado
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Limitador de movimiento',
                    _limitadorMovimientoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Suspensión', _suspensionComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Limitador de carga',
                    _limitadorCargaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Celda de carga', _celdaCargaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context, 'Pintado', _pintadoComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Limpieza profunda',
                    _limpiezaProfundaComentarioController),
                const SizedBox(height: 20.0),
                const Text(
                  'CAJA SUMADORA:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFa3e4d7), // Color personalizado
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Tapa de caja sumadora',
                    _tapaCajaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Humedad Interna',
                    _humedadInternaComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(
                    context,
                    'Estado de prensacables',
                    _estadoPrensacablesComentarioController),
                const SizedBox(height: 20.0),
                _buildDropdownFieldWithComment(context, 'Estado de borneas',
                    _estadoBorneasComentarioController),
                const SizedBox(height: 20.0),
                const Text(
                  'PRUEBAS METROLÓGICAS FINALES',
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
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _retornoCeroDropdownController,
                        builder: (context, selectedValue, child) {
                          final options = [
                            '1 Bueno',
                            '2 Aceptable',
                            '3 Malo',
                            '4 No aplica'
                          ];
                          final validValue = options.contains(selectedValue)
                              ? selectedValue
                              : options.first;

                          return DropdownButtonFormField<String>(
                            value:
                                selectedValue, // Valor controlado por el ValueNotifier
                            decoration: _buildInputDecoration(
                              'Retorno a cero',
                            ),
                            items: [
                              '1 Bueno',
                              '2 Aceptable',
                              '3 Malo',
                              '4 No aplica'
                            ].map((String value) {
                              Color textColor;
                              Icon? icon;
                              switch (value) {
                                case '1 Bueno':
                                  textColor = Colors.green;
                                  icon = const Icon(Icons.check_circle,
                                      color: Colors.green);
                                  break;
                                case '2 Aceptable':
                                  textColor = Colors.orange;
                                  icon = const Icon(Icons.warning,
                                      color: Colors.orange);
                                  break;
                                case '3 Malo':
                                  textColor = Colors.red;
                                  icon = const Icon(Icons.error,
                                      color: Colors.red);
                                  break;
                                case '4 No aplica':
                                  textColor = Colors.grey;
                                  icon = const Icon(Icons.block,
                                      color: Colors.grey);
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
                                    Text(value,
                                        style: TextStyle(color: textColor)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _retornoCeroDropdownController.value =
                                    value; // Actualizar el controlador
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _retornoCeroValorController,
                        decoration: _buildInputDecoration(
                          'Carga de Prueba',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                items: ['kg', 'g'].map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(unit),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedUnit = newValue;
                                      // Actualizar solo la unidad manteniendo el valor numérico
                                      final numericValue =
                                          _retornoCeroValorController.text
                                              .replaceAll(
                                                  RegExp(r'[^0-9]'), '');
                                      _retornoCeroValorController.text =
                                          numericValue.isNotEmpty
                                              ? '$numericValue $_selectedUnit'
                                              : '';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.arrow_drop_down),
                                elevation: 2,
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          // Solo actualizar el valor numérico (la unidad se mantiene)
                          final numericValue =
                              value.replaceAll(RegExp(r'[^0-9]'), '');
                          _retornoCeroValorController.text =
                              numericValue.isNotEmpty
                                  ? '$numericValue $_selectedUnit'
                                  : '';
                        },
                      ),
                    ),
                  ],
                ),
                //SWITCH DE LAS PRUEBAS
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE EXCENTRICIDAD FINAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showPlatformFields,
                  onChanged: (bool value) {
                    setState(() {
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
                  title: const Text('PRUEBAS DE REPETIBILIDAD FINAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showRepetibilidadFields,
                  onChanged: (bool value) {
                    setState(() {
                      _showRepetibilidadFields = value;
                    });
                  },
                ),
                _buildRepetibilidadFields(),
                const SizedBox(height: 20.0),
                SwitchListTile(
                  title: const Text('PRUEBAS DE LINEALIDAD FINAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _showLinealidadFields,
                  onChanged: (bool value) {
                    setState(() {
                      _showLinealidadFields = value;
                    });
                  },
                ),
                _showLinealidadFields
                    ? _buildLinealidadFields(context)
                    : const SizedBox(),
                const SizedBox(height: 20.0),
                const Text(
                  'ESTADO FINAL DE LA BALANZA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf5b041), // Color personalizado
                  ),
                  textAlign: TextAlign.center,
                ),
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
                    'Diagnostico',
                    'Mnt Preventivo Regular',
                    'Mnt Preventivo Avanzado',
                    'Mnt Correctivo',
                    'Ajustes Metrológicos',
                    'Calibración',
                    'Sin recomendación'
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
                const SizedBox(height: 20.0), // Espaciado entre los campos
                DropdownButtonFormField<String>(
                  value:
                      _selectedFisico, // Variable para almacenar la selección
                  decoration: InputDecoration(
                    labelText: 'Físico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFisico = newValue; // Actualiza la selección
                    });
                  },
                ),
                const SizedBox(height: 20.0), // Espaciado entre los campos
                DropdownButtonFormField<String>(
                  value:
                      _selectedOperacional, // Variable para almacenar la selección
                  decoration: InputDecoration(
                    labelText: 'Operacional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOperacional = newValue; // Actualiza la selección
                    });
                  },
                ),
                const SizedBox(height: 20.0), // Espaciado entre los campos
                DropdownButtonFormField<String>(
                  value:
                      _selectedMetrologico, // Variable para almacenar la selección
                  decoration: InputDecoration(
                    labelText: 'Metrológico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMetrologico = newValue; // Actualiza la selección
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
                            onPressed: isSaved ? ()
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FinServicioMntAvaStilScreen(
                                    sessionId: widget.sessionId,
                                    secaValue: widget.secaValue,
                                    codMetrica: widget.codMetrica,
                                    nReca: widget.nReca,
                                    userName: widget.userName,
                                    clienteId: widget.clienteId,
                                    plantaCodigo: widget.plantaCodigo,
                                    tableName: 'mnt_prv_avanzado_stil',
                                  ),
                                ),
                              );
                            }
                            : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isSaved ? const Color(0xFF167D1D) : Colors.grey,
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
