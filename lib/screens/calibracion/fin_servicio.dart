import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import '../../database/app_database.dart';
import '../../home_screen.dart';
import 'iden_balanza_screen.dart';

class FinServicioScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;

  const FinServicioScreen({
    super.key,
    required this.secaValue,
    required this.sessionId,
  });

  @override
  _FinServicioScreenState createState() => _FinServicioScreenState();
}

class _FinServicioScreenState extends State<FinServicioScreen> {
  String? errorMessage;
  bool _isExporting = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // color del texto
        ),

        backgroundColor: isError
            ? Colors.red
            : Colors.green, // esto aún funciona en versiones actuales
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// CONFIRMAR Y EXPORTAR (muestra diálogo antes de exportar)
  Future<void> _confirmarYExportar(BuildContext context) async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

      // 1) Consulta filtrada
      final rows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND estado_servicio_bal = ?',
        whereArgs: [widget.secaValue, 'Balanza Calibrada'],
      );

      final cantidad = rows.length;

      if (cantidad == 0) {
        _showSnackBar(context,
            'No hay registros para exportar con este SECA (${widget.secaValue})',
            isError: true);
        return;
      }

      // 2) Mostrar diálogo de confirmación
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Confirmar exportación'.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'Se exportará el SECA "${widget.secaValue}" con $cantidad registros.\n\n¿Desea continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF46824B),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, exportar'),
              )

            ],
          );
        },
      );

      if (confirmado != true) return;

      // 3) Exportar a CSV y TXT con los mismos registros
      await _exportDataToCSV(context, rows);
      await _exportDataToTXT(context, rows);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      _showSnackBar(context, 'Error en exportación: $e', isError: true);
    }
  }


  Future<List<Map<String, dynamic>>> _depurarDatos(
      List<Map<String, dynamic>> registros) async {
    // 1. Eliminar filas completamente vacías
    registros.removeWhere((registro) =>
        registro.values.every((value) => value == null || value == ''));

    // 2. Eliminar duplicados conservando el más reciente (por hora_fin)
    final Map<String, Map<String, dynamic>> registrosUnicos = {};

    for (var registro in registros) {
      final String claveUnica =
          '${registro['reca']}_${registro['cod_metrica']}_${registro['sticker']}';
      final String horaFinActual = registro['hora_fin']?.toString() ?? '';

      if (!registrosUnicos.containsKey(claveUnica) ||
          (registrosUnicos[claveUnica]?['hora_fin']?.toString() ?? '')
                  .compareTo(horaFinActual) <
              0) {
        registrosUnicos[claveUnica] = registro;
      }
    }

    return registrosUnicos.values.toList();
  }

  Future<void> _exportDataToCSV(
      BuildContext context, List<Map<String, dynamic>> registros) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      // 1. Depurar los datos
      final registrosDepurados = await _depurarDatos(registros);

      // 2. Encabezados
      final headers = registrosDepurados.first.keys.toList();

      // 3. Convertir filas
      final rows = registrosDepurados.map((registro) {
        return headers.map((header) {
          final value = registro[header];
          if (value is double || value is num) {
            return value.toString();
          } else {
            return value?.toString() ?? '';
          }
        }).toList();
      }).toList();

      rows.insert(0, headers);

      // 4. Generar CSV
      final csv = ListToCsvConverter(
        fieldDelimiter: ';',
        textDelimiter: '"',
      ).convert(rows);
      final csvBytes = utf8.encode(csv);

      // 5. Guardar archivo
      final internalDir = await getApplicationDocumentsDirectory();
      final csvDir = Directory('${internalDir.path}/csv_servicios');
      if (!await csvDir.exists()) await csvDir.create(recursive: true);

      final fileName =
          '${widget.secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
      final internalFile = File('${csvDir.path}/$fileName');
      await internalFile.writeAsBytes(csvBytes);

      // 6. Preguntar carpeta destino
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$fileName');
        await userFile.writeAsBytes(csvBytes, mode: FileMode.write);
        _showSnackBar(context, 'Archivo CSV exportado a: ${userFile.path}');
      } else {
        _showSnackBar(context, 'Exportación CSV cancelada.', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error al exportar CSV: $e', isError: true);
    } finally {
      _isExporting = false;
    }
  }

  Future<void> _exportDataToTXT(
      BuildContext context, List<Map<String, dynamic>> registros) async {
    try {
      final registrosDepurados = await _depurarDatos(registros);

      final headers = registrosDepurados.first.keys.toList();

      // 1. Convertir filas → formato plano separado por |
      final lines = <String>[];
      lines.add(headers.join(' | ')); // encabezado

      for (final row in registrosDepurados) {
        final values = headers.map((h) => (row[h] ?? '').toString()).toList();
        lines.add(values.join(' | '));
      }

      final txtContent = lines.join('\n');

      // 2. Guardar archivo
      final internalDir = await getApplicationDocumentsDirectory();
      final txtDir = Directory('${internalDir.path}/txt_servicios');
      if (!await txtDir.exists()) await txtDir.create(recursive: true);

      final fileName =
          '${widget.secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.txt';
      final internalFile = File('${txtDir.path}/$fileName');
      await internalFile.writeAsString(txtContent);

      // 3. Preguntar carpeta destino
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino para TXT',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$fileName');
        await userFile.writeAsString(txtContent);
        _showSnackBar(context, 'Archivo TXT exportado a: ${userFile.path}');
      } else {
        _showSnackBar(context, 'Exportación TXT cancelada.', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error al exportar TXT: $e', isError: true);
    }
  }


  Future<void> _confirmarSeleccionOtraBalanza(BuildContext context) async {
    final bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMAR ACCIÓN',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
          ),
          content: const Text('¿Está seguro que desea seleccionar otra balanza?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Sí, continuar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

      // 1) Trae TODAS las filas de la sesión actual, de la más reciente a la más antigua
      final List<Map<String, dynamic>> rows = await db.query(
          'registros_calibracion',
          where: 'seca = ? AND session_id = ?',
          whereArgs: [widget.secaValue, widget.sessionId],
          orderBy: 'id DESC' // usa 'hora_fin DESC' si no tienes 'id' autoincrement
      );

      // 2) Genera un nuevo sessionId
      final nuevoSessionId = await dbHelper.generateSessionId(widget.secaValue);

      // 3) Registro base
      final Map<String, dynamic> nuevoRegistro = {
        'seca': widget.secaValue,
        'session_id': nuevoSessionId,
        'fecha_servicio': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };

      // 4) Columnas de “cabecera” que quieres arrastrar
      const columnsToCarry = [
        'cliente', 'razon_social', 'planta', 'dir_planta',
        'dep_planta', 'cod_planta', 'personal',
        'equipo6', 'certificado6', 'ente_calibrador6', 'estado6', 'cantidad6',
        'equipo7', 'certificado7', 'ente_calibrador7', 'estado7', 'cantidad7',
      ];

      // 5) Para cada columna, toma el último valor NO NULO / NO VACÍO
      for (final col in columnsToCarry) {
        for (final row in rows) { // rows ya está DESC: último ingresado primero
          final v = row[col];
          if (v != null && (v is! String || v.toString().trim().isNotEmpty)) {
            nuevoRegistro[col] = v;
            break; // pasa a la siguiente columna
          }
        }
      }

      // 6) Inserta el nuevo registro “cabecera” con la nueva sesión
      await dbHelper.upsertRegistroCalibracion(nuevoRegistro);

      // 7) Datos para la navegación
      final selectedCliente = (nuevoRegistro['cliente'] ?? '').toString();
      final selectedPlantaCodigo = (nuevoRegistro['cod_planta'] ?? '').toString();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IdenBalanzaScreen(
            secaValue: widget.secaValue,
            sessionId: nuevoSessionId,
            selectedPlantaCodigo: selectedPlantaCodigo,
            selectedCliente: selectedCliente,
            loadFromSharedPreferences: false,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(context, 'Error al preparar nueva balanza: $e', isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardOpacity = isDarkMode ? 0.4 : 0.2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'CALIBRACIÓN',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDarkMode
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              )
            : null,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 30,
          left: 16.0, // Tu padding horizontal original
          right: 16.0, // Tu padding horizontal original
          bottom: 16.0, // Tu padding inferior original
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30.0),
              _buildInfoSection(
                'FINALIZAR SERVICIO',
                'Al dar clic se finalizará el servicio de calibración y se exportarán los datos a archivos CSV y TXT.',
                textColor,
              ),
              _buildActionCard(
                'images/tarjetas/t4.png',
                'FINALIZAR SERVICIO\nY EXPORTAR DATOS',
                    () => _confirmarYExportar(context),
                textColor,
                cardOpacity,
              ),
              const SizedBox(height: 40),
              _buildInfoSection(
                'SELECCIONAR OTRA BALANZA',
                'Al dar clic se volverá a la pantalla de identificación de balanza para seleccionar otra balanza.',
                textColor,
              ),
              _buildActionCard(
                'images/tarjetas/t7.png',
                'SELECCIONAR\nOTRA BALANZA',
                () => _confirmarSeleccionOtraBalanza(context),
                textColor,
                cardOpacity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String description, Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: textColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionCard(
    String imagePath,
    String title,
    VoidCallback onTap,
    Color textColor,
    double opacity,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 300,
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.black.withOpacity(opacity),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 6.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
