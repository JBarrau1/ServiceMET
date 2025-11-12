import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/balanza_provider.dart';
import 'base_metrological_test.dart';

class LinearityTest extends BaseMetrologicalTest {
  const LinearityTest({
    super.key,
    required super.testType,
    required super.initialData,
    required super.onDataChanged,
    super.selectedUnit,
    super.onUnitChanged,
  });

  @override
  State<LinearityTest> createState() => _LinearityTestState();
}

class _LinearityTestState extends State<LinearityTest>
    with MetrologicalTestMixin<LinearityTest> {
  late TextEditingController _lastLoadController;
  late TextEditingController _currentLoadController;
  late TextEditingController _incrementController;
  late List<Map<String, TextEditingController>> _rows;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _lastLoadController =
        TextEditingController(text: widget.initialData['lastLoad'] ?? '0');
    _currentLoadController = TextEditingController();
    _incrementController = TextEditingController();

    _rows = [];
    _initializeRows();

    // Marcar que la inicialización ha terminado SIN notificar inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        // NO llamar _notifyDataChanged() aquí - solo después de interacciones del usuario
      }
    });
  }

  void _initializeRows() {
    final savedRows = widget.initialData['rows'] ?? [];

    for (var rowData in savedRows) {
      _rows.add({
        'lt': TextEditingController(text: rowData['lt'] ?? ''),
        'indicacion': TextEditingController(text: rowData['indicacion'] ?? ''),
        'retorno': TextEditingController(text: rowData['retorno'] ?? '0'),
      });
    }

    // Asegurar mínimo 2 filas
    while (_rows.length < 2) {
      _addEmptyRow();
    }

    _updateLastLoad();
    _setupListeners();
  }

  void _setupListeners() {
    for (var row in _rows) {
      row['lt']?.addListener(_updateLastLoad);
    }
  }

  void _addEmptyRow() {
    _rows.add({
      'lt': TextEditingController(),
      'indicacion': TextEditingController(),
      'retorno': TextEditingController(text: '0'),
    });
  }

  void _updateLastLoad() {
    if (_rows.isEmpty) {
      _lastLoadController.text = '0';
      if (!_isInitializing) {
        _calculateSum();
        // Solo notificar después de que el usuario interactúe
        Future.microtask(() => _notifyDataChanged());
      }
      return;
    }

    for (int i = _rows.length - 1; i >= 0; i--) {
      final ltValue = _rows[i]['lt']?.text.trim();
      if (ltValue != null && ltValue.isNotEmpty) {
        _lastLoadController.text = ltValue;
        if (!_isInitializing) {
          _calculateSum();
          Future.microtask(() => _notifyDataChanged());
        }
        return;
      }
    }

    _lastLoadController.text = '0';
    if (!_isInitializing) {
      _calculateSum();
      Future.microtask(() => _notifyDataChanged());
    }
  }


  void _calculateSum() {
    final lastLoad = double.tryParse(_lastLoadController.text) ?? 0;
    final currentLoad = double.tryParse(_currentLoadController.text) ?? 0;

    // Deriva precisión de d1
    final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    final d1 = balanza?.d1 ?? 0.1;
    final decimalPlaces = _getSignificantDecimals(d1);

    _incrementController.text = (lastLoad + currentLoad).toStringAsFixed(decimalPlaces);
  }

  void _addRow() {
    setState(() {
      _addEmptyRow();
      _rows.last['lt']?.addListener(_updateLastLoad);
      if (!_isInitializing) {
        _notifyDataChanged();
      }
    });
  }

  void _removeRow(BuildContext context, int index) {
    if (_rows.length <= 2) {
      showSnackBar(context, 'Debe mantener al menos 2 filas');
      return;
    }

    setState(() {
      // Remover listener antes de disponer
      _rows[index]['lt']?.removeListener(_updateLastLoad);
      _rows[index]['lt']?.dispose();
      _rows[index]['indicacion']?.dispose();
      _rows[index]['retorno']?.dispose();
      _rows.removeAt(index);
      _updateLastLoad();
    });
  }

  void _saveLoad(BuildContext context) {
    if (_incrementController.text.isEmpty) {
      showSnackBar(context, 'Calcule la sumatoria primero');
      return;
    }

    setState(() {
      // Asignar a primera fila vacía o crear una nueva
      Map<String, TextEditingController>? targetRow =
      _rows.firstWhere((row) => (row['lt']?.text.isEmpty ?? true), orElse: () => {});
      if (targetRow.isEmpty) {
        _addRow();
        targetRow = _rows.last;
      }

      targetRow['lt']!.text = _incrementController.text;

      _currentLoadController.clear();
      _incrementController.clear();

      _updateLastLoad(); // ya recalcula incremento y notifica
    });
  }


  void _notifyDataChanged() {
    if (!mounted || _isInitializing) return;

    final rowsData = _rows
        .map((row) => {
      'lt': row['lt']?.text ?? '',
      'indicacion': row['indicacion']?.text ?? '',
      'retorno': row['retorno']?.text ?? '0',
    })
        .toList();

    // Solo notificar si hay cambios reales del usuario
    updateData({
      'type': 'linearity',
      'testType': widget.testType,
      'lastLoad': _lastLoadController.text,
      'rows': rowsData,
    });
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lastLoadController,
                decoration: buildInputDecoration('Última Carga de LT'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _currentLoadController,
                decoration: buildInputDecoration('Carga'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateSum(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _incrementController,
                decoration: buildInputDecoration('Incremento'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _saveLoad(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('GUARDAR CARGA'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'CARGAS REGISTRADAS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rows.length,
          itemBuilder: (context, index) => _buildRow(index),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: () => _removeRow(context, _rows.length - 1),
              icon: const Icon(Icons.remove, color: Colors.white),
              label: const Text('Eliminar Fila'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  int _getSignificantDecimals(double value) {
    final parts = value.toString().split('.');
    if (parts.length == 2) {
      return parts[1].replaceAll(RegExp(r'0+$'), '').length;
    }
    return 0;
  }

  Widget _buildRow(int index) {
    final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    final d1 = balanza?.d1 ?? 0.1;

    final indicacionCtrl = _rows[index]['indicacion']!;
    final ltCtrl = _rows[index]['lt']!;

    final decimalPlaces = _getSignificantDecimals(d1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: ltCtrl,
              decoration: buildInputDecoration('LT ${index + 1}'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  indicacionCtrl.text = value;
                }
                _updateLastLoad();   // también recalcula incremento (ver cambio 3)
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: indicacionCtrl,
              decoration: buildInputDecoration(
                'Indicación ${index + 1}',
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String newValue) {
                    setState(() {
                      indicacionCtrl.text = newValue;
                    });
                    _notifyDataChanged();
                  },
                  itemBuilder: (BuildContext context) {
                    final baseValue = double.tryParse(indicacionCtrl.text) ?? 0.0;
                    return List.generate(11, (i) {
                      final multiplier = i - 5;
                      final value = baseValue + (multiplier * d1);
                      final formattedValue = value.toStringAsFixed(decimalPlaces);
                      return PopupMenuItem<String>(
                        value: formattedValue,
                        child: Text(formattedValue),
                      );
                    });
                  },
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _notifyDataChanged(),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _lastLoadController.dispose();
    _currentLoadController.dispose();
    _incrementController.dispose();

    // Remover listeners y disponer controladores
    for (var row in _rows) {
      row['lt']?.removeListener(_updateLastLoad);
    }
    disposeControllerMaps(_rows);
    super.dispose();
  }
}