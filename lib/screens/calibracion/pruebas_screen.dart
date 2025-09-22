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

class PruebasScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String codMetrica;

  const PruebasScreen({
    super.key,
    required this.sessionId,
    required this.codMetrica,
    required this.secaValue,
  });

  @override
  _PruebasScreenState createState() => _PruebasScreenState();
}

class _PruebasScreenState extends State<PruebasScreen> {
  // Constantes para evitar números mágicos
  static const int maxPreloads = 6;
  static const int minPreloads = 5;

  final List<TextEditingController> _precargasControllers = [];
  final List<TextEditingController> _indicacionesControllers = [];
  int _rowCount = minPreloads;
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
    _setCurrentTime(); // Establecer hora actual al iniciar
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isFabVisible.dispose();
    _isNextButtonVisible.dispose();

    // Limpiar todos los controladores
    for (var controller in _precargasControllers) {
      controller.dispose();
    }
    for (var controller in _indicacionesControllers) {
      controller.dispose();
    }
    _tipoAjusteController.dispose();
    _cargasPesasController.dispose();
    _horaController.dispose();
    _tiController.dispose();
    _hriController.dispose();
    _patmiController.dispose();
    _comentarioController.dispose();

    super.dispose();
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
    if (_rowCount >= maxPreloads) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden agregar más de 6 precargas.'),
          duration: Duration(seconds: 2),
        ),
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
    if (_rowCount > minPreloads) {
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
        where: 'seca = ?',
        whereArgs: [widget.secaValue],
        columns: ['d1'],
        limit: 1,
      );

      if (result.isNotEmpty && result.first['d1'] != null) {
        return double.tryParse(result.first['d1'].toString()) ?? 0.1;
      }
      return 0.1;
    } catch (e, stackTrace) {
      debugPrint('Error al obtener d1: $e');
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
            child: TextField(
              controller: _precargasControllers[index],
              decoration: buildInputDecoration('Precarga'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
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
                final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
                final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;
                final decimalPlaces = _getDecimalPlaces(d1);

                return TextFormField(
                  controller: _indicacionesControllers[index],
                  decoration: buildInputDecoration(
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
                      return 'Por favor ingrese un valor';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
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

    // Valores incrementados (+5d1, +4d1, ..., +d1)
    for (int i = 5; i >= 1; i--) {
      allValues.add(baseValue + (i * d1));
    }

    // Valor actual (sin cambios)
    allValues.add(baseValue);

    // Valores decrementados (-d1, -2d1, ..., -5d1)
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
    if (!_validateFields(context)) return;

    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);
      final Map<String, dynamic> registro = _createRegistro();

      registro['observaciones'] = _comentarioController.text.trim();
      registro['seca'] = widget.secaValue;
      registro['session_id'] = widget.sessionId;

      if (existingRecord != null) {
        await dbHelper.upsertRegistroCalibracion(registro);
      } else {
        await dbHelper.insertRegistroCalibracion(registro);
      }

      setState(() => _isDataSaved = true);
      _isNextButtonVisible.value = true;
      _showSnackBar(context, 'Datos guardados correctamente');
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar los datos: $e', isError: true);
      debugPrint('Error al guardar: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  bool _validateFields(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    for (int i = 0; i < _precargasControllers.length; i++) {
      if (_precargasControllers[i].text.isEmpty || _indicacionesControllers[i].text.isEmpty) {
        _showSnackBar(context, 'Debe completar todas las precargas y su respectiva indicación', isError: true);
        return false;
      }
    }

    if (_horaController.text.isEmpty) {
      _showSnackBar(context, 'Registre la hora', isError: true);
      return false;
    }

    if (_hriController.text.isEmpty) {
      _showSnackBar(context, 'Ingrese el HRi', isError: true);
      return false;
    }

    if (_tiController.text.isEmpty) {
      _showSnackBar(context, 'Ingrese el Ti', isError: true);
      return false;
    }

    if (_patmiController.text.isEmpty) {
      _showSnackBar(context, 'Ingrese el Patmi', isError: true);
      return false;
    }

    if (_isAjusteRealizado && _tipoAjusteController.text.isEmpty) {
      _showSnackBar(context, 'Ingrese el tipo de ajuste', isError: true);
      return false;
    }

    if (_isAjusteExterno && _cargasPesasController.text.isEmpty) {
      _showSnackBar(context, 'Ingrese las pesas de ajuste', isError: true);
      return false;
    }

    return true;
  }

  Map<String, Object?> _createRegistro() {
    final Map<String, Object?> registro = {};

    for (int i = 0; i < _precargasControllers.length; i++) {
      registro['precarga${i + 1}'] = _precargasControllers[i].text;
      registro['p_indicador${i + 1}'] = _indicacionesControllers[i].text;
    }

    for (int i = _precargasControllers.length; i < maxPreloads; i++) {
      registro['precarga${i + 1}'] = '';
      registro['p_indicador${i + 1}'] = '';
    }

    registro['ajuste'] = _isAjusteRealizado ? 'Sí' : 'No';
    registro['tipo'] = _tipoAjusteController.text;
    registro['cargas_pesas'] = _cargasPesasController.text;
    registro['hora'] = _horaController.text;
    registro['hri'] = _hriController.text;
    registro['ti'] = _tiController.text;
    registro['patmi'] = _patmiController.text;
    return registro;
  }

  void _onAjusteRealizadoChanged(String? value) {
    setState(() {
      _isAjusteRealizado = value == 'Sí';
      if (!_isAjusteRealizado) {
        _tipoAjusteController.text = 'NO APLICA';
        _cargasPesasController.text = 'NO APLICA';
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
        _cargasPesasController.text = 'NO APLICA';
      } else {
        _cargasPesasController.clear();
      }
    });
  }

  InputDecoration buildInputDecoration(
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

  Widget _buildDetailContainer(String label, String value, Color textColor, Color borderColor) {
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          Text(value, style: TextStyle(color: textColor)),
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
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null || now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(context, 'Presione nuevamente para retroceder. Los datos registrados se perderán.');
      return false;
    }
    return true;
  }

  Future<void> _saveComentarioToDatabase(BuildContext context, String comentario) async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);

      if (existingRecord == null) {
        _showSnackBar(context, 'No se encontró el registro para actualizar', isError: true);
        return;
      }

      final registro = {
        'seca': widget.secaValue,
        'observaciones': comentario.trim(),
      };

      await dbHelper.upsertRegistroCalibracion(registro);
      _showSnackBar(context, 'Comentario guardado correctamente');
    } catch (e, stackTrace) {
      _showSnackBar(context, 'Error al guardar el comentario: $e', isError: true);
      debugPrint('Error al guardar comentario: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  void _finalizarServicio(BuildContext context) {
    if (!_isDataSaved) {
      _showSnackBar(context, 'Debe guardar todos los campos para finalizar el servicio', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('CONFIRMACIÓN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Está seguro de finalizar el servicio? No se registrarán los datos de Excentricidad, Repetibilidad y Linealidad.'),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _comentarioController,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (máximo 300 caracteres)',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 300,
                    maxLines: 3,
                    onChanged: (value) => setModalState(() {}),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('No'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _comentarioController.text.trim().isEmpty || _comentarioController.text.trim().length > 300
                      ? null
                      : () async {
                    await _saveComentarioToDatabase(context, _comentarioController.text.trim());
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FinServicioScreen(
                            secaValue: widget.secaValue,
                            sessionId: widget.sessionId,
                                                  ),
                      ),
                    );
                  },
                  child: const Text('Sí'),
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
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

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
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 40,
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'INICIO DE PRUEBAS DE ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                            children: const <TextSpan>[
                              TextSpan(text: 'PRECARGAS DE AJUSTE', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Precargas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 20),
                      const Center(child: Text('REGISTRO DE AJUSTES', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        items: ['Sí', 'No'].map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        )).toList(),
                        onChanged: _onAjusteRealizadoChanged,
                        decoration: buildInputDecoration('¿Se Realizó el Ajuste?'),
                        validator: (value) => value == null ? 'Por favor seleccione una opción' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        items: ['INTERNO', 'EXTERNO'].map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        )).toList(),
                        onChanged: _isAjusteRealizado ? _onTipoAjusteChanged : null,
                        decoration: buildInputDecoration('Tipo de Ajuste:'),
                        validator: (value) => _isAjusteRealizado && value == null ? 'Por favor seleccione una opción' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _cargasPesasController,
                        decoration: buildInputDecoration('Cargas / Pesas de Ajuste:'),
                        enabled: _isAjusteExterno,
                        validator: (value) => _isAjusteExterno && (value == null || value.isEmpty) ? 'Por favor ingrese un valor' : null,
                      ),
                      const SizedBox(height: 20),
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
                            decoration: buildInputDecoration(
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
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Haga clic en el icono del reloj para ingresar la hora. La hora se obtiene automáticamente del sistema, NO ES EDITABLE.',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
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
                        decoration: buildInputDecoration('HRi (%)', suffixText: '%'),
                        validator: (value) => value == null || value.isEmpty ? 'Por favor ingrese un valor' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _tiController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        decoration: buildInputDecoration('ti (°C)', suffixText: '°C'),
                        validator: (value) => value == null || value.isEmpty ? 'Por favor ingrese un valor' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patmiController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        decoration: buildInputDecoration('Patmi (hPa)', suffixText: 'hPa'),
                        validator: (value) => value == null || value.isEmpty ? 'Por favor ingrese un valor' : null,
                      ),
                      const SizedBox(height: 20.0),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _saveDataToDatabase(context),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3e7732)),
                                    child: const Text('1: GUARDAR DATOS'),
                                  ),
                                  const SizedBox(height: 8.0),
                                  const Text(
                                    'Guarde los datos para continuar con las prue bas de Excentricidad.',
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
                                              _showSnackBar(context, 'Debe guardar los datos antes de continuar', isError: true);
                                              return;
                                            }

                                            if (_formKey.currentState!.validate()) {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('CONFIRMACIÓN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                                                    content: const Text('¿Estás seguro de los datos registrados?, Empezaremos con las pruebas de Excentricidad.'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text('No'),
                                                        onPressed: () => Navigator.of(context).pop(),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => CalibrationFlowScreen(
                                                                selectedBalanza: const {},
                                                                codMetrica: widget.codMetrica,
                                                                secaValue: widget.secaValue,
                                                                sessionId: widget.sessionId,
                                                              ),
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
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007195)),
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
                      )
                    ],
                  ),
                ),
              ),
            ),
        floatingActionButton: ValueListenableBuilder<bool>(
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
              SpeedDialChild(
                child: const Icon(Icons.stop),
                backgroundColor: Colors.red,
                label: 'Cortar Servicio',
                onTap: () => _finalizarServicio(context),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                const Text('Información de la balanza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (balanza != null) ...[
                  _buildDetailContainer('Código Métrica', balanza.cod_metrica, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('Unidades', balanza.unidad.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax1', balanza.cap_max1, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d1', balanza.d1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e1', balanza.e1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec1', balanza.dec1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax2', balanza.cap_max2, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d2', balanza.d2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e2', balanza.e2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec2', balanza.dec2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax3', balanza.cap_max3, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d3', balanza.d3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e3', balanza.e3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec3', balanza.dec3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
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

        final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
        final dividerColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

        final Map<String, String> fieldLabels = {
          'reg_fecha': 'Fecha del Último Servicio',
          'reg_usuario': 'Técnico Responsable',
          'seca': 'Último SECA',
          'exc': 'Exc',
        };

        for (int i = 1; i <= 30; i++) fieldLabels['rep$i'] = 'rep $i';
        for (int i = 1; i <= 60; i++) fieldLabels['lin$i'] = 'lin $i';

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
                    .where((entry) => entry.value != null && fieldLabels.containsKey(entry.key))
                    .map((entry) => _buildEditableDetailContainer(
                  fieldLabels[entry.key]!,
                  entry.key == 'reg_fecha'
                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.value))
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

  Widget _buildEditableDetailContainer(String label, String value, Color textColor, Color borderColor) {
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          Text(value, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}