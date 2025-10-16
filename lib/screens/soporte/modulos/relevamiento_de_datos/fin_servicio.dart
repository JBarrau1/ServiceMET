import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:service_met/home_screen.dart';
import 'package:service_met/screens/soporte/modulos/iden_balanza.dart';

import '../../../../bdb/soporte_tecnico_bd.dart';

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

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ---- NUEVO: Copia todas las filas de tablas origen a la BD interna "servicios_soporte_tecnino.db"
  /// Inserta sucesivamente (removiendo 'id' si existe).
  Future<void> _copyToInternalDatabase() async {
    final srcPath = join(widget.dbPath, '${widget.dbName}.db');
    Database? src;

    try {
      // Abrimos la DB de origen en solo lectura
      src = await openDatabase(srcPath, readOnly: true);

      // Usamos SIEMPRE la conexión del helper
      final dest = await DatabaseHelperSop().database;

      // Ajusta las tablas a copiar según tu esquema
      final tablesToCopy = ['inf_cliente_balanza', 'relevamiento_de_datos'];

      for (final table in tablesToCopy) {
        // Leemos filas del origen
        final srcRows = await src.query(table);

        if (srcRows.isEmpty) continue;

        // Obtenemos columnas válidas en destino para esa tabla
        final destColsInfo = await dest.rawQuery('PRAGMA table_info($table)');
        if (destColsInfo.isEmpty) {
          debugPrint('Tabla $table no existe en la DB interna; omitiendo copia.');
          continue;
        }

        final destCols = destColsInfo.map((c) => (c['name'] as String)).toSet();
        final hasId = destCols.contains('id');

        // CORREGIDO: Primero eliminamos registros existentes de esta sesión/cod_metrica
        await dest.delete(table,
            where: 'cod_metrica = ?',
            whereArgs: [widget.codMetrica]
        );

        // Insertamos en transacción
        await dest.transaction((txn) async {
          for (final row in srcRows) {
            final data = Map<String, dynamic>.from(row);

            // Eliminamos 'id' si existe para respetar AUTOINCREMENT en destino
            if (hasId) data.remove('id');

            // Filtramos a solo columnas que existen en destino
            data.removeWhere((k, _) => !destCols.contains(k));

            if (data.isNotEmpty) {
              await txn.insert(table, data);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error copiando a BD interna (helper): $e');
      rethrow;
    } finally {
      await src?.close();
    }
  }

  /// ---- NUEVO: Construye un JOIN con alias para evitar colisiones de columnas en SELECT *
  Future<Map<String, dynamic>> _buildAliasedJoin(Database db) async {
    try {
      final icbColsInfo = await db.rawQuery('PRAGMA table_info(inf_cliente_balanza)');
      final rddColsInfo = await db.rawQuery('PRAGMA table_info(relevamiento_de_datos)');

      final icbCols = icbColsInfo.map((c) => c['name'] as String).toList();
      final rddCols = rddColsInfo.map((c) => c['name'] as String).toList();

      // ✅ NUEVO: Excluir columnas duplicadas de la segunda tabla
      final columnasExcluir = {'id', 'cod_metrica'};
      final rddColsFiltered = rddCols.where((c) => !columnasExcluir.contains(c)).toList();

      // Seleccionar todas las columnas de icb
      final icbSelect = icbCols.map((c) => 'icb."$c" AS icb_$c').join(', ');
      // Solo columnas no duplicadas de rdd
      final rddSelect = rddColsFiltered.map((c) => 'rdd."$c" AS rdd_$c').join(', ');

      final sql = '''
      SELECT $icbSelect, $rddSelect
      FROM inf_cliente_balanza icb
      LEFT JOIN relevamiento_de_datos rdd
        ON icb.cod_metrica = rdd.cod_metrica
      WHERE icb.cod_metrica = ?
    ''';

      debugPrint('SQL Query: $sql');
      final rawRows = await db.rawQuery(sql, [widget.codMetrica]);
      debugPrint('Filas obtenidas: ${rawRows.length}');

      final processedRows = rawRows.map((row) {
        final processedRow = <String, dynamic>{};

        // Mapear columnas de inf_cliente_balanza
        for (final col in icbCols) {
          final aliasedKey = 'icb_$col';
          if (row.containsKey(aliasedKey)) {
            processedRow[col] = row[aliasedKey];
          }
        }

        // Mapear solo columnas no duplicadas de relevamiento_de_datos
        for (final col in rddColsFiltered) {
          final aliasedKey = 'rdd_$col';
          if (row.containsKey(aliasedKey)) {
            processedRow[col] = row[aliasedKey];
          }
        }

        return processedRow;
      }).toList();

      return {
        'icbCols': icbCols,
        'rddCols': rddColsFiltered,  // ✅ Retornar solo las columnas filtradas
        'rows': processedRows,
      };
    } catch (e) {
      debugPrint('Error en _buildAliasedJoin: $e');
      rethrow;
    }
  }


  /// ---- NUEVO: Dedupe básico por (reca, cod_metrica, sticker) y elige el más "reciente" por hora_fin
  List<Map<String, dynamic>> _dedupeRegistros(List<Map<String, dynamic>> regs) {
    // Filtrar registros completamente vacíos
    regs.removeWhere((r) => r.values.every((v) => v == null || v.toString().trim().isEmpty));

    debugPrint('Registros antes de deduplicar: ${regs.length}');

    final Map<String, Map<String, dynamic>> unicos = {};

    for (final r in regs) {
      // CORREGIDO: Usar nombres originales sin prefijos
      final reca = (r['reca'] ?? '').toString().trim();
      final cod = (r['cod_metrica'] ?? '').toString().trim();
      final stick = (r['sticker'] ?? '').toString().trim();
      final horaFin = (r['hora_fin'] ?? '').toString().trim();

      final clave = '$reca|$cod|$stick';

      if (!unicos.containsKey(clave)) {
        unicos[clave] = r;
      } else {
        // Si ya existe, comparar por hora_fin (mantener el más reciente)
        final horaExistente = (unicos[clave]!['hora_fin'] ?? '').toString().trim();
        if (horaFin.compareTo(horaExistente) > 0) {
          unicos[clave] = r;
        }
      }
    }

    debugPrint('Registros después de deduplicar: ${unicos.length}');
    return unicos.values.toList();
  }

  /// ---- NUEVO: Exporta CSV + TXT + MET y empaqueta en ZIP (tras copiar a BD interna).
  Future<void> _exportAllAndZip(BuildContext context) async {
    if (_isExporting) return;
    _isExporting = true;

    Database? db;
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Copiando a base interna y generando exportables...'),
              ],
            ),
          ),
        );
      }

      // 1) Copiar a BD interna antes de exportar
      await _copyToInternalDatabase();

      // 2) Armar datos para CSV/TXT a partir de JOIN con alias
      final srcPath = join(widget.dbPath, '${widget.dbName}.db');
      db = await openDatabase(srcPath);

      final aliased = await _buildAliasedJoin(db);
      final icbCols = (aliased['icbCols'] as List).cast<String>();
      final rddCols = (aliased['rddCols'] as List).cast<String>();
      final rows = (aliased['rows'] as List).cast<Map<String, dynamic>>();

      debugPrint('Datos obtenidos del JOIN: ${rows.length} filas');

      final depurados = _dedupeRegistros(rows);
      if (depurados.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSnackBar(context, 'No hay datos para exportar', isError: true);
        }
        return;
      }

      // 3) CORREGIDO: Headers con nombres originales de las columnas (SIN prefijos)
      final headers = [
        ...icbCols,  // Nombres originales de inf_cliente_balanza
        ...rddCols,  // Nombres originales de relevamiento_de_datos
      ];

      debugPrint('Headers generados: ${headers.length}');
      debugPrint('Primeros headers: ${headers.take(5).toList()}');

      // 4) CORREGIDO: Matriz de datos usando nombres originales
      final matrix = <List<dynamic>>[
        headers,  // Headers con nombres originales
        ...depurados.map((reg) {
          final row = headers.map((header) {
            final value = reg[header];  // Usar nombre original directamente
            return (value is num) ? value.toString() : (value?.toString() ?? '');
          }).toList();
          return row;
        })
      ];

      debugPrint('Matriz generada: ${matrix.length} filas (incluyendo header)');
      if (matrix.length > 1) {
        debugPrint('Primera fila de datos: ${matrix[1].take(5).toList()}');
      }

      // 5) CSV y TXT (ambos ; como separador)
      final csvString = const ListToCsvConverter(
        fieldDelimiter: ';',
        textDelimiter: '"',
      ).convert(matrix);
      final txtString = matrix.map((row) => row.map((e) => e.toString()).join(';')).join('\n');

      final csvBytes = utf8.encode(csvString);
      final txtBytes = utf8.encode(txtString);

      // 6) MET = copia binaria de la .db con extensión .met
      final dbFileBytes = await File(srcPath).readAsBytes();

      // 7) Empaquetar a ZIP con mismo nombre base
      final now = DateTime.now();
      final baseName =
          '${widget.dbName}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(now)}_relevamiento_de_datos';

      final csvName = '$baseName.csv';
      final txtName = '$baseName.txt';
      final metName = '$baseName.met';
      final zipName = '$baseName.zip';

      final archive = Archive()
        ..addFile(ArchiveFile(csvName, csvBytes.length, csvBytes))
        ..addFile(ArchiveFile(txtName, txtBytes.length, txtBytes))
        ..addFile(ArchiveFile(metName, dbFileBytes.length, dbFileBytes));

      final zipData = ZipEncoder().encode(archive)!;

      // 8) Guardar ZIP internamente (por si el usuario cancela el picker)
      final internalDir = await getApplicationSupportDirectory();
      final bundleDir = Directory('${internalDir.path}/export_bundles');
      if (!await bundleDir.exists()) {
        await bundleDir.create(recursive: true);
      }
      final internalZipPath = join(bundleDir.path, zipName);
      await File(internalZipPath).writeAsBytes(zipData);

      // 9) Elegir carpeta destino para guardar el ZIP
      if (mounted) Navigator.of(context).pop();
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccione carpeta para guardar el ZIP',
      );

      if (directoryPath != null) {
        final outZip = File(join(directoryPath, zipName));
        await outZip.writeAsBytes(zipData);
        if (mounted) {
          _showSnackBar(context, 'ZIP guardado en: ${outZip.path}');
        }
      } else {
        if (mounted) {
          _showSnackBar(
            context,
            'Exportación completada (ZIP guardado internamente en: $internalZipPath)',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // cerrar diálogo si estaba abierto
        _showSnackBar(context, 'Error en exportación: $e', isError: true);
      }
      debugPrint('ExportAllAndZip error: $e');
    } finally {
      await db?.close();
      _isExporting = false;
    }
  }

  Future<void> _confirmarSeleccionOtraBalanza(BuildContext context) async {
    final bool? confirmado = await showDialog<bool>(
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
              Text(
                'Se generará un respaldo CSV antes de continuar.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, continuar'),
            ),
          ],
        );
      },
    );

    // Verificar si el usuario confirmó la acción
    if (confirmado != true) return;

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const AlertDialog(
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
      // Copiar los datos a la base de datos interna
      await _copyToInternalDatabase();

      // Exportar los datos a CSV, TXT y MET, y crear el ZIP
      await _exportAllAndZip(context);

      // Cerrar el diálogo de progreso si el widget sigue montado
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navegar a la pantalla de selección de balanza
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => IdenBalanzaScreen(
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
      }
    } catch (e) {
      // Cerrar el diálogo de progreso si ocurre un error
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (mounted) {
        _showSnackBar(
          context,
          'Error al preparar nueva balanza: ${e.toString()}',
          isError: true,
        );
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

      final List<Map<String, dynamic>> registrosDepurados = _dedupeRegistros(registros);
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
      const ListToCsvConverter(fieldDelimiter: ';', textDelimiter: '"').convert(rows);
      final csvBytes = utf8.encode(csv);

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final backupDir = Directory('${externalDir.path}/RespaldoSM/CSV_Automaticos');
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
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      await db.transaction((txn) async {
        final res = await txn.query('relevamiento_de_datos', where: 'id = ?', whereArgs: [1]);
        if (res.isEmpty) return;

        final data = Map.of(res.first)..remove('id');

        final maxRow =
        await txn.rawQuery('SELECT COALESCE(MAX(id), 1) AS max_id FROM relevamiento_de_datos');
        final nextId = ((maxRow.first['max_id'] as int) + 1);

        await txn.insert('relevamiento_de_datos', {...data, 'id': nextId});

        final colsInfo = await txn.rawQuery('PRAGMA table_info(relevamiento_de_datos)');
        final allCols = colsInfo.map((c) => c['name'] as String).toList();
        final emptyData = {for (final c in allCols) if (c != 'id') c: ''};

        await txn.update('relevamiento_de_datos', emptyData, where: 'id = ?', whereArgs: [1]);
      });
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

      final backupDir = Directory('${externalDir.path}/RespaldoSM/Database_Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final formattedDate =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final backupPath = join(backupDir.path, '${widget.dbName}_backup_$formattedDate.db');

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
      _showSnackBar(context, 'ERROR AL REALIZAR EL RESPALDO: $e', isError: true);
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
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 40,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoSection(
              'EXPORTAR',
              'Generará un ZIP con CSV, TXT (ambos con ;) y una copia MET de la base. '
                  'Antes de exportar se replicarán los datos en la BD interna "servicios_soporte_tecnino.db".',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t4.png',
              'EXPORTAR',
                  () => _exportAllAndZip(context),
              textColor,
              cardOpacity,
            ),
            const SizedBox(height: 40),
            _buildInfoSection(
              'SELECCIONAR OTRA BALANZA',
              'Volverá a la pantalla de identificación para seleccionar otra balanza del cliente. '
                  'Se generará un CSV de respaldo automático antes de continuar.',
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
              child: const Text('FINALIZAR SERVICIO'),
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
                        fontSize: 18,
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
