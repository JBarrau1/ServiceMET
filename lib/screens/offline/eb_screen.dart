import 'dart:io';
import 'dart:ui';
import 'package:service_met/screens/offline/pc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart'; // Para crear archivos ZIP
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // Para manejar archivos con SAF
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart'; // Importar Uint8List

class EbScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String dbPath;

  const EbScreen({
    super.key,
    required this.dbName,
    required this.userName,
    required this.dbPath,
  });

  @override
  _EbScreenState createState() => _EbScreenState();
}

class _EbScreenState extends State<EbScreen> {
  String? _tiempoMin;
  String? _horaInicio;
  String? _tiempoBalanza;
  final _formKey = GlobalKey<FormState>();
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final Map<String, List<File>> _fieldPhotos = {};

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _horaInicio = DateFormat('HH:mm:ss').format(DateTime.now());
    _fieldData['Vibración'] = {'value': 'Inexistente'};
    _fieldData['Polvo'] = {'value': 'Inexistente'};
    _fieldData['Temperatura'] = {'value': 'Bueno'};
    _fieldData['Humedad'] = {'value': 'Inexistente'};
    _fieldData['Mesada'] = {'value': 'Bueno'};
    _fieldData['Iluminación'] = {'value': 'Bueno'};
    _fieldData['Limpieza de Fosa'] = {'value': 'Bueno'};
    _fieldData['Estado de Drenaje'] = {'value': 'Bueno'};
    _fieldData['Limpieza General'] = {'value': 'Bueno'};
    _fieldData['Golpes al Terminal'] = {'value': 'Sin Daños'};
    _fieldData['Nivelación'] = {'value': 'Bueno'};
    _fieldData['Limpieza Receptor'] = {'value': 'Inexistente'};
    _fieldData['Golpes al receptor de Carga'] = {'value': 'Sin Daños'};
    _fieldData['Encendido'] = {'value': 'Bueno'};
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    final db = await openDatabase(widget.dbPath);

    final registro = {
      'hora_inicio': _horaInicio,
      'tiempo_estab': _tiempoMin,
      't_ope_balanza': _tiempoBalanza,
      'vibracion': _fieldData['Vibración']?['value'],
      'polvo': _fieldData['Polvo']?['value'],
      'temp': _fieldData['Temperatura']?['value'],
      'humedad': _fieldData['Humedad']?['value'],
      'mesada': _fieldData['Mesada']?['value'],
      'iluminacion': _fieldData['Iluminación']?['value'],
      'limp_foza': _fieldData['Limpieza de Fosa']?['value'],
      'estado_drenaje': _fieldData['Estado de Drenaje']?['value'],
      'limp_general': _fieldData['Limpieza General']?['value'],
      'golpes_terminal': _fieldData['Golpes al Terminal']?['value'],
      'nivelacion': _fieldData['Nivelación']?['value'],
      'limp_recepto': _fieldData['Limpieza Receptor']?['value'],
      'golpes_receptor': _fieldData['Golpes al receptor de Carga']?['value'],
      'encendido': _fieldData['Encendido']?['value'],
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

  void _navigateToPcScreen(BuildContext context) async {
    // Validar que todos los campos estén llenos

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
          builder: (context) => PcScreen(
            dbName: widget.dbName,
            userName: widget.userName,
            dbPath: widget.dbPath,
          ),
        ),
      );
    }
  }

  Widget _buildDropdownField(
      BuildContext context, String label, List<String> items) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<String>(
            value: _fieldData[label]?['value'],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items: items.map((String value) {
              Color textColor;
              switch (value) {
                case 'Inexistente':
                  textColor = Colors.lightGreen;
                  break;
                case 'Dañado':
                  textColor = Colors.red;
                  break;
                case 'Malo':
                  textColor = Colors.red;
                  break;
                case 'Aceptable':
                  textColor = Colors.orange;
                  break;
                case 'Bueno':
                  textColor = Colors.lightGreen;
                  break;
                case 'Sin Daños':
                  textColor = Colors.lightGreen;
                  break;
                case 'Existente':
                  textColor = Colors.red;
                  break;
                case 'Daños Leves':
                  textColor = Colors.orange;
                  break;
                case 'No aplica':
                  textColor = Colors.grey;
                  break;
                default:
                  textColor = Colors.black;
              }
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: textColor),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _fieldData[label] ??= {};
                _fieldData[label]!['value'] = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor seleccione una opción';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _showCommentDialog(context, label),
          icon: Icon(
            _fieldData[label]?['comment'] != null ||
                    _fieldData[label]?['image'] != null
                ? Icons.check_circle
                : Icons.add_comment,
          ),
          tooltip: 'Agregar Comentario',
        ),
      ],
    );
  }

  Future<void> _showCommentDialog(BuildContext context, String label) async {
    final ImagePicker picker = ImagePicker();
    List<File> photos = _fieldPhotos[label] ?? [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Agregar Comentario y Fotos para $label'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final XFile? photo =
                        await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      setState(() {
                        photos.add(File(photo.path));
                        _fieldPhotos[label] = photos;
                      });
                    }
                  },
                  child: const Text('Tomar Foto'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: photos.map((photo) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.file(photo, width: 100, height: 100),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAllPhotos() async {
    final archive = Archive(); // Crear un archivo ZIP

    // Agregar todas las fotos al archivo ZIP
    _fieldPhotos.forEach((label, photos) {
      for (var i = 0; i < photos.length; i++) {
        final file = photos[i];
        final fileName = '${label}_${i + 1}.jpg';
        archive.addFile(
            ArchiveFile(fileName, file.lengthSync(), file.readAsBytesSync()));
      }
    });

    // Codificar el archivo ZIP
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    // Convertir List<int> a Uint8List
    final uint8ListData = Uint8List.fromList(zipData);

    // Permitir al usuario seleccionar la carpeta de destino
    final params = SaveFileDialogParams(
      data: uint8ListData, // Usar Uint8List en lugar de List<int>
      fileName: 'fotos_calibracion.zip', // Nombre del archivo
      mimeTypesFilter: ['application/zip'], // Filtro para archivos ZIP
    );

    try {
      final filePath = await FlutterFileDialog.saveFile(params: params);
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotos guardadas en $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna carpeta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el archivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDarkMode ? Colors.white : Colors.black;

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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'REGISTRO DE DATOS DE CONDICIONES DEL EQUIPO A CALIBRAR',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: _horaInicio,
                decoration: InputDecoration(
                  labelText: 'Hora de inicio de la Calibración:',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor)),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _tiempoMin,
                decoration: InputDecoration(
                  labelText: 'Tiempo de estabilización de Pesas (en Minutos):',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Mayor a 15 minutos',
                      child: Text('Mayor a 15 minutos')),
                  DropdownMenuItem(
                      value: 'Mayor a 30 minutos',
                      child: Text('Mayor a 30 minutos')),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _tiempoMin = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                value: _tiempoBalanza,
                decoration: InputDecoration(
                  labelText: 'Tiempo previo a operacion de Balanza:',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Mayor a 15 minutos',
                      child: Text('Mayor a 15 minutos')),
                  DropdownMenuItem(
                      value: 'Mayor a 30 minutos',
                      child: Text('Mayor a 30 minutos')),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _tiempoBalanza = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              const Text(
                'ENTORNO DE INSTALACIÓN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Vibración',
                  ['Inexistente', 'Aceptable', 'Existente', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Polvo',
                  ['Inexistente', 'Aceptable', 'Existente', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Temperatura',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Humedad',
                  ['Inexistente', 'Aceptable', 'Existente', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Mesada',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Iluminación',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Limpieza de Fosa',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Estado de Drenaje',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              const Text(
                'ESTADO GENERAL DE LA BALANZA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Limpieza General',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Golpes al Terminal',
                  ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Nivelación',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Limpieza Receptor',
                  ['Inexistente', 'Aceptable', 'Existente', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Golpes al receptor de Carga',
                  ['Sin Daños', 'Daños Leves', 'Dañado', 'No aplica']),
              const SizedBox(height: 20.0),
              _buildDropdownField(context, 'Encendido',
                  ['Bueno', 'Aceptable', 'Malo', 'No aplica']),
            ],
          ),
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
            child: const Icon(Icons.save),
            backgroundColor: Colors.blue,
            label: 'Guardar Todas las Fotos',
            onTap: _saveAllPhotos, // Llamar a la función para guardar fotos
          ),
          SpeedDialChild(
            child: const Icon(Icons.arrow_forward),
            backgroundColor: Colors.green,
            label: 'Guardar Datos y Siguiente',
            onTap: () {
              _saveDataToDatabase(context);
              _navigateToPcScreen(context);
            },
          ),
        ],
      ),
    );
  }
}
