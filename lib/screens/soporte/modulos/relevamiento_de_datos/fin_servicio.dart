import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:service_met/home_screen.dart';
import 'package:service_met/screens/soporte/modulos/iden_balanza.dart';
import 'package:service_met/bdb/calibracion_bd.dart';

class FinServicioScreen extends StatefulWidget {
  final String dbName;
  final String dbPath;
  final String otValue;
  final String selectedCliente;
  final String selectedPlantaNombre;
  final String codMetrica;

  const FinServicioScreen({
    super.key,
    required this.dbName,
    required this.dbPath,
    required this.otValue,
    required this.selectedCliente,
    required this.selectedPlantaNombre,
    required this.codMetrica,
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
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _exportDataToCSV(BuildContext context) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Procesando datos...'),
            ],
          ),
        ),
      );

      // 1. Abrir la base de datos
      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      // 2. Consulta para unir las tablas
      final List<Map<String, dynamic>> registros = await db.rawQuery('''
        SELECT *
        FROM inf_cliente_balanza AS icb
        LEFT JOIN relevamiento_de_datos AS rdd
        ON icb.cod_metrica = rdd.cod_metrica
      ''');

      // 3. Depurar los datos
      final List<Map<String, dynamic>> registrosDepurados =
          await _depurarDatos(registros);

      if (registrosDepurados.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        _showSnackBar(context, 'No hay datos para exportar', isError: true);
        return;
      }

      // 4. Preparar encabezados y filas
      Set<String> uniqueKeys = {};
      List<String> headers = [];

      for (var registro in registrosDepurados) {
        for (var key in registro.keys) {
          if (!uniqueKeys.contains(key)) {
            uniqueKeys.add(key);
            headers.add(key);
          }
        }
      }

      List<List<dynamic>> rows = [];
      rows.add(headers);

      for (var registro in registrosDepurados) {
        List<dynamic> row = [];
        for (var header in headers) {
          final value = registro[header];
          if (value is double) {
            row.add(value.toString());
          } else if (value is num) {
            row.add(value.toString());
          } else {
            row.add(value?.toString() ?? '');
          }
        }
        rows.add(row);
      }

      // 5. Generar CSV
      String csv =
          const ListToCsvConverter(fieldDelimiter: ';', textDelimiter: '"')
              .convert(rows);
      final csvBytes = utf8.encode(csv);

      // 6. Guardar en directorio interno
      final internalDir = await getApplicationSupportDirectory();
      final internalCsvDir = Directory('${internalDir.path}/csv_servicios');
      if (!await internalCsvDir.exists()) {
        await internalCsvDir.create(recursive: true);
      }

      final internalFileName =
          '${widget.dbName}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}_relevamiento_de_datos.csv';
      final internalFile = File('${internalCsvDir.path}/$internalFileName');
      await internalFile.writeAsBytes(csvBytes);

      // 7. Permitir al usuario elegir ubicación adicional
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de carga

      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccione carpeta para guardar el archivo',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$internalFileName');
        await userFile.writeAsBytes(csvBytes);
        _showSnackBar(
            context, 'Archivo guardado en: $directoryPath/$internalFileName');
      } else {
        _showSnackBar(context, 'Exportación completada (guardado localmente)');
      }

      // 8. Crear respaldo automático
      await _crearRespaldoAutomatico(csvBytes, internalFileName);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de carga en caso de error
      _showSnackBar(context, 'Error al exportar: ${e.toString()}',
          isError: true);
      debugPrint('Error al exportar CSV: $e');
    } finally {
      _isExporting = false;
    }
  }

  Future<void> _crearRespaldoAutomatico(
      List<int> csvBytes, String fileName) async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final backupDir =
            Directory('${externalDir.path}/RespaldoSM/CSV_Automaticos');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        final backupFile = File('${backupDir.path}/$fileName');
        await backupFile.writeAsBytes(csvBytes);
      }
    } catch (e) {
      debugPrint('Error al crear respaldo automático: $e');
    }
  }

  Future<void> _confirmarSeleccionOtraBalanza(BuildContext context) async {
    final bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMAR ACCIÓN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Está seguro que desea seleccionar otra balanza?'),
              SizedBox(height: 10),
              Text('Se generará un respaldo CSV antes de continuar.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Sí, continuar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Preparando datos para nueva balanza...'),
            ],
          ),
        ),
      );

      try {
        await _exportBackupCSV();
        await _copyDataFromId1();

        if (!mounted) return;
        Navigator.of(context).pop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IdenBalanzaScreen(
              dbName: widget.dbName,
              dbPath: widget.dbPath,
              otValue: widget.otValue,
              selectedPlantaCodigo: '',
              selectedCliente: widget.selectedCliente,
              selectedPlantaNombre: widget.selectedPlantaNombre,
              loadFromSharedPreferences: true,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        _showSnackBar(context, 'Error al preparar nueva balanza: $e',
            isError: true);
      }
    }
  }

  Future<void> _exportBackupCSV() async {
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      final List<Map<String, dynamic>> registros = await db.rawQuery('''
        SELECT *
        FROM inf_cliente_balanza AS icb
        LEFT JOIN relevamiento_de_datos AS rdd
        ON icb.cod_metrica = rdd.cod_metrica
      ''');

      final List<Map<String, dynamic>> registrosDepurados =
          await _depurarDatos(registros);
      if (registrosDepurados.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      Set<String> uniqueKeys = {};
      List<String> headers = [];

      for (var registro in registrosDepurados) {
        for (var key in registro.keys) {
          if (!uniqueKeys.contains(key)) {
            uniqueKeys.add(key);
            headers.add(key);
          }
        }
      }

      List<List<dynamic>> rows = [];
      rows.add(headers);
      for (var registro in registrosDepurados) {
        List<dynamic> row = [];
        for (var header in headers) {
          final value = registro[header];
          row.add(value?.toString() ?? '');
        }
        rows.add(row);
      }

      String csv =
          const ListToCsvConverter(fieldDelimiter: ';', textDelimiter: '"')
              .convert(rows);
      final csvBytes = utf8.encode(csv);

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final backupDir =
            Directory('${externalDir.path}/RespaldoSM/CSV_Automaticos');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }

        final fileName =
            '${widget.dbName}_auto_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
        final backupFile = File('${backupDir.path}/$fileName');
        await backupFile.writeAsBytes(csvBytes);
      }
    } finally {
      await db.close();
    }
  }

  Future<void> _copyDataFromId1() async {
    String path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'relevamiento_de_datos',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (result.isNotEmpty) {
        final Map<String, dynamic> data = Map.from(result.first);
        data.remove('id');

        final List<Map<String, dynamic>> allRows =
            await db.query('relevamiento_de_datos');
        final int nextId = allRows.isEmpty ? 2 : allRows.last['id'] + 1;

        await db.insert('relevamiento_de_datos', {...data, 'id': nextId});

        final List<Map<String, dynamic>> tableInfo =
            await db.rawQuery('PRAGMA table_info(relevamiento_de_datos)');
        final List<String> allColumns =
            tableInfo.map((col) => col['name'] as String).toList();

        final Map<String, dynamic> emptyData = {};
        for (final column in allColumns) {
          if (column != 'id') {
            emptyData[column] = '';
          }
        }

        await db.update(
          'relevamiento_de_datos',
          emptyData,
          where: 'id = ?',
          whereArgs: [1],
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error copiando datos: $e';
      });
    } finally {
      await db.close();
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Creando respaldo de la base de datos...'),
            ],
          ),
        ),
      );

      final dbPath = join(widget.dbPath, '${widget.dbName}.db');
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception("No se pudo acceder al almacenamiento externo");
      }

      final backupDir =
          Directory('${externalDir.path}/RespaldoSM/Database_Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final formattedDate =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final backupPath =
          join(backupDir.path, '${widget.dbName}_backup_$formattedDate.db');

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnackBar(context, 'RESPALDO REALIZADO CORRECTAMENTE');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnackBar(context, 'ERROR AL REALIZAR EL RESPALDO: $e',
          isError: true);
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
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'SOPORTE TÉCNICO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              'CLIENTE: ${widget.selectedPlantaNombre}\nCÓDIGO: ${widget.codMetrica}',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
          left: 16.0, // Tu padding horizontal original
          right: 16.0, // Tu padding horizontal original
          bottom: 16.0, // Tu padding inferior original
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoSection(
              'EXPORTAR CSV',
              'Al dar clic se generará el archivo CSV con todos los datos registrados del módulo de RELEVAMIENTO DE DATOS, si pasara a otro módulo, debe generar el archivo CSV antes de continuar.',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t4.png',
              'EXPORTAR CSV',
              () => _exportDataToCSV(context),
              textColor,
              cardOpacity,
            ),
            const SizedBox(height: 40),
            _buildInfoSection(
              'SELECCIONAR OTRA BALANZA',
              'Al dar clic se volverá a la pantalla de identificación de balanza para seleccionar otra balanza del cliente seleccionado.',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t7.png',
              'SELECCIONAR OTRA BALANZA',
              () => _confirmarSeleccionOtraBalanza(context),
              textColor,
              cardOpacity,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _backupDatabase(context);
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFdf0000),
              ),
              child: const Text(
                'FINALIZAR SERVICIO',

              ),
            ),
          ],
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
          width: 350,
          height: 200,
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
                      style: TextStyle(
                        fontSize: 20,
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
                    ),
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
