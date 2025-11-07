import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stil_model.dart';
import '../utils/constants.dart';

class ExcentricidadWidget extends StatefulWidget {
  final Excentricidad excentricidad;
  final Future<double> Function() getD1FromDatabase;
  final Function onChanged;

  const ExcentricidadWidget({
    Key? key,
    required this.excentricidad,
    required this.getD1FromDatabase,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ExcentricidadWidgetState createState() => _ExcentricidadWidgetState();
}

class _ExcentricidadWidgetState extends State<ExcentricidadWidget> {
  final List<TextEditingController> _positionControllers = [];
  final List<TextEditingController> _indicationControllers = [];
  final List<TextEditingController> _returnControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _positionControllers.clear();
    _indicationControllers.clear();
    _returnControllers.clear();

    for (var posicion in widget.excentricidad.posiciones) {
      _positionControllers.add(TextEditingController(text: posicion.posicion));
      _indicationControllers.add(TextEditingController(text: posicion.indicacion));
      _returnControllers.add(TextEditingController(text: posicion.retorno));
    }
  }

  void _updatePositions() {
    if (widget.excentricidad.puntosIndicador == null) return;

    int numberOfPositions = _getNumberOfPositions(widget.excentricidad.puntosIndicador!);

    widget.excentricidad.posiciones.clear();
    _initializeControllers();

    for (int i = 0; i < numberOfPositions; i++) {
      widget.excentricidad.posiciones.add(PosicionExcentricidad(
        posicion: (i + 1).toString(),
        indicacion: widget.excentricidad.carga,
        retorno: '0',
      ));

      _positionControllers.add(TextEditingController(text: (i + 1).toString()));
      _indicationControllers.add(TextEditingController(text: widget.excentricidad.carga));
      _returnControllers.add(TextEditingController(text: '0'));
    }

    widget.onChanged();
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
        const SizedBox(height: 20),
        const Text(
          'INFORMACIÓN DE PLATAFORMA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: widget.excentricidad.tipoPlataforma,
          decoration: _buildInputDecoration('Tipo de Plataforma'),
          items: AppConstants.platformOptions.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              widget.excentricidad.tipoPlataforma = newValue;
              widget.excentricidad.puntosIndicador = null;
              widget.excentricidad.imagenPath = null;
              _updatePositions();
            });
          },
        ),
        const SizedBox(height: 20),
        if (widget.excentricidad.tipoPlataforma != null)
          DropdownButtonFormField<String>(
            value: widget.excentricidad.puntosIndicador,
            decoration: _buildInputDecoration('Puntos e Indicador'),
            items: AppConstants.platformOptions[widget.excentricidad.tipoPlataforma]!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                widget.excentricidad.puntosIndicador = newValue;
                widget.excentricidad.imagenPath = AppConstants.optionImages[newValue!];
                _updatePositions();
              });
            },
          ),
        const SizedBox(height: 20),
        if (widget.excentricidad.imagenPath != null)
          Image.asset(widget.excentricidad.imagenPath!),
        const SizedBox(height: 20),
        TextFormField(
          onChanged: (value) {
            widget.excentricidad.carga = value;
            // Actualizar indicaciones
            for (int i = 0; i < _indicationControllers.length; i++) {
              _indicationControllers[i].text = value;
              widget.excentricidad.posiciones[i].indicacion = value;
            }
            widget.onChanged();
          },
          decoration: _buildInputDecoration('Carga'),
          keyboardType: TextInputType.number,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.excentricidad.posiciones.length,
          itemBuilder: (context, index) {
            return _buildPositionRow(index);
          },
        ),
      ],
    );
  }

  Widget _buildPositionRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Posición como texto
          Text(
            'Posición ${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _indicationControllers[index],
                  decoration: _buildInputDecoration(
                    'Indicación',
                    suffixIcon: FutureBuilder<double>(
                      future: widget.getD1FromDatabase(),
                      builder: (context, snapshot) {
                        // Mostrar loader mientras carga
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        // Manejar errores
                        if (snapshot.hasError) {
                          return const Tooltip(
                            message: 'Error al cargar d1',
                            child: Icon(Icons.error_outline, color: Colors.red),
                          );
                        }
                        // Obtener d1 o usar valor por defecto
                        final d1 = snapshot.data ?? 0.1;

                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (String newValue) {
                            setState(() {
                              _indicationControllers[index].text = newValue;
                              widget.excentricidad.posiciones[index].indicacion = newValue;
                              widget.onChanged();
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            final currentText = _indicationControllers[index].text.trim();

                            // Si está vacío, usa la carga como base
                            final baseValue = double.tryParse(
                              (currentText.isEmpty
                                  ? widget.excentricidad.carga
                                  : currentText).replaceAll(',', '.'),
                            ) ?? 0.0;

                            // Generar 11 opciones (5 abajo, actual, 5 arriba)
                            return List.generate(11, (i) {
                              final value = baseValue + ((i - 5) * d1);
                              final txt = value.toStringAsFixed(1); // 1 decimal
                              return PopupMenuItem<String>(
                                value: txt,
                                child: Text(txt),
                              );
                            });
                          },
                        );
                      },
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    widget.excentricidad.posiciones[index].indicacion = value;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _returnControllers[index],
                  decoration: _buildInputDecoration('Retorno'),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    widget.excentricidad.posiciones[index].retorno = value;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
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
}