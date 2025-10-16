import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stil_model.dart';

class RepetibilidadWidget extends StatefulWidget {
  final Repetibilidad repetibilidad;
  final Future<double> Function() getD1FromDatabase;
  final Function onChanged;

  const RepetibilidadWidget({
    Key? key,
    required this.repetibilidad,
    required this.getD1FromDatabase,
    required this.onChanged,
  }) : super(key: key);

  @override
  _RepetibilidadWidgetState createState() => _RepetibilidadWidgetState();
}

class _RepetibilidadWidgetState extends State<RepetibilidadWidget> {
  final List<List<TextEditingController>> _indicacionControllers = [];
  final List<List<TextEditingController>> _retornoControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _indicacionControllers.clear();
    _retornoControllers.clear();

    for (var carga in widget.repetibilidad.cargas) {
      List<TextEditingController> indicacionControllers = [];
      List<TextEditingController> retornoControllers = [];

      for (var prueba in carga.pruebas) {
        indicacionControllers.add(TextEditingController(text: prueba.indicacion));
        retornoControllers.add(TextEditingController(text: prueba.retorno));
      }

      _indicacionControllers.add(indicacionControllers);
      _retornoControllers.add(retornoControllers);
    }
  }

  void _updateCantidadCargas(int newCount) {
    if (newCount > widget.repetibilidad.cargas.length) {
      // Agregar nuevas cargas
      for (int i = widget.repetibilidad.cargas.length; i < newCount; i++) {
        widget.repetibilidad.cargas.add(CargaRepetibilidad());
      }
    } else {
      // Remover cargas excedentes
      widget.repetibilidad.cargas = widget.repetibilidad.cargas.sublist(0, newCount);
    }
    _initializeControllers();
    widget.onChanged();
    setState(() {});
  }

  void _updateCantidadPruebas(int newCount) {
    for (var carga in widget.repetibilidad.cargas) {
      if (newCount > carga.pruebas.length) {
        // Agregar nuevas pruebas
        for (int i = carga.pruebas.length; i < newCount; i++) {
          carga.pruebas.add(PruebaRepetibilidad());
        }
      } else {
        // Remover pruebas excedentes
        carga.pruebas = carga.pruebas.sublist(0, newCount);
      }
    }
    _initializeControllers();
    widget.onChanged();
    setState(() {});
  }

  void _updateIndicacionValues(int cargaIndex, String value) {
    if (value.isEmpty) return;
    for (var prueba in widget.repetibilidad.cargas[cargaIndex].pruebas) {
      prueba.indicacion = value;
    }
    for (var controller in _indicacionControllers[cargaIndex]) {
      controller.text = value;
    }
    widget.onChanged();
    setState(() {});
  }

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          value: widget.repetibilidad.cantidadCargas,
          items: [1, 2, 3].map((int value) => DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                widget.repetibilidad.cantidadCargas = value;
                _updateCantidadCargas(value);
              });
            }
          },
          decoration: _buildInputDecoration('Cantidad de Cargas'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: widget.repetibilidad.cantidadPruebas,
          items: [3, 5, 10].map((int value) => DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                widget.repetibilidad.cantidadPruebas = value;
                _updateCantidadPruebas(value);
              });
            }
          },
          decoration: _buildInputDecoration('Cantidad de Pruebas'),
        ),
        const SizedBox(height: 20),
        ..._buildCargas(),
      ],
    );
  }

  List<Widget> _buildCargas() {
    List<Widget> widgets = [];

    for (int cargaIndex = 0; cargaIndex < widget.repetibilidad.cargas.length; cargaIndex++) {
      widgets.addAll([
        Text(
          'CARGA ${cargaIndex + 1}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (value) {
            widget.repetibilidad.cargas[cargaIndex].valor = value;
            _updateIndicacionValues(cargaIndex, value);
          },
          decoration: _buildInputDecoration('Carga ${cargaIndex + 1}'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        ..._buildPruebas(cargaIndex),
        const SizedBox(height: 20),
      ]);
    }

    return widgets;
  }

  List<Widget> _buildPruebas(int cargaIndex) {
    List<Widget> widgets = [];

    for (int pruebaIndex = 0; pruebaIndex < widget.repetibilidad.cantidadPruebas; pruebaIndex++) {
      widgets.add(
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<double>(
                    future: widget.getD1FromDatabase(),
                    builder: (context, snapshot) {
                      final d1 = snapshot.data ?? 0.1;
                      return TextFormField(
                        controller: _indicacionControllers[cargaIndex][pruebaIndex],
                        decoration: _buildInputDecoration('Indicación ${pruebaIndex + 1}').copyWith(
                          suffixIcon: PopupMenuButton<String>(
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (String newValue) {
                              setState(() {
                                _indicacionControllers[cargaIndex][pruebaIndex].text = newValue;
                                widget.repetibilidad.cargas[cargaIndex].pruebas[pruebaIndex].indicacion = newValue;
                                widget.onChanged();
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              final baseValue = double.tryParse(
                                  _indicacionControllers[cargaIndex][pruebaIndex].text) ??
                                  0.0;
                              return List.generate(11, (index) {
                                final multiplier = index - 5;
                                final value = baseValue + (multiplier * d1);
                                return PopupMenuItem<String>(
                                  value: value.toStringAsFixed(1),
                                  child: Text(value.toStringAsFixed(1)),
                                );
                              });
                            },
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          widget.repetibilidad.cargas[cargaIndex].pruebas[pruebaIndex].indicacion = value;
                          widget.onChanged();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _retornoControllers[cargaIndex][pruebaIndex],
                    decoration: _buildInputDecoration('Retorno ${pruebaIndex + 1}'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      widget.repetibilidad.cargas[cargaIndex].pruebas[pruebaIndex].retorno = value;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    return widgets;
  }

  @override
  void dispose() {
    for (var controllers in _indicacionControllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controllers in _retornoControllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}