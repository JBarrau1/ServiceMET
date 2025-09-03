import 'dart:ui';
import 'package:service_met/screens/offline/bal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sqflite/sqflite.dart';
import '../../bdb/calibracion_bd_bn.dart';

class RdsScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String dbPath;

  const RdsScreen({
    super.key,
    required this.dbName,
    required this.userName,
    required this.dbPath,
  });

  @override
  _RdsScreenState createState() => _RdsScreenState();
}

class _RdsScreenState extends State<RdsScreen> {
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _plantaController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  DatabaseHelperbn? _dbHelper;

  @override
  void dispose() {
    _empresaController.dispose();
    _plantaController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    // Validar que todos los campos estén llenos
    if (_empresaController.text.isEmpty ||
        _plantaController.text.isEmpty ||
        _departamentoController.text.isEmpty) {
      return;
    }
    final db = await openDatabase(widget.dbPath);

    final registro = {
      'empresa': _empresaController.text,
      'planta': _plantaController.text,
      'dep_planta': _departamentoController.text,
    };

    // Verificar si el registro con id = 1 existe
    final existingRecord = await db.query(
      'registros_calibracion_bn',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (existingRecord.isEmpty) {
      // Insertar un nuevo registro si no existe
      await db.insert(
        'registros_calibracion_bn',
        registro,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Actualizar el registro si ya existe
      await db.update(
        'registros_calibracion_bn',
        registro,
        where: 'id = ?',
        whereArgs: [1],
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente.')),
    );
  }

  void _navigateToBalScreen(BuildContext context) async {
    // Validar que todos los campos estén llenos
    if (_empresaController.text.isEmpty ||
        _plantaController.text.isEmpty ||
        _departamentoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor registre todos los datos.')),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMACIÓN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text('¿Está seguro de los datos registrados?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // No confirmado
              },
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmado
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma, guardar datos y navegar a BalScreen
    if (confirm == true) {
      // Guardar los datos en la base de datos
      await _saveDataToDatabase(context);

      // Navegar a BalScreen y pasar los parámetros necesarios
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BalScreen(
            dbName: widget.dbName,
            userName: widget.userName,
            dbPath: widget.dbPath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'CALIBRACION BALANZA NUEVA',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDarkMode
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'REGISTRO DE DATOS DE LA EMPRESA',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _empresaController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre de la empresa';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                SizedBox(
                  height: 54.0,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow, // Color secundario
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 15.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'VER CLIENTES DISPONIBLES',
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Puede verificar si el cliente existe en el DATAMET haciendo cilck en el botón VER CLIENTES DISPONIBLES, en caso de que no exista, por favor registre el cliente.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _plantaController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la planta',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre de la planta';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _departamentoController,
              decoration: const InputDecoration(
                labelText: 'Departamento de la Planta',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre del departamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.black54),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.arrow_forward),
            backgroundColor: Colors.green,
            label: 'Guardar Datos y Siguiente',
            onTap: () {
              _saveDataToDatabase(context);
              _navigateToBalScreen(context); // Llamar a la nueva función
            },
          ),
        ],
      ),
    );
  }
}
