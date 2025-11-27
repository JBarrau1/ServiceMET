import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../provider/balanza_provider.dart';
import '../services/calibration_service.dart';

class EccentricityTest extends StatefulWidget {
  final CalibrationService calibrationService;
  final ValueNotifier<bool> isDataSaved;

  const EccentricityTest({
    super.key,
    required this.calibrationService,
    required this.isDataSaved,
  });

  @override
  _EccentricityTestState createState() => _EccentricityTestState();
}

class _EccentricityTestState extends State<EccentricityTest> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cargaController = TextEditingController();
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _oneThirdPmax1Controller =
      TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();

  String? _selectedPlatform;
  String? _selectedOption;
  String? _selectedImagePath;

  List<TextEditingController> _positionControllers = [];
  List<TextEditingController> _indicationControllers = [];
  List<TextEditingController> _returnControllers = [];

  final Map<String, List<String>> _platformOptions = {
    'Rectangular': [
      'Rectangular 3D',
      'Rectangular 3I',
      'Rectangular 3F',
      'Rectangular 3A',
      'Rectangular 5D',
      'Rectangular 5I',
      'Rectangular 5F',
      'Rectangular 5A'
    ],
    'Circular': [
      'Circular 5D',
      'Circular 5I',
      'Circular 5F',
      'Circular 5A',
      'Circular 4D',
      'Circular 4I',
      'Circular 4F',
      'Circular 4A'
    ],
    'Cuadrada': ['Cuadrada D', 'Cuadrada I', 'Cuadrada F', 'Cuadrada A'],
    'Triangular': [
      'Triangular I',
      'Triangular F',
      'Triangular A',
      'Triangular D'
    ],
  };

  final Map<String, String> _optionImages = {
    'Rectangular 3D': 'images/Rectangular_3D.png',
    'Rectangular 3I': 'images/Rectangular_3I.png',
    'Rectangular 3F': 'images/Rectangular_3F.png',
    'Rectangular 3A': 'images/Rectangular_3A.png',
    'Rectangular 5D': 'images/Rectangular_5D.png',
    'Rectangular 5I': 'images/Rectangular_5I.png',
    'Rectangular 5F': 'images/Rectangular_5F.png',
    'Rectangular 5A': 'images/Rectangular_5A.png',
    'Circular 5D': 'images/Circular_5D.png',
    'Circular 5I': 'images/Circular_5I.png',
    'Circular 5F': 'images/Circular_5F.png',
    'Circular 5A': 'images/Circular_5A.png',
    'Circular 4D': 'images/Circular_4D.png',
    'Circular 4I': 'images/Circular_4I.png',
    'Circular 4F': 'images/Circular_4F.png',
    'Circular 4A': 'images/Circular_4A.png',
    'Cuadrada D': 'images/Cuadrada_D.png',
    'Cuadrada I': 'images/Cuadrada_I.png',
    'Cuadrada F': 'images/Cuadrada_F.png',
    'Cuadrada A': 'images/Cuadrada_A.png',
    'Triangular I': 'images/Triangular_I.png',
    'Triangular F': 'images/Triangular_F.png',
    'Triangular A': 'images/Triangular_A.png',
    'Triangular D': 'images/Triangular_D.png',
  };

  @override
  void initState() {
    super.initState();
    _loadPmax1Data();
  }

  Future<void> _loadPmax1Data() async {
    final pmax1 = await widget.calibrationService.getPmax1Value();
    final oneThirdPmax1 = pmax1 / 3;

    setState(() {
      _pmax1Controller.text = pmax1.toStringAsFixed(2);
      _oneThirdPmax1Controller.text = oneThirdPmax1.toStringAsFixed(2);
    });
  }

  void _updatePositions() {
    if (_selectedOption == null) return;

    int numberOfPositions = _getNumberOfPositions(_selectedOption!);
    _positionControllers = [];
    _indicationControllers = [];
    _returnControllers = [];

    for (int i = 0; i < numberOfPositions; i++) {
      _positionControllers.add(TextEditingController(text: (i + 1).toString()));
      _indicationControllers.add(TextEditingController());
      _returnControllers.add(TextEditingController(text: '0'));
    }

    setState(() {});
  }

  int _getNumberOfPositions(String platform) {
    if (platform.contains('3')) return 3;
    if (platform.contains('4')) return 4;
    if (platform.contains('5')) return 5;
    if (platform.startsWith('Cuadrada')) return 5;
    if (platform.startsWith('Triangular')) return 4;
    return 0;
  }

  Future<void> _saveDataToDatabase() async {
    if (_selectedPlatform == null || _selectedPlatform!.isEmpty) {
      _showSnackBar('Seleccione el tipo de plataforma', isError: true);
      return;
    }

    if (_selectedOption == null || _selectedOption!.isEmpty) {
      _showSnackBar('Seleccione los puntos e indicación', isError: true);
      return;
    }

    if (_cargaController.text.isEmpty) {
      _showSnackBar('Ingrese la carga', isError: true);
      return;
    }

    for (int i = 0; i < _positionControllers.length; i++) {
      if (_positionControllers[i].text.isEmpty) {
        _showSnackBar('Ingrese la posición ${i + 1}', isError: true);
        return;
      }
      if (_indicationControllers[i].text.isEmpty) {
        _showSnackBar('Por favor ingrese la indicación ${i + 1}',
            isError: true);
        return;
      }
      if (_returnControllers[i].text.isEmpty) {
        _showSnackBar('Por favor ingrese el retorno ${i + 1}', isError: true);
        return;
      }
    }

    try {
      final registro = {
        'tipo_plataforma': _selectedPlatform ?? '',
        'puntos_ind': _selectedOption ?? '',
        'carga': _cargaController.text,
        'posicion1':
            _positionControllers.isNotEmpty ? _positionControllers[0].text : '',
        'indicacion1': _indicationControllers.isNotEmpty
            ? _indicationControllers[0].text
            : '',
        'retorno1':
            _returnControllers.isNotEmpty ? _returnControllers[0].text : '',
        'posicion2':
            _positionControllers.length > 1 ? _positionControllers[1].text : '',
        'indicacion2': _indicationControllers.length > 1
            ? _indicationControllers[1].text
            : '',
        'retorno2':
            _returnControllers.length > 1 ? _returnControllers[1].text : '',
        'posicion3':
            _positionControllers.length > 2 ? _positionControllers[2].text : '',
        'indicacion3': _indicationControllers.length > 2
            ? _indicationControllers[2].text
            : '',
        'retorno3':
            _returnControllers.length > 2 ? _returnControllers[2].text : '',
        'posicion4':
            _positionControllers.length > 3 ? _positionControllers[3].text : '',
        'indicacion4': _indicationControllers.length > 3
            ? _indicationControllers[3].text
            : '',
        'retorno4':
            _returnControllers.length > 3 ? _returnControllers[3].text : '',
        'posicion5':
            _positionControllers.length > 4 ? _positionControllers[4].text : '',
        'indicacion5': _indicationControllers.length > 4
            ? _indicationControllers[4].text
            : '',
        'retorno5':
            _returnControllers.length > 4 ? _returnControllers[4].text : '',
        'posicion6':
            _positionControllers.length > 5 ? _positionControllers[5].text : '',
        'indicacion6': _indicationControllers.length > 5
            ? _indicationControllers[5].text
            : '',
        'retorno6':
            _returnControllers.length > 5 ? _returnControllers[5].text : '',
        'observaciones': _comentarioController.text.trim(),
      };

      await widget.calibrationService.saveEccentricityData(registro);

      widget.isDataSaved.value = true;
      _showSnackBar('Datos y respaldo guardado correctamente');
    } catch (e) {
      _showSnackBar('Error al guardar datos: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + 140,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'PRUEBAS DE ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                children: const <TextSpan>[
                  TextSpan(
                    text: 'EXCENTRICIDAD',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '1. TIPO DE PLATAFORMA',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              decoration:
                  _buildInputDecoration('Selecciona el tipo de plataforma'),
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
                });
              },
              initialValue: _selectedPlatform,
            ),
            const SizedBox(height: 10.0),
            if (_selectedPlatform != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Puntos e Indicador'),
                  items:
                      _platformOptions[_selectedPlatform]!.map((String value) {
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
                  initialValue: _selectedOption,
                ),
              ),
            if (_selectedImagePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Image.asset(_selectedImagePath!),
              ),
            const SizedBox(height: 20.0),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '2. REGISTRO DE DATOS DE EXCENTRICIDAD',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pmax1Controller,
                      decoration: _buildInputDecoration('pmax1').copyWith(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.yellow),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TextFormField(
                      controller: _oneThirdPmax1Controller,
                      decoration:
                          _buildInputDecoration('1/3 de cap_max1').copyWith(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.lightGreen),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'En el campo 1/3 de pmax1 puede visualizar el cálculo. El dato que aparece ahí es una sugerencia al peso que debería usar para la prueba.',
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
            const SizedBox(width: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                controller: _cargaController,
                decoration: _buildInputDecoration('Carga'),
                onChanged: (value) {
                  final doubleValue = double.tryParse(value);
                  if (doubleValue != null) {
                    for (int i = 0; i < _indicationControllers.length; i++) {
                      _indicationControllers[i].text = value;
                    }
                  }
                },
                style: TextStyle(
                  color: (_cargaController.text.isNotEmpty &&
                          double.tryParse(_cargaController.text) != null &&
                          double.parse(_cargaController.text) <
                              double.parse(_oneThirdPmax1Controller.text))
                      ? Colors.red
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _positionControllers.length,
              itemBuilder: (context, index) {
                return Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _positionControllers[index],
                                decoration: _buildInputDecoration(
                                    'Posición ${index + 1}'),
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
                                        future: widget.calibrationService
                                            .getD1Value(),
                                        builder: (context, snapshot) {
                                          final d1 = balanza?.d1 ??
                                              snapshot.data ??
                                              0.1;

                                          int getSignificantDecimals(
                                              double value) {
                                            String text = value.toString();
                                            if (text.contains('.')) {
                                              return text
                                                  .split('.')[1]
                                                  .replaceAll(
                                                      RegExp(r'0*$'), '')
                                                  .length;
                                            }
                                            return 0;
                                          }

                                          final decimalPlaces =
                                              getSignificantDecimals(d1);

                                          return PopupMenuButton<String>(
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            onSelected: (String newValue) {
                                              setState(() {
                                                _indicationControllers[index]
                                                    .text = newValue;
                                              });
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              final baseValue = double.tryParse(
                                                      _indicationControllers[
                                                              index]
                                                          .text) ??
                                                  0.0;
                                              List<String> options = [
                                                for (int i = 5; i >= 1; i--)
                                                  (baseValue + (i * d1))
                                                      .toStringAsFixed(
                                                          decimalPlaces),
                                                baseValue.toStringAsFixed(
                                                    decimalPlaces),
                                                for (int i = 1; i <= 5; i++)
                                                  (baseValue - (i * d1))
                                                      .toStringAsFixed(
                                                          decimalPlaces),
                                              ];
                                              return options
                                                  .map((value) =>
                                                      PopupMenuItem<String>(
                                                        value: value,
                                                        child: Text(value),
                                                      ))
                                                  .toList();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'))
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'))
                                    ],
                                    controller: _returnControllers[index],
                                    decoration:
                                        _buildInputDecoration('Retorno'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _saveDataToDatabase,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3e7732)),
              child: const Text('GUARDAR DATOS'),
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder<bool>(
              valueListenable: widget.isDataSaved,
              builder: (context, isSaved, child) {
                return Text(
                  isSaved
                      ? 'Datos de excentricidad guardados correctamente'
                      : 'Guarde los datos para continuar con las pruebas',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: isSaved ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
