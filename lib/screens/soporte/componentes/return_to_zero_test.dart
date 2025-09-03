import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReturnToZeroTest extends StatefulWidget {
  final String testType;
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const ReturnToZeroTest({
    super.key,
    required this.testType,
    required this.initialData,
    required this.onDataChanged,
    this.selectedUnit,
    this.onUnitChanged,
  });

  @override
  State<ReturnToZeroTest> createState() => _ReturnToZeroTestState();
}

class _ReturnToZeroTestState extends State<ReturnToZeroTest> {
  late String _selectedValue;
  late TextEditingController _loadController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialData['value'] ?? '1 Bueno';
    _loadController = TextEditingController(
        text: widget.initialData['load']?.toString() ?? '');
    _selectedUnit = widget.selectedUnit ?? 'kg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedValue,
                decoration: _buildInputDecoration(
                  'Retorno a cero ${widget.testType == 'initial' ? 'inicial' : 'final'}',
                ),
                items: ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica']
                    .map((String value) {
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case '1 Bueno':
                      textColor = Colors.green;
                      icon =
                          const Icon(Icons.check_circle, color: Colors.green);
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
                      _selectedValue = value;
                      _updateData();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _loadController,
                decoration: _buildInputDecoration(
                  'Carga de Prueba',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        items: ['kg', 'g'].map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(unit),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUnit = newValue;
                              if (widget.onUnitChanged != null) {
                                widget.onUnitChanged!(_selectedUnit);
                              }
                              _updateData();
                            });
                          }
                        },
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  _loadController.text = numericValue.isNotEmpty
                      ? '$numericValue $_selectedUnit'
                      : '';
                  _updateData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateData() {
    widget.onDataChanged({
      'type': 'return_to_zero',
      'testType': widget.testType,
      'value': _selectedValue,
      'load': _loadController.text.replaceAll(' $_selectedUnit', ''),
      'unit': _selectedUnit,
    });
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }
}
