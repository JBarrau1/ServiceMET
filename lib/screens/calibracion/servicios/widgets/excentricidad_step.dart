// widgets/excentricidad_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../provider/balanza_provider.dart';
import '../servicio_controller.dart';

class ExcentricidadStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;

  const ExcentricidadStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
  }) : super(key: key);

  @override
  State<ExcentricidadStep> createState() => _ExcentricidadStepState();
}

class _ExcentricidadStepState extends State<ExcentricidadStep> {
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _oneThirdPmax1Controller =
      TextEditingController();
  final TextEditingController _cargaController = TextEditingController();

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

  double? _oneThirdpmax1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPmax1Data();
    });
  }

  @override
  void dispose() {
    _pmax1Controller.dispose();
    _oneThirdPmax1Controller.dispose();
    _cargaController.dispose();
    super.dispose();
  }

  Future<void> _fetchPmax1Data() async {
    final balanza =
        Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    if (balanza != null) {
      final pmax1 = double.tryParse(balanza.cap_max1) ?? 0.0;
      final oneThirdPmax1 = pmax1 / 3;
      setState(() {
        _pmax1Controller.text = pmax1.toStringAsFixed(2);
        _oneThirdPmax1Controller.text = oneThirdPmax1.toStringAsFixed(2);
        _oneThirdpmax1 = oneThirdPmax1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicioController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
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
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Sección de tipo de plataforma
            _buildPlataformaSection(controller),

            const SizedBox(height: 30),

            // Sección de datos de excentricidad
            _buildDatosExcentricidadSection(controller),

            const SizedBox(height: 30),

            // Botón para guardar
            _buildSaveButton(controller),
          ],
        );
      },
    );
  }

  Widget _buildPlataformaSection(ServicioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. TIPO DE PLATAFORMA',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.3),
        const SizedBox(height: 20.0),
        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Selecciona el tipo de plataforma'),
          items: controller.plataformaOptions.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            controller.setSelectedPlataforma(newValue!);
          },
          value: controller.selectedPlataforma,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione una opción';
            }
            return null;
          },
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
        const SizedBox(height: 10.0),
        if (controller.selectedPlataforma != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: DropdownButtonFormField<String>(
              decoration: _buildInputDecoration('Puntos e Indicador'),
              items: controller
                  .plataformaOptions[controller.selectedPlataforma]!
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                controller.setSelectedOpcionExcentricidad(newValue!);
              },
              value: controller.selectedOpcionExcentricidad,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione una opción';
                }
                return null;
              },
            ),
          ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),
        if (controller.selectedOpcionExcentricidad != null &&
            _optionImages[controller.selectedOpcionExcentricidad!] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Image.asset(
                _optionImages[controller.selectedOpcionExcentricidad!]!),
          )
              .animate(delay: 500.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildDatosExcentricidadSection(ServicioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. REGISTRO DE DATOS DE EXCENTRICIDAD',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ).animate(delay: 600.ms).fadeIn().slideX(begin: -0.3),

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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
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
                  decoration: _buildInputDecoration('1/3 de cap_max1').copyWith(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
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
        ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.3),

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

        const SizedBox(height: 20.0),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: TextFormField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            controller: _cargaController,
            decoration: _buildInputDecoration('Carga'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un valor';
              }
              final doubleValue = double.tryParse(value);
              if (doubleValue == null) {
                return 'Por favor ingrese un número válido';
              }
              return null;
            },
            onChanged: (value) {
              controller.setCargaExcentricidad(value);

              // Verificar si es menor al 1/3 del pmax1
              final doubleValue = double.tryParse(value);
              if (doubleValue != null &&
                  _oneThirdpmax1 != null &&
                  doubleValue < _oneThirdpmax1!) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Está trabajando con un peso menor al 1/3 del pmax1 de la balanza (${_oneThirdpmax1!.toStringAsFixed(0)}).',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextStyle(
              color: (_cargaController.text.isNotEmpty &&
                      double.tryParse(_cargaController.text) != null &&
                      _oneThirdpmax1 != null &&
                      double.parse(_cargaController.text) < _oneThirdpmax1!)
                  ? Colors.red
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ).animate(delay: 800.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20.0),

        // Lista de posiciones dinámicas
        if (controller.posicionesExcentricidad.isNotEmpty)
          _buildPosicionesList(controller),
      ],
    );
  }

  Widget _buildPosicionesList(ServicioController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.posicionesExcentricidad.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: controller.posicionesExcentricidad[index]
                            ['posicion'],
                        decoration:
                            _buildInputDecoration('Posición ${index + 1}'),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          FutureBuilder<double>(
                            future: controller.getD1FromDatabase(),
                            builder: (context, snapshot) {
                              final balanza = Provider.of<BalanzaProvider>(
                                      context,
                                      listen: false)
                                  .selectedBalanza;
                              final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                              int getSignificantDecimals(double value) {
                                final text = value.toString();
                                if (text.contains('.')) {
                                  return text
                                      .split('.')[1]
                                      .replaceAll(RegExp(r'0+$'), '')
                                      .length;
                                }
                                return 0;
                              }

                              final decimalPlaces = getSignificantDecimals(d1);

                              return TextFormField(
                                initialValue:
                                    controller.posicionesExcentricidad[index]
                                        ['indicacion'],
                                decoration: _buildInputDecoration(
                                  'Indicación',
                                  suffixIcon: PopupMenuButton<String>(
                                    icon: const Icon(Icons.arrow_drop_down),
                                    onSelected: (String newValue) {
                                      controller.updatePosicionExcentricidad(
                                          index, 'indicacion', newValue);
                                    },
                                    itemBuilder: (BuildContext context) {
                                      final baseValue = double.tryParse(
                                              controller.posicionesExcentricidad[
                                                      index]['indicacion'] ??
                                                  '') ??
                                          0.0;

                                      return List.generate(11, (i) {
                                        final multiplier = i - 5;
                                        final value =
                                            baseValue + (multiplier * d1);
                                        final formattedValue = value
                                            .toStringAsFixed(decimalPlaces);

                                        return PopupMenuItem<String>(
                                          value: formattedValue,
                                          child: Text(formattedValue),
                                        );
                                      });
                                    },
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                ],
                                onChanged: (value) {
                                  controller.updatePosicionExcentricidad(
                                      index, 'indicacion', value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Ingrese un valor';
                                  if (double.tryParse(value) == null)
                                    return 'Número inválido';
                                  return null;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            initialValue: controller
                                .posicionesExcentricidad[index]['retorno'],
                            decoration: _buildInputDecoration('Retorno'),
                            onChanged: (value) {
                              controller.updatePosicionExcentricidad(
                                  index, 'retorno', value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Ingrese un valor';
                              if (double.tryParse(value) == null)
                                return 'Número inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(delay: (900 + (index * 100)).ms)
            .fadeIn()
            .slideX(begin: index % 2 == 0 ? -0.3 : 0.3);
      },
    );
  }

  Widget _buildSaveButton(ServicioController controller) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await controller.saveCurrentStepData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Datos guardados correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'GUARDAR EXCENTRICIDAD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.3);
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
