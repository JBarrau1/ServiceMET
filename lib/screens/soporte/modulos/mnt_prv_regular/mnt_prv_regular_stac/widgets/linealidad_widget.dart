import 'package:flutter/material.dart';
import '../models/mnt_prv_regular_stac_model.dart';

class LinealidadWidget extends StatefulWidget {
  final Linealidad linealidad;
  final Function onChanged;
  final Future<double> Function() getD1FromDatabase;

  const LinealidadWidget({
    super.key,
    required this.linealidad,
    required this.onChanged,
    required this.getD1FromDatabase,
  });

  @override
  _LinealidadWidgetState createState() => _LinealidadWidgetState();
}

class _LinealidadWidgetState extends State<LinealidadWidget> {
  final List<TextEditingController> _ltControllers = [];
  final List<TextEditingController> _indicacionControllers = [];
  final List<TextEditingController> _retornoControllers = [];
  final List<TextEditingController> _differenceControllers = [];

  // Controladores para Método 2
  final TextEditingController _iLsubnController = TextEditingController();
  final TextEditingController _lsubnController = TextEditingController();
  final TextEditingController _ioController = TextEditingController();
  final TextEditingController _ltnController = TextEditingController();
  double _d1 = 0.1; // Initialize with default

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _iLsubnController.text = widget.linealidad.iLsubn;
    _lsubnController.text = widget.linealidad.lsubn;
    _ioController.text = widget.linealidad.io;
    _ltnController.text = widget.linealidad.ltn;
    _loadD1();
  }

  Future<void> _loadD1() async {
    final val = await widget.getD1FromDatabase();
    if (mounted) {
      setState(() {
        _d1 = val;
      });
    }
  }

  void _initializeControllers() {
    _ltControllers.clear();
    _indicacionControllers.clear();
    _retornoControllers.clear();
    _differenceControllers.clear();

    for (var punto in widget.linealidad.puntos) {
      _ltControllers.add(TextEditingController(text: punto.lt));
      _indicacionControllers.add(TextEditingController(text: punto.indicacion));
      _retornoControllers.add(TextEditingController(text: punto.retorno));
      _differenceControllers.add(TextEditingController());
      _calcularDiferencia(_differenceControllers.length - 1);
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

  void _calcularMetodo2() {
    final iLsubn = double.tryParse(_iLsubnController.text) ?? 0.0;

    if (widget.linealidad.puntos.isEmpty) {
      _lsubnController.text = iLsubn.toStringAsFixed(2);
      _calcularLtn();
      return;
    }

    // Buscar la carga LT más cercana a I(Lsubn)
    double closestLt = double.infinity;
    double closestDifference = 0.0;

    for (var punto in widget.linealidad.puntos) {
      final lt = double.tryParse(punto.lt) ?? 0.0;
      final indicacion = double.tryParse(punto.indicacion) ?? 0.0;
      final difference = indicacion - lt;

      if ((iLsubn - lt).abs() < (iLsubn - closestLt).abs()) {
        closestLt = lt;
        closestDifference = difference;
      }
    }

    // Calcular Lsubn
    final lsubn = iLsubn - closestDifference;
    _lsubnController.text = lsubn.toStringAsFixed(2);
    widget.linealidad.lsubn = lsubn.toStringAsFixed(2);

    _calcularLtn();
  }

  void _calcularLtn() {
    final lsubn = double.tryParse(_lsubnController.text) ?? 0.0;
    final io = double.tryParse(_ioController.text) ?? 0.0;
    final ltn = lsubn + io;

    _ltnController.text = ltn.toStringAsFixed(2);
    widget.linealidad.ltn = ltn.toStringAsFixed(2);
    widget.onChanged();
  }

  void _agregarFila() {
    if (widget.linealidad.puntos.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo 12 cargas permitidas')));
      return;
    }

    setState(() {
      widget.linealidad.puntos.add(PuntoLinealidad());
      _ltControllers.add(TextEditingController());
      _indicacionControllers.add(TextEditingController());
      _retornoControllers.add(TextEditingController(text: '0'));
      _differenceControllers.add(TextEditingController());
    });
  }

  void _removerFila(int index) {
    if (widget.linealidad.puntos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe mantener al menos 1 fila')));
      return;
    }

    setState(() {
      widget.linealidad.puntos.removeAt(index);
      _ltControllers[index].dispose();
      _indicacionControllers[index].dispose();
      _retornoControllers[index].dispose();
      _differenceControllers[index].dispose();
      _ltControllers.removeAt(index);
      _indicacionControllers.removeAt(index);
      _retornoControllers.removeAt(index);
      _differenceControllers.removeAt(index);
      _actualizarUltimaCarga();
    });
  }

  void _guardarCarga() {
    if (_ltnController.text.isEmpty) return;

    if (widget.linealidad.puntos.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo 12 cargas permitidas')));
      return;
    }

    setState(() {
      // Buscar primera fila vacía
      for (int i = 0; i < widget.linealidad.puntos.length; i++) {
        if (widget.linealidad.puntos[i].lt.isEmpty) {
          widget.linealidad.puntos[i].lt = _ltnController.text;
          widget.linealidad.puntos[i].indicacion = _ltnController.text;
          _ltControllers[i].text = _ltnController.text;
          _indicacionControllers[i].text = _ltnController.text;
          _actualizarUltimaCarga();
          _limpiarCampos();
          return;
        }
      }

      // Si no hay filas vacías, agregar nueva
      if (widget.linealidad.puntos.length < 12) {
        _agregarFila();
        final lastIndex = widget.linealidad.puntos.length - 1;
        widget.linealidad.puntos[lastIndex].lt = _ltnController.text;
        widget.linealidad.puntos[lastIndex].indicacion = _ltnController.text;
        _ltControllers[lastIndex].text = _ltnController.text;
        _indicacionControllers[lastIndex].text = _ltnController.text;
        _actualizarUltimaCarga();
        _limpiarCampos();
      }
    });
  }

  void _limpiarCampos() {
    _iLsubnController.clear();
    _lsubnController.clear();
    _ioController.clear();
    _ltnController.clear();
    widget.linealidad.iLsubn = '';
    widget.linealidad.lsubn = '';
    widget.linealidad.io = '0';
    widget.linealidad.ltn = '';
    widget.onChanged();
  }

  void _calcularDiferencia(int index) {
    if (index < 0 || index >= _ltControllers.length) return;

    final ltText = _ltControllers[index].text.replaceAll(',', '.');
    final indicacionText =
        _indicacionControllers[index].text.replaceAll(',', '.');

    if (ltText.isNotEmpty && indicacionText.isNotEmpty) {
      final lt = double.tryParse(ltText) ?? 0.0;
      final indicacion = double.tryParse(indicacionText) ?? 0.0;
      final diferencia = indicacion - lt;

      // Intentar respetar los decimales de la indicación
      int decimals = 1;
      if (indicacionText.contains('.')) {
        decimals = indicacionText.split('.')[1].length;
      }

      _differenceControllers[index].text = diferencia.toStringAsFixed(decimals);
    } else {
      _differenceControllers[index].text = '';
    }
  }

  // DIÁLOGO PARA SUMAR/RESTAR CARGAS (Compositor de Carga Avanzado)
  Future<void> _showSummationDialog(int currentIndex) async {
    // 1. Obtener cargas anteriores válidas (LT e Indicación)
    // Estructura: {index, lt, ind, operation: 0 (none), 1 (add), -1 (sub)}
    final previousLoads = <Map<String, dynamic>>[];

    for (int i = 0; i < currentIndex; i++) {
      final ltVal =
          double.tryParse(_ltControllers[i].text.replaceAll(',', '.')) ?? 0.0;
      final indVal = double.tryParse(
              _indicacionControllers[i].text.replaceAll(',', '.')) ??
          0.0;

      if (ltVal > 0) {
        previousLoads.add({
          'index': i,
          'lt': ltVal,
          'ind': indVal,
          'operation': 0, // 0: Ignorar, 1: Sumar, -1: Restar
        });
      }
    }

    // 2. Lista para valores manuales temporales
    final manualValues = <double>[];
    final manualInputController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Calcular Totales
            double totalLt = 0.0;
            double totalInd = 0.0;

            // Sumar/Restar Cargas Anteriores
            for (var item in previousLoads) {
              int op = item['operation'] as int;
              if (op != 0) {
                totalLt += (item['lt'] as double) * op;
                totalInd += (item['ind'] as double) * op;
              }
            }

            // Sumar Manuales (Asumimos que manual afecta igual a LT e Indicación, idealmente)
            // Si el usuario ingresa negativo, resta.
            double sumManual = manualValues.fold(0.0, (sum, val) => sum + val);
            totalLt += sumManual;
            totalInd += sumManual;

            return AlertDialog(
              title: const Text(
                'REGISTRO DE CARGAS',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN 1: Cargas Anteriores
                      if (previousLoads.isNotEmpty) ...[
                        const Text('Cargas Anteriores:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: previousLoads.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = previousLoads[i];
                            final int operation = item['operation'];
                            final double val = item['lt'];

                            // Color para diferenciar el estado
                            Color? cardColor;
                            if (operation == 1)
                              cardColor = Colors.green.withOpacity(0.1);
                            if (operation == -1)
                              cardColor = Colors.red.withOpacity(0.1);

                            return Container(
                              color: cardColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Carga ${item['index'] + 1}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 10),
                                        Text('LT: $val | Ind: ${item['ind']}'),
                                      ],
                                    ),
                                  ),
                                  // Botones de Operación
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón Restar
                                      IconButton(
                                        icon: Icon(Icons.remove_circle,
                                            color: operation == -1
                                                ? Colors.red
                                                : Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            // Toggle: si ya estaba restando, deseleccionar
                                            item['operation'] =
                                                (operation == -1) ? 0 : -1;
                                          });
                                        },
                                      ),
                                      // Botón Sumar
                                      IconButton(
                                        icon: Icon(Icons.add_circle,
                                            color: operation == 1
                                                ? Colors.green
                                                : Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            // Toggle: si ya estaba sumando, deseleccionar
                                            item['operation'] =
                                                (operation == 1) ? 0 : 1;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],

                      // SECCIÓN 2: Agregar Manual
                      const SizedBox(height: 10),
                      const Text('Agregar Carga Manual:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: manualInputController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_box,
                                color: Colors.blue, size: 30),
                            onPressed: () {
                              final val = double.tryParse(manualInputController
                                      .text
                                      .replaceAll(',', '.')) ??
                                  0.0;
                              if (val != 0) {
                                setState(() {
                                  manualValues.add(val);
                                  manualInputController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      // SECCIÓN 3: Lista de Manuales
                      if (manualValues.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: manualValues.asMap().entries.map((entry) {
                            final val = entry.value;
                            return Chip(
                              backgroundColor:
                                  val > 0 ? Colors.green[50] : Colors.red[50],
                              avatar: Icon(
                                val > 0 ? Icons.add : Icons.remove,
                                size: 16,
                                color: val > 0 ? Colors.green : Colors.red,
                              ),
                              label: Text('${val.abs()}',
                                  style: TextStyle(
                                      color: val > 0
                                          ? Colors.green[800]
                                          : Colors.red[800])),
                              onDeleted: () {
                                setState(() {
                                  manualValues.removeAt(entry.key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                // Resumen de Totales
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Carga (LT): ${totalLt.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Indicación Est.: ${totalInd.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        // Aplicar valores a los controladores
                        _ltControllers[currentIndex].text =
                            totalLt.toStringAsFixed(2);
                        _indicacionControllers[currentIndex].text =
                            totalInd.toStringAsFixed(2);

                        // Actualizar modelo
                        widget.linealidad.puntos[currentIndex].lt =
                            totalLt.toStringAsFixed(2);
                        widget.linealidad.puntos[currentIndex].indicacion =
                            totalInd.toStringAsFixed(2);

                        _actualizarUltimaCarga();
                        _calcularDiferencia(currentIndex);
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ],
                )
              ],
            );
          },
        );
      },
    );
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
      child: Column(
        children: [
          // Fila 1: Carga (LT) y Error (Diferencia)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ltControllers[index],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    widget.linealidad.puntos[index].lt = value;
                    widget.linealidad.puntos[index].indicacion =
                        value; // Copiar a indicación por defecto
                    _indicacionControllers[index].text =
                        value; // Reflejar en controlador
                    _actualizarUltimaCarga();
                    _calcularDiferencia(index);
                    widget.onChanged();
                  },
                  decoration: _buildInputDecoration('LT ${index + 1}').copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate, color: Colors.blue),
                      onPressed: () => _showSummationDialog(index),
                      tooltip: 'Componer Carga',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _differenceControllers[index],
                  decoration: _buildInputDecoration('Error'),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 2: Indicación y Retorno
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _indicacionControllers[index],
                  decoration: _buildInputDecoration(
                    'Indicación ${index + 1}',
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String newValue) {
                        setState(() {
                          _indicacionControllers[index].text = newValue;
                          widget.linealidad.puntos[index].indicacion = newValue;
                          _calcularDiferencia(index);
                          widget.onChanged();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        final currentText =
                            _indicacionControllers[index].text.trim();
                        final baseValue = double.tryParse(
                              (currentText.isEmpty
                                      ? widget.linealidad.puntos[index].lt
                                      : currentText)
                                  .replaceAll(',', '.'),
                            ) ??
                            0.0;

                        int decimals = 1;
                        if (_d1 > 0) {
                          if (_d1 % 1 == 0) {
                            decimals = 0;
                          } else {
                            final d1Str = _d1.toString();
                            if (d1Str.contains('.')) {
                              decimals = d1Str.split('.')[1].length;
                            }
                          }
                        }
                        if (decimals > 4) decimals = 4;

                        return List.generate(11, (i) {
                          final value = baseValue + ((i - 5) * _d1);
                          final txt = value.toStringAsFixed(decimals);
                          return PopupMenuItem<String>(
                            value: txt,
                            child: Text(txt),
                          );
                        });
                      },
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    widget.linealidad.puntos[index].indicacion = value;
                    _calcularDiferencia(index);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _retornoControllers[index],
                  decoration: _buildInputDecoration('Retorno (0)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    widget.linealidad.puntos[index].retorno = value;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
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

        // Sección Método 2
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _iLsubnController,
                decoration: _buildInputDecoration('I(Lsubn)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  widget.linealidad.iLsubn = value;
                  _calcularMetodo2();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _lsubnController,
                decoration: _buildInputDecoration('Lsubn'),
                readOnly: true,
                style: const TextStyle(color: Colors.lightGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ioController,
                decoration: _buildInputDecoration('Io'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  widget.linealidad.io = value;
                  _calcularLtn();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _ltnController,
                decoration: _buildInputDecoration('LTn'),
                readOnly: true,
                style: const TextStyle(color: Colors.lightGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15.0),
        ElevatedButton(
          onPressed: _guardarCarga,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('GUARDAR LTn'),
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
              onPressed:
                  widget.linealidad.puntos.length < 12 ? _agregarFila : null,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: widget.linealidad.puntos.length > 1
                  ? () => _removerFila(widget.linealidad.puntos.length - 1)
                  : null,
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
    for (var controller in _differenceControllers) {
      controller.dispose();
    }
    _iLsubnController.dispose();
    _lsubnController.dispose();
    _ioController.dispose();
    _ltnController.dispose();
    super.dispose();
  }
}
