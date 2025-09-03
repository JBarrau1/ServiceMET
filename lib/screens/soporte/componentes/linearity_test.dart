import 'package:flutter/material.dart';

class LinearityTest extends StatefulWidget {
  final String testType;
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const LinearityTest({
    super.key,
    required this.testType,
    required this.initialData,
    required this.onDataChanged,
    this.selectedUnit,
    this.onUnitChanged,
  });

  @override
  State<LinearityTest> createState() => _LinearityTestState();
}

class _LinearityTestState extends State<LinearityTest> {
  late TextEditingController _lastLoadController;
  late TextEditingController _currentLoadController;
  late TextEditingController _incrementController;
  late List<Map<String, TextEditingController>> _rows;

  @override
  void initState() {
    super.initState();
    _lastLoadController =
        TextEditingController(text: widget.initialData['lastLoad'] ?? '0');
    _currentLoadController = TextEditingController();
    _incrementController = TextEditingController();

    _rows = [];
    _initializeRows();
  }

  void _initializeRows() {
    final savedRows = widget.initialData['rows'] ?? [];

    for (var rowData in savedRows) {
      _rows.add({
        'lt': TextEditingController(text: rowData['lt']),
        'indicacion': TextEditingController(text: rowData['indicacion']),
        'retorno': TextEditingController(text: rowData['retorno'] ?? '0'),
      });
    }

    _updateLastLoad();
  }

  void _updateLastLoad() {
    if (_rows.isEmpty) {
      _lastLoadController.text = '0';
      return;
    }

    for (int i = _rows.length - 1; i >= 0; i--) {
      final ltValue = _rows[i]['lt']?.text.trim();
      if (ltValue != null && ltValue.isNotEmpty) {
        _lastLoadController.text = ltValue;
        return;
      }
    }

    _lastLoadController.text = '0';
  }

  void _calculateSum() {
    final lastLoad = double.tryParse(_lastLoadController.text) ?? 0;
    final currentLoad = double.tryParse(_currentLoadController.text) ?? 0;
    _incrementController.text = (lastLoad + currentLoad).toStringAsFixed(2);
  }

  void _addRow() {
    setState(() {
      _rows.add({
        'lt': TextEditingController(),
        'indicacion': TextEditingController(),
        'retorno': TextEditingController(text: '0'),
      });

      _rows.last['lt']?.addListener(_updateLastLoad);
    });
  }

  void _removeRow(BuildContext context, int index) {
    if (_rows.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe mantener al menos 2 filas')),
      );
      return;
    }

    setState(() {
      _rows[index]['lt']?.dispose();
      _rows[index]['indicacion']?.dispose();
      _rows[index]['retorno']?.dispose();
      _rows.removeAt(index);
      _updateLastLoad();
    });
  }

  void _saveLoad(BuildContext context) {
    if (_incrementController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calcule la sumatoria primero')),
      );
      return;
    }

    setState(() {
      for (var row in _rows) {
        if (row['lt']?.text.isEmpty ?? true) {
          row['lt']?.text = _incrementController.text;
          row['indicacion']?.text = _incrementController.text;

          _currentLoadController.clear();
          _incrementController.clear();
          _updateLastLoad();
          return;
        }
      }

      _addRow();
      _rows.last['lt']?.text = _incrementController.text;
      _rows.last['indicacion']?.text = _incrementController.text;

      _currentLoadController.clear();
      _incrementController.clear();
      _updateLastLoad();
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
                decoration: _buildInputDecoration('Última Carga de LT'),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _currentLoadController,
                decoration: _buildInputDecoration('Carga'),
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
                decoration: _buildInputDecoration('Incremento'),
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
          itemBuilder: (context, index) {
            return _buildRow(index);
          },
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

  Widget _buildRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _rows[index]['lt'],
              decoration: _buildInputDecoration('LT ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _rows[index]['indicacion']?.text = value;
                }
                _updateLastLoad();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _rows[index]['indicacion'],
              decoration: _buildInputDecoration('Indicación ${index + 1}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
    );
  }

  @override
  void dispose() {
    _lastLoadController.dispose();
    _currentLoadController.dispose();
    _incrementController.dispose();
    for (var row in _rows) {
      row['lt']?.dispose();
      row['indicacion']?.dispose();
      row['retorno']?.dispose();
    }
    super.dispose();
  }
}
