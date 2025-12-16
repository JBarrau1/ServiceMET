import 'package:flutter/material.dart';
import '../../mnt_prv_regular/mnt_prv_regular_stil/models/mnt_prv_regular_stil_model.dart';
import 'excentricidad_widget.dart';
import 'repetibilidad_widget.dart';
import 'linealidad_widget.dart';
import '../controllers/diagnostico_controller.dart'; // Importar controller para fotos

class PruebasMetrologicasWidget extends StatefulWidget {
  final PruebasMetrologicas pruebas;
  final String tipoPrueba; // 'Inicial' o 'Final'
  final Function onChanged;
  final Future<List<String>> Function(String, String) getIndicationSuggestions;
  final Future<double> Function() getD1FromDatabase;
  final DiagnosticoController? controller; // Opcional, para manejo de fotos

  const PruebasMetrologicasWidget({
    super.key,
    required this.pruebas,
    required this.tipoPrueba,
    required this.onChanged,
    required this.getIndicationSuggestions,
    required this.getD1FromDatabase,
    this.controller,
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
    bool isInicial = widget.tipoPrueba.toLowerCase() == 'inicial';

    return Column(
      children: [
        Text(
          'PRUEBAS METROLÓGICAS ${widget.tipoPrueba.toUpperCase()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDECD00),
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

        // Estabilidad (Campo Carga en DB Diagnostico, o 'Estabilidad' en modelo)
        // Nota: Diagnostico DB usa 'retorno_cero_inicial_carga', usaremos 'valor' del modelo para mantener compatibilidad o 'estabilidad' si el modelo lo tiene.
        // El modelo `RetornoCero` de STIL tiene `valor`, `unidad`, `estabilidad` (opcional).
        // Si seguimos STIL, usamos `estabilidad`.
        DropdownButtonFormField<String>(
          initialValue: widget
              .pruebas.retornoCero.estabilidad, // Usamos campo estabilidad
          decoration: _buildInputDecoration('Estabilidad'),
          items: const [
            DropdownMenuItem(value: '1 Bueno', child: Text('1 Bueno')),
            DropdownMenuItem(value: '2 Aceptable', child: Text('2 Aceptable')),
            DropdownMenuItem(value: '3 Malo', child: Text('3 Malo')),
            DropdownMenuItem(value: '4 No aplica', child: Text('4 No aplica')),
          ],
          onChanged: (value) {
            if (value != null) {
              // Asignamos a 'valor' también porque en DiagnosticoController guardamos data['retorno_cero...carga'] = pruebas.retornoCero.valor
              // pero espera, DiagnosticoController línea 203: data['retorno_cero_${tipo}_carga'] = pruebas.retornoCero.valor;
              // Si quiero guardar la estabilidad ahí, debo asignarla a valor O cambiar el controller.
              // Cambiaré el controller luego para usar .estabilidad si existe o asignar ambas.
              // Por ahora asigno a ambos para seguridad.
              widget.pruebas.retornoCero.estabilidad = value;
              widget.pruebas.retornoCero.valor = value;
              widget.onChanged();
            }
          },
        ),
        const SizedBox(height: 20.0),

        // Excentricidad
        SwitchListTile(
          title: Text(
              'PRUEBAS DE EXCENTRICIDAD ${widget.tipoPrueba.toUpperCase()}',
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
            getIndicationSuggestions: widget.getIndicationSuggestions,
            onChanged: widget.onChanged,
          ),

        const SizedBox(height: 20.0),

        // Repetibilidad
        SwitchListTile(
          title: Text(
              'PRUEBAS DE REPETIBILIDAD ${widget.tipoPrueba.toUpperCase()}',
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
            getIndicationSuggestions: widget.getIndicationSuggestions,
            onChanged: widget.onChanged,
          ),

        const SizedBox(height: 20.0),

        // Linealidad
        SwitchListTile(
          title: Text(
              'PRUEBAS DE LINEALIDAD ${widget.tipoPrueba.toUpperCase()}',
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
            getD1FromDatabase: widget.getD1FromDatabase,
          ),
      ],
    );
  }
}
