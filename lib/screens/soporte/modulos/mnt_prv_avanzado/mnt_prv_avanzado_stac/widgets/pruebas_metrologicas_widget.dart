import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stac_model.dart';
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