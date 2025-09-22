// widgets/precargas_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';
import '../servicio_controller.dart';


class PrecargasStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;

  const PrecargasStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
  }) : super(key: key);

  @override
  State<PrecargasStep> createState() => _PrecargasStepState();
}

class _PrecargasStepState extends State<PrecargasStep> {
  final List<TextEditingController> _precargasControllers = [];
  final List<TextEditingController> _indicacionesControllers = [];
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _hriController = TextEditingController();
  final TextEditingController _tiController = TextEditingController();
  final TextEditingController _patmiController = TextEditingController();

  String _ajusteRealizado = '';
  String _tipoAjuste = '';
  bool _isAjusteExterno = false;
  final TextEditingController _cargasPesasController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final controller = Provider.of<ServicioController>(context, listen: false);
    final rowCount = controller.precargas.length;

    for (int i = 0; i < rowCount; i++) {
      _precargasControllers.add(TextEditingController(
          text: controller.precargas[i]['precarga'] ?? ''
      ));
      _indicacionesControllers.add(TextEditingController(
          text: controller.precargas[i]['indicacion'] ?? ''
      ));
    }
  }

  @override
  void dispose() {
    _precargasControllers.forEach((c) => c.dispose());
    _indicacionesControllers.forEach((c) => c.dispose());
    _horaController.dispose();
    _hriController.dispose();
    _tiController.dispose();
    _patmiController.dispose();
    _cargasPesasController.dispose();
    super.dispose();
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
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Sección de precargas
            _buildPrecargasSection(controller),

            const SizedBox(height: 30),

            // Registro de ajustes
            _buildAjustesSection(controller),

            const SizedBox(height: 30),

            // Condiciones ambientales iniciales
            _buildCondicionesAmbientalesSection(controller),

            const SizedBox(height: 30),

            // Botón para guardar
            _buildSaveButton(controller),
          ],
        );
      },
    );
  }

  Widget _buildPrecargasSection(ServicioController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Precargas:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (controller.precargas.length < 6) {
                      controller.addPrecarga();
                      _precargasControllers.add(TextEditingController());
                      _indicacionesControllers.add(TextEditingController());
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pueden agregar más de 6 precargas.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (controller.precargas.length > 5) {
                      controller.removePrecarga();
                      _precargasControllers.removeLast().dispose();
                      _indicacionesControllers.removeLast().dispose();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.precargas.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    '${index + 1}.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _precargasControllers[index],
                      decoration: _buildInputDecoration('Precarga'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) {
                        controller.updatePrecarga(index, value, _indicacionesControllers[index].text);
                        setState(() {
                          _indicacionesControllers[index].text = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FutureBuilder<double>(
                      future: controller.getD1FromDatabase(),
                      builder: (context, snapshot) {
                        final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
                        final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                        int getDecimalPlaces(double value) {
                          String text = value.toString();
                          if (text.contains('.')) {
                            String decimalPart = text.split('.')[1].replaceAll(RegExp(r'0*$'), '');
                            return decimalPart.length;
                          }
                          return 0;
                        }

                        final decimalPlaces = getDecimalPlaces(d1);

                        return TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          controller: _indicacionesControllers[index],
                          decoration: _buildInputDecoration(
                            'Indicación',
                            suffixIcon: PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (String newValue) {
                                setState(() {
                                  _indicacionesControllers[index].text = newValue;
                                });
                                controller.updatePrecarga(index, _precargasControllers[index].text, newValue);
                              },
                              itemBuilder: (BuildContext context) {
                                final baseValue = double.tryParse(_indicacionesControllers[index].text) ?? 0.0;

                                List<double> allValues = [];

                                for (int i = 5; i >= 1; i--) {
                                  allValues.add(baseValue + (i * d1));
                                }

                                allValues.add(baseValue);

                                for (int i = 1; i <= 5; i++) {
                                  allValues.add(baseValue - (i * d1));
                                }

                                List<String> options = allValues.map((value) =>
                                    value.toStringAsFixed(decimalPlaces)).toList();

                                return options.map((String value) {
                                  return PopupMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          onChanged: (value) {
                            controller.updatePrecarga(index, _precargasControllers[index].text, value);
                          },
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
          },
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3);
  }

  Widget _buildAjustesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'REGISTRO DE AJUSTES',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _ajusteRealizado.isEmpty ? null : _ajusteRealizado, // CAMBIO IMPORTANTE
          items: ['Sí', 'No'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _ajusteRealizado = newValue ?? '';
              if (newValue == 'No') {
                _tipoAjuste = ''; // CAMBIO: Vacío en lugar de 'NO APLICA'
                _cargasPesasController.text = ''; // CAMBIO: Vacío en lugar de 'NO APLICA'
                _isAjusteExterno = false;
              } else if (newValue == 'Sí') {
                _tipoAjuste = ''; // Reiniciar cuando se selecciona Sí
              }
            });

            controller.setAjusteData({
              'ajuste': _ajusteRealizado,
              'tipo': _tipoAjuste,
              'cargas_pesas': _cargasPesasController.text,
            });
          },
          decoration: _buildInputDecoration('¿Se Realizó el Ajuste?'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione una opción';
            }
            return null;
          },
        ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _tipoAjuste.isEmpty ? null : _tipoAjuste, // CAMBIO IMPORTANTE
          items: ['INTERNO', 'EXTERNO'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: _ajusteRealizado == 'Sí' ? (String? newValue) {
            setState(() {
              _tipoAjuste = newValue ?? '';
              _isAjusteExterno = newValue == 'EXTERNO';
              if (!_isAjusteExterno) {
                _cargasPesasController.text = ''; // CAMBIO: Vacío en lugar de 'NO APLICA'
              } else {
                _cargasPesasController.clear();
              }
            });

            controller.setAjusteData({
              'ajuste': _ajusteRealizado,
              'tipo': _tipoAjuste,
              'cargas_pesas': _cargasPesasController.text,
            });
          } : null,
          decoration: _buildInputDecoration('Tipo de Ajuste:'),
          validator: (value) {
            if (_ajusteRealizado == 'Sí' && (value == null || value.isEmpty)) {
              return 'Por favor seleccione una opción';
            }
            return null;
          },
        ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _cargasPesasController,
          decoration: _buildInputDecoration('Cargas / Pesas de Ajuste:'),
          enabled: _isAjusteExterno,
          onChanged: (value) {
            controller.setAjusteData({
              'ajuste': _ajusteRealizado,
              'tipo': _tipoAjuste,
              'cargas_pesas': value,
            });
          },
          validator: (value) {
            if (_isAjusteExterno && (value == null || value.isEmpty)) {
              return 'Por favor ingrese un valor';
            }
            return null;
          },
        ).animate(delay: 600.ms).fadeIn().slideX(begin: 0.3),
      ],
    );
  }

  Widget _buildCondicionesAmbientalesSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          'REGISTRO DE CONDICIONES AMBIENTALES INICIALES',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 700.ms).fadeIn().slideY(begin: -0.3),

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
                  onPressed: () {
                    final now = DateTime.now();
                    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
                        '${now.minute.toString().padLeft(2, '0')}:'
                        '${now.second.toString().padLeft(2, '0')}';
                    _horaController.text = formattedTime;
                  },
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
        ).animate(delay: 800.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _hriController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _buildInputDecoration('HRi (%)', suffixText: '%'),
          onChanged: (value) {
            controller.setCondicionesAmbientales({
              'hora': _horaController.text,
              'hri': value,
              'ti': _tiController.text,
              'patmi': _patmiController.text,
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un valor';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor ingrese un número válido';
            }
            return null;
          },
        ).animate(delay: 900.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _tiController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _buildInputDecoration('ti (°C)', suffixText: '°C'),
          onChanged: (value) {
            controller.setCondicionesAmbientales({
              'hora': _horaController.text,
              'hri': _hriController.text,
              'ti': value,
              'patmi': _patmiController.text,
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un valor';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor ingrese un número válido';
            }
            return null;
          },
        ).animate(delay: 1000.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _patmiController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _buildInputDecoration('Patmi (hPa)', suffixText: 'hPa'),
          onChanged: (value) {
            controller.setCondicionesAmbientales({
              'hora': _horaController.text,
              'hri': _hriController.text,
              'ti': _tiController.text,
              'patmi': value,
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un valor';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor ingrese un número válido';
            }
            return null;
          },
        ).animate(delay: 1100.ms).fadeIn().slideX(begin: 0.3),
      ],
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
          'GUARDAR PRECARGAS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.3);
  }

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }
}