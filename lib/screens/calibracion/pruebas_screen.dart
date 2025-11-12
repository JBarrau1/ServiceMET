import 'dart:io';
import 'dart:ui';
import 'package:service_met/screens/calibracion/fin_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import 'calibration_flow.dart';
import 'package:provider/provider.dart';
import '../../provider/balanza_provider.dart';

// Constantes de la aplicación
class AppConstants {
  static const int maxPreloads = 6;
  static const int minPreloads = 5;
  static const int maxComentarioLength = 300;
  static const String noAplica = 'NO APLICA';
  static const String confirmacion = 'CONFIRMACIÓN';
  static const Duration doubleTapDuration = Duration(seconds: 2);
}

class PruebasScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String codMetrica;
  final String nReca;

  const PruebasScreen({
    super.key,
    required this.sessionId,
    required this.codMetrica,
    required this.secaValue,
    required this.nReca,
  });

  @override
  _PruebasScreenState createState() => _PruebasScreenState();
}

class _PruebasScreenState extends State<PruebasScreen> {
  final List<TextEditingController> _precargasControllers = [];
  final List<TextEditingController> _indicacionesControllers = [];
  int _rowCount = AppConstants.minPreloads;
  DateTime? _lastPressedTime;
  bool _isDataSaved = false;
  bool _isAjusteRealizado = false;
  bool _isAjusteExterno = false;

  final TextEditingController _tipoAjusteController = TextEditingController();
  final TextEditingController _cargasPesasController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _tiController = TextEditingController();
  final TextEditingController _hriController = TextEditingController();
  final TextEditingController _patmiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isFabVisible = ValueNotifier<bool>(true);
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isNextButtonVisible = ValueNotifier<bool>(false);
  final TextEditingController _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeControllers();
    _setCurrentTime();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isFabVisible.dispose();
    _isNextButtonVisible.dispose();

    _disposeControllers();

    _tipoAjusteController.dispose();
    _cargasPesasController.dispose();
    _horaController.dispose();
    _tiController.dispose();
    _hriController.dispose();
    _patmiController.dispose();
    _comentarioController.dispose();

    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _precargasControllers) {
      controller.dispose();
    }
    for (var controller in _indicacionesControllers) {
      controller.dispose();
    }
    _precargasControllers.clear();
    _indicacionesControllers.clear();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      _isFabVisible.value = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      _isFabVisible.value = true;
    }
  }

  void _initializeControllers() {
    for (int i = 0; i < _rowCount; i++) {
      _precargasControllers.add(TextEditingController());
      _indicacionesControllers.add(TextEditingController());
    }
  }

  void _addRow(BuildContext context) {
    if (_rowCount >= AppConstants.maxPreloads) {
      _showSnackBar(
        context,
        'No se pueden agregar más de ${AppConstants.maxPreloads} precargas.',
      );
      return;
    }

    setState(() {
      _rowCount++;
      _precargasControllers.add(TextEditingController());
      _indicacionesControllers.add(TextEditingController());
    });
  }

  void _removeRow() {
    if (_rowCount > AppConstants.minPreloads) {
      setState(() {
        _rowCount--;
        _precargasControllers.removeLast().dispose();
        _indicacionesControllers.removeLast().dispose();
      });
    }
  }

  void _setCurrentTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _horaController.text = formattedTime;
  }

  Future<double> _getD1FromDatabase() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> result = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',  // ← MISMO CRITERIO QUE GUARDADO
        whereArgs: [widget.secaValue, widget.sessionId],
        columns: ['d1'],
        limit: 1,
      );

      if (result.isNotEmpty && result.first['d1'] != null) {
        final d1Value = result.first['d1'];

        // Manejo robusto de tipos
        if (d1Value is double) return d1Value;
        if (d1Value is int) return d1Value.toDouble();
        if (d1Value is String) {
          return double.tryParse(d1Value) ?? 0.1;
        }
      }

      // Valor por defecto si no se encuentra
      return 0.1;

    } catch (e, stackTrace) {
      debugPrint('Error al obtener d1 de la base de datos: $e');
      debugPrint('StackTrace: $stackTrace');
      return 0.1;
    }
  }

  Widget _buildPreloadRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('${index + 1}.', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _precargasControllers[index],
              decoration: _buildInputDecoration('Precarga'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _indicacionesControllers[index].text = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FutureBuilder<double>(
              future: _getD1FromDatabase(),
              builder: (context, snapshot) {
                // SOLO de la base de datos - Eliminado el Provider
                final d1 = snapshot.data ?? 0.1;
                final decimalPlaces = _getDecimalPlaces(d1);

                return TextFormField(
                  controller: _indicacionesControllers[index],
                  decoration: _buildInputDecoration(
                    'Indicación',
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String newValue) {
                        setState(() {
                          _indicacionesControllers[index].text = newValue;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        final baseValue = double.tryParse(_indicacionesControllers[index].text) ?? 0.0;
                        return _buildPopupMenuItems(baseValue, d1, decimalPlaces);
                      },
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(double baseValue, double d1, int decimalPlaces) {
    List<double> allValues = [];

    for (int i = 5; i >= 1; i--) {
      allValues.add(baseValue + (i * d1));
    }

    allValues.add(baseValue);

    for (int i = 1; i <= 5; i++) {
      allValues.add(baseValue - (i * d1));
    }

    return allValues.map((value) {
      return PopupMenuItem<String>(
        value: value.toStringAsFixed(decimalPlaces),
        child: Text(value.toStringAsFixed(decimalPlaces)),
      );
    }).toList();
  }

  int _getDecimalPlaces(double value) {
    String text = value.toString();
    if (text.contains('.')) {
      return text.split('.')[1].replaceAll(RegExp(r'0*$'), '').length;
    }
    return 0;
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(context, 'Complete todos los campos requeridos', isError: true);
      return;
    }

    if (!_validateAllFields(context)) return;

    try {
      final dbHelper = AppDatabase();
      final registro = _createRegistro();

      await dbHelper.upsertRegistroCalibracion(registro);

      setState(() => _isDataSaved = true);
      _isNextButtonVisible.value = true;
      _showSnackBar(context, 'Datos guardados correctamente');
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar los datos', isError: true);
      debugPrint('Error al guardar: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  bool _validateAllFields(BuildContext context) {
    for (int i = 0; i < _precargasControllers.length; i++) {
      if (_precargasControllers[i].text.isEmpty ||
          _indicacionesControllers[i].text.isEmpty) {
        _showSnackBar(
            context,
            'Complete todas las precargas e indicaciones',
            isError: true
        );
        return false;
      }
    }

    final validations = [
      (_horaController.text.isEmpty, 'Registre la hora'),
      (_hriController.text.isEmpty, 'Ingrese el HRi'),
      (_tiController.text.isEmpty, 'Ingrese el Ti'),
      (_patmiController.text.isEmpty, 'Ingrese el Patmi'),
      (_isAjusteRealizado && _tipoAjusteController.text.isEmpty, 'Ingrese el tipo de ajuste'),
      (_isAjusteExterno && _cargasPesasController.text.isEmpty, 'Ingrese las pesas de ajuste'),
    ];

    for (final validation in validations) {
      if (validation.$1) {
        _showSnackBar(context, validation.$2, isError: true);
        return false;
      }
    }

    return true;
  }

  Map<String, Object?> _createRegistro() {
    final Map<String, Object?> registro = {
      'seca': widget.secaValue,
      'session_id': widget.sessionId,
      'observaciones': _comentarioController.text.trim(),
      'ajuste': _isAjusteRealizado ? 'Sí' : 'No',
      'tipo': _tipoAjusteController.text,
      'cargas_pesas': _cargasPesasController.text,
      'hora': _horaController.text,
      'hri': _hriController.text,
      'ti': _tiController.text,
      'patmi': _patmiController.text,
    };

    for (int i = 0; i < _precargasControllers.length; i++) {
      registro['precarga${i + 1}'] = _precargasControllers[i].text;
      registro['p_indicador${i + 1}'] = _indicacionesControllers[i].text;
    }

    for (int i = _precargasControllers.length; i < AppConstants.maxPreloads; i++) {
      registro['precarga${i + 1}'] = '';
      registro['p_indicador${i + 1}'] = '';
    }

    return registro;
  }

  void _onAjusteRealizadoChanged(String? value) {
    setState(() {
      _isAjusteRealizado = value == 'Sí';
      if (!_isAjusteRealizado) {
        _tipoAjusteController.text = AppConstants.noAplica;
        _cargasPesasController.text = AppConstants.noAplica;
        _isAjusteExterno = false;
      } else {
        _tipoAjusteController.clear();
        _cargasPesasController.clear();
      }
    });
  }

  void _onTipoAjusteChanged(String? value) {
    setState(() {
      _isAjusteExterno = value == 'EXTERNO';
      _tipoAjusteController.text = value ?? '';
      if (!_isAjusteExterno) {
        _cargasPesasController.text = AppConstants.noAplica;
      } else {
        _cargasPesasController.clear();
      }
    });
  }

  InputDecoration _buildInputDecoration(
      String labelText, {
        Widget? suffixIcon,
        String? suffixText,
      }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }

  Widget _buildDetailContainer(
      String label,
      String value,
      Color textColor,
      Color borderColor
      ) {
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
          Expanded(
            child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: textColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > AppConstants.doubleTapDuration) {
      _lastPressedTime = now;
      _showSnackBar(
          context,
          'Presione nuevamente para retroceder. Los datos registrados se perderán.'
      );
      return false;
    }
    return true;
  }

  Future<void> _saveComentarioToDatabase(BuildContext context, String comentario) async {
    try {
      final dbHelper = AppDatabase();
      final registro = {
        'seca': widget.secaValue,
        'session_id': widget.sessionId,
        'observaciones': comentario.trim(),
      };

      await dbHelper.upsertRegistroCalibracion(registro);
      _showSnackBar(context, 'Comentario guardado correctamente');
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar el comentario', isError: true);
      debugPrint('Error al guardar comentario: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  const SizedBox(height: 10),
                  _buildPrecargasSection(context),
                  const SizedBox(height: 20),
                  _buildAjustesSection(),
                  const SizedBox(height: 20),
                  _buildCondicionesAmbientalesSection(),
                  const SizedBox(height: 20.0),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildSpeedDial(context, balanza),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'INICIO DE PRUEBAS DE ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          children: const <TextSpan>[
            TextSpan(
                text: 'PRECARGAS DE AJUSTE',
                style: TextStyle(color: Colors.orange)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecargasSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
                'Precargas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => _addRow(context),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: _removeRow,
                ),
              ],
            ),
          ],
        ),
        ...List.generate(_rowCount, (index) => _buildPreloadRow(index)),
      ],
    );
  }

  Widget _buildAjustesSection() {
    return Column(
      children: [
        const Center(
            child: Text(
                'REGISTRO DE AJUSTES',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)
            )
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          items: ['Sí', 'No'].map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: _onAjusteRealizadoChanged,
          decoration: _buildInputDecoration('¿Se Realizó el Ajuste?'),
          validator: (value) => value == null ? 'Seleccione una opción' : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          items: ['INTERNO', 'EXTERNO'].map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: _isAjusteRealizado ? _onTipoAjusteChanged : null,
          decoration: _buildInputDecoration('Tipo de Ajuste:'),
          validator: (value) => _isAjusteRealizado && value == null
              ? 'Seleccione una opción'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _cargasPesasController,
          decoration: _buildInputDecoration('Cargas / Pesas de Ajuste:'),
          enabled: _isAjusteExterno,
          validator: (value) => _isAjusteExterno && (value == null || value.isEmpty)
              ? 'Ingrese un valor'
              : null,
        ),
      ],
    );
  }

  Widget _buildCondicionesAmbientalesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'REGISTRO DE CONDICIONES AMBIENTALES INICIALES',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _horaController,
              readOnly: true,
              decoration: _buildInputDecoration(
                'Hora',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _setCurrentTime(),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16.0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Haga clic en el icono del reloj para ingresar la hora. La hora se obtiene automáticamente del sistema, NO ES EDITABLE.',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _hriController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: _buildInputDecoration('HRi (%)', suffixText: '%'),
          validator: (value) => value == null || value.isEmpty
              ? 'Ingrese un valor'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _tiController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: _buildInputDecoration('ti (°C)', suffixText: '°C'),
          validator: (value) => value == null || value.isEmpty
              ? 'Ingrese un valor'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _patmiController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: _buildInputDecoration('Patmi (hPa)', suffixText: 'hPa'),
          validator: (value) => value == null || value.isEmpty
              ? 'Ingrese un valor'
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _saveDataToDatabase(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3e7732)
                  ),
                  child: const Text('1: GUARDAR DATOS'),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Guarde los datos para continuar con las pruebas de Excentricidad.',
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isNextButtonVisible,
              builder: (context, isVisible, child) {
                return Visibility(
                  visible: isVisible,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (!_isDataSaved) {
                            _showSnackBar(
                                context,
                                'Debe guardar los datos antes de continuar',
                                isError: true
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate()) {
                            _showConfirmationDialog(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007195)
                        ),
                        child: const Text('2: SIGUIENTE'),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Se empezará con las pruebas de Excentricidad.',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              AppConstants.confirmacion,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)
          ),
          content: const Text(
              '¿Estás seguro de los datos registrados? Empezaremos con las pruebas de Excentricidad.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToScreen(
                  CalibrationFlowScreen(
                    selectedBalanza: const {},
                    codMetrica: widget.codMetrica,
                    secaValue: widget.secaValue,
                    sessionId: widget.sessionId,
                  ),
                );
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedDial(BuildContext context, dynamic balanza) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFabVisible,
      builder: (context, isVisible, child) {
        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      child: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.black54),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.info),
            backgroundColor: Colors.blueAccent,
            label: 'Información de la balanza',
            onTap: () => _showBalanzaInfo(context, balanza),
          ),
          SpeedDialChild(
            child: const Icon(Icons.info),
            backgroundColor: Colors.orangeAccent,
            label: 'Datos del Último Servicio',
            onTap: () => _showLastServiceData(context),
          ),
        ],
      ),
    );
  }

  void _showBalanzaInfo(BuildContext context, dynamic balanza) {
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                if (balanza != null) ...[
                  _buildDetailContainer(
                      'Código Métrica',
                      balanza.cod_metrica,
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'Unidades',
                      balanza.unidad.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'pmax1',
                      balanza.cap_max1,
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'd1',
                      balanza.d1.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'e1',
                      balanza.e1.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'dec1',
                      balanza.dec1.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'pmax2',
                      balanza.cap_max2,
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'd2',
                      balanza.d2.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'e2',
                      balanza.e2.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'dec2',
                      balanza.dec2.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'pmax3',
                      balanza.cap_max3,
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'd3',
                      balanza.d3.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'e3',
                      balanza.e3.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                  _buildDetailContainer(
                      'dec3',
                      balanza.dec3.toString(),
                      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      Colors.grey
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLastServiceData(BuildContext context) {
    final balanzaProvider = Provider.of<BalanzaProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        if (balanzaProvider.isNewBalanza || balanzaProvider.lastServiceData == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay datos de servicio histórico para esta balanza',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final textColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
        final dividerColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;

        final Map<String, String> fieldLabels = {
          'reg_fecha': 'Fecha del Último Servicio',
          'reg_usuario': 'Técnico Responsable',
          'seca': 'Último SECA',
          'exc': 'Exc',
        };

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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...balanzaProvider.lastServiceData!.entries
                    .where((entry) =>
                entry.value != null &&
                    fieldLabels.containsKey(entry.key))
                    .map((entry) => _buildDetailContainer(
                  fieldLabels[entry.key]!,
                  entry.key == 'reg_fecha'
                      ? DateFormat('yyyy-MM-dd').format(
                      DateTime.parse(entry.value)
                  )
                      : entry.value.toString(),
                  textColor,
                  dividerColor,
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}