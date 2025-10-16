import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stil_model.dart';
import 'excentricidad_widget.dart';
import 'repetibilidad_widget.dart';
import 'linealidad_widget.dart';

class PruebasMetrologicasWidget extends StatefulWidget {
  final PruebasMetrologicas pruebas;
  final bool isInicial;
  final Function onChanged;
  final Future<double> Function() getD1FromDatabase;

  const PruebasMetrologicasWidget({
    Key? key,
    required this.pruebas,
    required this.isInicial,
    required this.onChanged,
    required this.getD1FromDatabase,
  }) : super(key: key);

  @override
  _PruebasMetrologicasWidgetState createState() => _PruebasMetrologicasWidgetState();
}

class _PruebasMetrologicasWidgetState extends State<PruebasMetrologicasWidget> {
  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildRetornoCero() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: widget.pruebas.retornoCero.estado,
            decoration: _buildInputDecoration(
              'Retorno a cero ${widget.isInicial ? 'inicial' : ''}',
            ),
            items: ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'].map((String value) {
              Color textColor;
              Icon? icon;
              switch (value) {
                case '1 Bueno':
                  textColor = Colors.green;
                  icon = const Icon(Icons.check_circle, color: Colors.green);
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
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.pruebas.retornoCero.estado = value;
                  widget.onChanged();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          flex: 1,
          child: TextFormField(
            onChanged: (value) {
              widget.pruebas.retornoCero.valor = value;
              widget.onChanged();
            },
            decoration: _buildInputDecoration(
              'Carga de Prueba ${widget.isInicial ? 'Inicial' : ''}',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.pruebas.retornoCero.unidad,
                    items: ['kg', 'g'].map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(unit),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          widget.pruebas.retornoCero.unidad = newValue;
                          widget.onChanged();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PRUEBAS METROLÓGICAS ${widget.isInicial ? 'INICIALES' : 'FINALES'}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFDECD00),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),
        _buildRetornoCero(),
        const SizedBox(height: 20.0),

        // Excentricidad
        SwitchListTile(
          title: Text('PRUEBAS DE EXCENTRICIDAD ${widget.isInicial ? 'INICIAL' : 'FINAL'}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          value: widget.pruebas.excentricidad?.activo ?? false,
          onChanged: (bool value) {
            setState(() {
              if (value) {
                widget.pruebas.excentricidad = Excentricidad(activo: true);
              } else {
                widget.pruebas.excentricidad = null;
              }
              widget.onChanged();
            });
          },
        ),
        if (widget.pruebas.excentricidad != null)
          ExcentricidadWidget(
            excentricidad: widget.pruebas.excentricidad!,
            getD1FromDatabase: widget.getD1FromDatabase,
            onChanged: widget.onChanged,
          ),

        const SizedBox(height: 20.0),

        // Repetibilidad
        SwitchListTile(
          title: Text('PRUEBAS DE REPETIBILIDAD ${widget.isInicial ? 'INICIAL' : 'FINAL'}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          value: widget.pruebas.repetibilidad?.activo ?? false,
          onChanged: (bool value) {
            setState(() {
              if (value) {
                widget.pruebas.repetibilidad = Repetibilidad(activo: true);
              } else {
                widget.pruebas.repetibilidad = null;
              }
              widget.onChanged();
            });
          },
        ),
        if (widget.pruebas.repetibilidad != null)
          RepetibilidadWidget(
            repetibilidad: widget.pruebas.repetibilidad!,
            getD1FromDatabase: widget.getD1FromDatabase,
            onChanged: widget.onChanged,
          ),

        const SizedBox(height: 20.0),

        // Linealidad
        SwitchListTile(
          title: Text('PRUEBAS DE LINEALIDAD ${widget.isInicial ? 'INICIAL' : 'FINAL'}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          value: widget.pruebas.linealidad?.activo ?? false,
          onChanged: (bool value) {
            setState(() {
              if (value) {
                widget.pruebas.linealidad = Linealidad(activo: true);
              } else {
                widget.pruebas.linealidad = null;
              }
              widget.onChanged();
            });
          },
        ),
        if (widget.pruebas.linealidad != null)
          LinealidadWidget(
            linealidad: widget.pruebas.linealidad!,
            onChanged: widget.onChanged,
          ),
      ],
    );
  }
}