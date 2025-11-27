import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stac_model.dart';

class LinealidadWidget extends StatefulWidget {
  final Linealidad linealidad;
  final Function onChanged;

  const LinealidadWidget({
    super.key,
    required this.linealidad,
    required this.onChanged,
  });

  @override
  _LinealidadWidgetState createState() => _LinealidadWidgetState();
}

class _LinealidadWidgetState extends State<LinealidadWidget> {
  final List<TextEditingController> _ltControllers = [];
  final List<TextEditingController> _indicacionControllers = [];
  final List<TextEditingController> _retornoControllers = [];
  final TextEditingController _cargaController = TextEditingController();
  final TextEditingController _incrementoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _incrementoController.text = widget.linealidad.incremento;
    _cargaController.text = widget.linealidad.carga;
  }

  void _initializeControllers() {
    _ltControllers.clear();
    _indicacionControllers.clear();
    _retornoControllers.clear();

    for (var punto in widget.linealidad.puntos) {
      _ltControllers.add(TextEditingController(text: punto.lt));
      _indicacionControllers.add(TextEditingController(text: punto.indicacion));
      _retornoControllers.add(TextEditingController(text: punto.retorno));
    }
  }

  void _actualizarUltimaCarga() {
    if (widget.linealidad.puntos.isEmpty) {
      widget.linealidad.ultimaCargaLt = '0';
      return;
    }

    for (int i = widget.linealidad.puntos.length - 1; i >= 0; i--) {
      final ltValue = widget.linealidad.puntos[i].lt;
      if (ltValue.isNotEmpty) {
        widget.linealidad.ultimaCargaLt = ltValue;
        return;
      }
    }

    widget.linealidad.ultimaCargaLt = '0';
  }

  void _calcularSumatoria() {
    final cargaLn = double.tryParse(widget.linealidad.ultimaCargaLt) ?? 0;
    final cargaCliente = double.tryParse(_cargaController.text) ?? 0;
    final sumatoria = (cargaLn + cargaCliente).toStringAsFixed(2);

    _incrementoController.text = sumatoria;
    widget.linealidad.incremento = sumatoria;
    widget.onChanged();
  }

  void _agregarFila() {
    setState(() {
      widget.linealidad.puntos.add(PuntoLinealidad());
      _ltControllers.add(TextEditingController());
      _indicacionControllers.add(TextEditingController());
      _retornoControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removerFila(int index) {
    if (widget.linealidad.puntos.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe mantener al menos 2 filas')));
      return;
    }

    setState(() {
      widget.linealidad.puntos.removeAt(index);
      _ltControllers[index].dispose();
      _indicacionControllers[index].dispose();
      _retornoControllers[index].dispose();
      _ltControllers.removeAt(index);
      _indicacionControllers.removeAt(index);
      _retornoControllers.removeAt(index);
      _actualizarUltimaCarga();
    });
  }

  void _guardarCarga() {
    if (_incrementoController.text.isEmpty) return;

    setState(() {
      // Buscar primera fila vacía
      for (int i = 0; i < widget.linealidad.puntos.length; i++) {
        if (widget.linealidad.puntos[i].lt.isEmpty) {
          widget.linealidad.puntos[i].lt = _incrementoController.text;
          widget.linealidad.puntos[i].indicacion = _incrementoController.text;
          _ltControllers[i].text = _incrementoController.text;
          _indicacionControllers[i].text = _incrementoController.text;
          _actualizarUltimaCarga();
          _limpiarCampos();
          return;
        }
      }

      // Si no hay filas vacías, agregar nueva
      _agregarFila();
      final lastIndex = widget.linealidad.puntos.length - 1;
      widget.linealidad.puntos[lastIndex].lt = _incrementoController.text;
      widget.linealidad.puntos[lastIndex].indicacion =
          _incrementoController.text;
      _ltControllers[lastIndex].text = _incrementoController.text;
      _indicacionControllers[lastIndex].text = _incrementoController.text;
      _actualizarUltimaCarga();
      _limpiarCampos();
    });
  }

  void _limpiarCampos() {
    _cargaController.clear();
    _incrementoController.clear();
    widget.linealidad.carga = '';
    widget.linealidad.incremento = '';
    widget.onChanged();
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildFilaLinealidad(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _ltControllers[index],
              decoration: _buildInputDecoration('LT ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.linealidad.puntos[index].lt = value;
                widget.linealidad.puntos[index].indicacion = value;
                _indicacionControllers[index].text = value;
                _actualizarUltimaCarga();
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _indicacionControllers[index],
              decoration: _buildInputDecoration('Indicación ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.linealidad.puntos[index].indicacion = value;
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'PRUEBAS DE LINEALIDAD',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Sección de Carga e Incremento
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: TextEditingController(
                    text: widget.linealidad.ultimaCargaLt),
                decoration: _buildInputDecoration('Última Carga de LT'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _cargaController,
                decoration: _buildInputDecoration('Carga'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  widget.linealidad.carga = value;
                  _calcularSumatoria();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _incrementoController,
                decoration: _buildInputDecoration('Incremento'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _guardarCarga,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('GUARDAR CARGA'),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        const Text(
          'CARGAS REGISTRADAS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        // Lista de filas
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.linealidad.puntos.length,
          itemBuilder: (context, index) {
            return _buildFilaLinealidad(index);
          },
        ),
        const SizedBox(height: 10),

        // Botones de control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _agregarFila,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _removerFila(widget.linealidad.puntos.length - 1),
              icon: const Icon(Icons.remove, color: Colors.white),
              label: const Text('Eliminar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _ltControllers) {
      controller.dispose();
    }
    for (var controller in _indicacionControllers) {
      controller.dispose();
    }
    for (var controller in _retornoControllers) {
      controller.dispose();
    }
    _cargaController.dispose();
    _incrementoController.dispose();
    super.dispose();
  }
}
