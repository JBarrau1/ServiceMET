import 'package:flutter/material.dart';
import '../models/relevamiento_de_datos_model.dart';
import 'excentricidad_widget.dart';
import 'repetibilidad_widget.dart';
import 'linealidad_widget.dart';

class PruebasMetrologicasWidget extends StatefulWidget {
  final PruebasMetrologicas pruebas;
  final Function onChanged;
  final Future<double> Function() getD1FromDatabase;

  const PruebasMetrologicasWidget({
    super.key,
    required this.pruebas,
    required this.onChanged,
    required this.getD1FromDatabase,
  });

  @override
  _PruebasMetrologicasWidgetState createState() =>
      _PruebasMetrologicasWidgetState();
}

class _PruebasMetrologicasWidgetState extends State<PruebasMetrologicasWidget> {
  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
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
        Text(
          'PRUEBAS METROLÓGICAS FINALES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFDECD00),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),

        // Retorno a Cero
        DropdownButtonFormField<String>(
          initialValue: widget.pruebas.retornoCero.estado,
          decoration: _buildInputDecoration('Retorno a Cero'),
          items: const [
            DropdownMenuItem(value: '1 Bueno', child: Text('1 Bueno')),
            DropdownMenuItem(value: '2 Aceptable', child: Text('2 Aceptable')),
            DropdownMenuItem(value: '3 Malo', child: Text('3 Malo')),
            DropdownMenuItem(value: '4 No aplica', child: Text('4 No aplica')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.pruebas.retornoCero.estado = value;
              widget.onChanged();
            }
          },
        ),
        const SizedBox(height: 20.0),

        // Estabilidad
        DropdownButtonFormField<String>(
          initialValue: widget.pruebas.retornoCero.estabilidad,
          decoration: _buildInputDecoration('Estabilidad'),
          items: const [
            DropdownMenuItem(value: '1 Bueno', child: Text('1 Bueno')),
            DropdownMenuItem(value: '2 Aceptable', child: Text('2 Aceptable')),
            DropdownMenuItem(value: '3 Malo', child: Text('3 Malo')),
            DropdownMenuItem(value: '4 No aplica', child: Text('4 No aplica')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.pruebas.retornoCero.estabilidad = value;
              widget.onChanged();
            }
          },
        ),
        const SizedBox(height: 20.0),

        // Excentricidad
        SwitchListTile(
          title: const Text('PRUEBAS DE EXCENTRICIDAD FINAL',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
          title: const Text('PRUEBAS DE REPETIBILIDAD FINAL',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
          title: const Text('PRUEBAS DE LINEALIDAD FINAL',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
