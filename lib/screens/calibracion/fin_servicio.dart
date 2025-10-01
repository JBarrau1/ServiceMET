import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_met/screens/calibracion/precarga/precarga_screen.dart';
import 'package:service_met/screens/calibracion/precarga/widgets/balanza_step.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart'; // Añadir esta dependencia
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

  String? _selectedEmp23001;
  final TextEditingController _indicarController = TextEditingController();
  final TextEditingController _factorSeguridadController = TextEditingController();
  String? _selectedReglaAceptacion;

  @override
  void dispose() {
    _indicarController.dispose();
    _factorSeguridadController.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> _showAdditionalDataDialog(BuildContext context) async {
    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'DATOS ADICIONALES PARA EXPORTACIÓN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'EMP NB 23001',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedEmp23001,
                      items: ['Sí', 'No'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedEmp23001 = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _indicarController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Indicar (%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _factorSeguridadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Factor Seguridad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Regla de Aceptación',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedReglaAceptacion,
                      items: ['Ninguna', 'Simple', 'Conservadora'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedReglaAceptacion = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46824B),
                  ),
                  onPressed: () {
                    if (_selectedEmp23001 == null ||
                        _indicarController.text.isEmpty ||
                        _factorSeguridadController.text.isEmpty ||
                        _selectedReglaAceptacion == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete todos los campos'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx, {
                      'emp': _selectedEmp23001!,
                      'indicar': _indicarController.text,
                      'factor': _factorSeguridadController.text,
                      'regla_aceptacion': _selectedReglaAceptacion!,
                    });
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  /// CONFIRMAR Y EXPORTAR (muestra diálogo antes de exportar)
  Future<void> _confirmarYExportar(BuildContext context) async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;

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

      // 1. Solicitar datos adicionales
      final additionalData = await _showAdditionalDataDialog(context);
      if (additionalData == null) {
        return; // Usuario canceló
      }

      // 2. Actualizar registros con datos adicionales
      for (final row in rows) {
        await db.update(
          'registros_calibracion',
          {
            'emp': additionalData['emp'],
            'indicar': additionalData['indicar'],
            'factor': additionalData['factor'],
            'regla_aceptacion': additionalData['regla_aceptacion'],
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }

      // 3. Obtener rows actualizados
      final updatedRows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND estado_servicio_bal = ?',
        whereArgs: [widget.secaValue, 'Balanza Calibrada'],
      );

      // 4. Mostrar confirmación de exportación
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Confirmar exportación'.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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

      await _exportToZip(context, updatedRows);

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

  /// EXPORTAR TODO EN UN ARCHIVO ZIP
  Future<void> _exportToZip(
      BuildContext context, List<Map<String, dynamic>> registros) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      // 1. Depurar los datos
      final registrosDepurados = await _depurarDatos(registros);

      // 2. Crear el nombre base para los archivos
      final baseFileName =
          '${widget.secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}';

      // 3. Crear el archivo ZIP
      final archive = Archive();

      // 4. Generar y añadir CSV al ZIP
      final csvBytes = await _generateCSVBytes(registrosDepurados);
      archive
          .addFile(ArchiveFile('$baseFileName.csv', csvBytes.length, csvBytes));

      // 5. Generar y añadir TXT al ZIP
      final txtBytes = await _generateTXTBytes(registrosDepurados);
      archive
          .addFile(ArchiveFile('$baseFileName.txt', txtBytes.length, txtBytes));

      // 6. Generar y añadir SMET (DB) al ZIP
      final smetBytes = await _generateSMETBytes(registrosDepurados);
      archive.addFile(
          ArchiveFile('$baseFileName.met', smetBytes.length, smetBytes));

      // 7. Comprimir el archivo
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        throw Exception('Error al comprimir los archivos');
      }

      // 8. Guardar archivo ZIP internamente
      final internalDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${internalDir.path}/export_servicios');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);

      final zipFileName = '$baseFileName.zip';
      final internalZipFile = File('${exportDir.path}/$zipFileName');
      await internalZipFile.writeAsBytes(zipBytes);

      // 9. Preguntar carpeta destino UNA SOLA VEZ
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino para exportación',
      );

      if (directoryPath != null) {
        final userZipFile = File('$directoryPath/$zipFileName');
        await userZipFile.writeAsBytes(zipBytes, mode: FileMode.write);
        _showSnackBar(context, 'Archivo ZIP exportado a: ${userZipFile.path}');
      } else {
        _showSnackBar(context, 'Exportación cancelada.', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error al exportar ZIP: $e', isError: true);
    } finally {
      _isExporting = false;
    }
  }

  /// GENERAR BYTES DEL CSV
  Future<List<int>> _generateCSVBytes(
      List<Map<String, dynamic>> registros) async {
    final headers = registros.first.keys.toList();

    final rows = registros.map((registro) {
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

    final csv = ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
    ).convert(rows);

    return utf8.encode(csv);
  }

  /// GENERAR BYTES DEL TXT (ahora con ; y "")
  Future<List<int>> _generateTXTBytes(
      List<Map<String, dynamic>> registros) async {
    final headers = registros.first.keys.toList();

    // Crear líneas con formato CSV pero para TXT
    final lines = <String>[];

    // Encabezado con comillas y punto y coma
    final headerLine = headers.map((h) => '"$h"').join(';');
    lines.add(headerLine);

    // Datos con comillas y punto y coma
    for (final row in registros) {
      final values = headers.map((h) {
        final value = row[h]?.toString() ?? '';
        return '"$value"'; // Envolver cada valor en comillas
      }).toList();
      lines.add(values.join(';'));
    }

    final txtContent = lines.join('\n');
    return utf8.encode(txtContent);
  }

  /// GENERAR BYTES DEL SMET (BASE DE DATOS)
  Future<List<int>> _generateSMETBytes(
      List<Map<String, dynamic>> registros) async {
    // Crear una base de datos temporal
    final internalDir = await getApplicationDocumentsDirectory();
    final tempDbPath = '${internalDir.path}/temp_export.db';

    // Eliminar archivo temporal si existe
    final tempDbFile = File(tempDbPath);
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }

    // Crear nueva base de datos
    final tempDb = await openDatabase(
      tempDbPath,
      version: 1,
      onCreate: (db, version) async {
        // Crear la tabla con la misma estructura
        await db.execute('''
          CREATE TABLE registros_calibracion (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT DEFAULT '',
            razon_social TEXT DEFAULT '',
            planta TEXT DEFAULT '',
            dir_planta TEXT DEFAULT '',
            dep_planta TEXT DEFAULT '',
            cod_planta TEXT DEFAULT '',
            personal TEXT DEFAULT '',
            seca TEXT DEFAULT '',
            session_id TEXT DEFAULT '',
            n_reca TEXT DEFAULT '',
            sticker TEXT DEFAULT '',
            equipo1 TEXT DEFAULT '',
            certificado1 TEXT DEFAULT '',
            ente_calibrador1 TEXT DEFAULT '',
            estado1 TEXT DEFAULT '',
            cantidad1 REAL DEFAULT '',
            equipo2 TEXT DEFAULT '',
            certificado2 TEXT DEFAULT '',
            ente_calibrador2 TEXT DEFAULT '',
            estado2 TEXT DEFAULT '',
            cantidad2 REAL DEFAULT '',
            equipo3 TEXT DEFAULT '',
            certificado3 TEXT DEFAULT '',
            ente_calibrador3 TEXT DEFAULT '',
            estado3 TEXT DEFAULT '',
            cantidad3 REAL DEFAULT '',
            equipo4 TEXT DEFAULT '',
            certificado4 TEXT DEFAULT '',
            ente_calibrador4 TEXT DEFAULT '',
            estado4 TEXT DEFAULT '',
            cantidad4 REAL DEFAULT '',
            equipo5 TEXT DEFAULT '',
            certificado5 TEXT DEFAULT '',
            ente_calibrador5 TEXT DEFAULT '',
            estado5 TEXT DEFAULT '',
            cantidad5 REAL DEFAULT '',
            equipo6 TEXT DEFAULT '',
            certificado6 TEXT DEFAULT '',
            ente_calibrador6 TEXT DEFAULT '',
            estado6 TEXT DEFAULT '',
            cantidad6 REAL DEFAULT '',
            equipo7 TEXT DEFAULT '',
            certificado7 TEXT DEFAULT '',
            ente_calibrador7 TEXT DEFAULT '',
            estado7 TEXT DEFAULT '',
            cantidad7 REAL DEFAULT '',
            
            foto_balanza TEXT DEFAULT '',
            categoria_balanza TEXT DEFAULT '',
            cod_metrica TEXT DEFAULT '',
            cod_int TEXT DEFAULT '',
            tipo_equipo TEXT DEFAULT '',
            marca TEXT DEFAULT '',
            modelo TEXT DEFAULT '',
            serie TEXT DEFAULT '',
            unidades TEXT DEFAULT '',
            ubicacion TEXT DEFAULT '',
            cap_max1 REAL DEFAULT '',
            d1 REAL DEFAULT '',
            e1 REAL DEFAULT '',
            dec1 REAL DEFAULT '',
            cap_max2 REAL DEFAULT '',
            d2 REAL DEFAULT '',
            e2 REAL DEFAULT '',
            dec2 REAL DEFAULT '',
            cap_max3 REAL DEFAULT '',
            d3 REAL DEFAULT '',
            e3 REAL DEFAULT '',
            dec3 REAL DEFAULT '',
            fecha_servicio TEXT DEFAULT '',
            hora_inicio TEXT DEFAULT '',
            tiempo_estab TEXT DEFAULT '',
            t_ope_balanza TEXT DEFAULT '',
            vibracion TEXT DEFAULT '',
            vibracion_foto TEXT DEFAULT '',
            vibracion_comentario TEXT DEFAULT '',
            polvo TEXT DEFAULT '',
            polvo_foto TEXT DEFAULT '',
            polvo_comentario TEXT DEFAULT '',
            temp TEXT DEFAULT '',
            temp_foto TEXT DEFAULT '',
            temp_comentario TEXT DEFAULT '',
            humedad TEXT DEFAULT '',
            humedad_foto TEXT DEFAULT '',
            humedad_comentario TEXT DEFAULT '',
            mesada TEXT DEFAULT '',
            mesada_foto TEXT DEFAULT '',
            mesada_comentario TEXT DEFAULT '',
            iluminacion TEXT DEFAULT '',
            iluminacion_foto TEXT DEFAULT '',
            iluminacion_comentario TEXT DEFAULT '',
            limp_foza TEXT DEFAULT '',
            limp_foza_foto TEXT DEFAULT '',
            limp_foza_comentario TEXT DEFAULT '',
            estado_drenaje TEXT DEFAULT '',
            estado_drenaje_foto TEXT DEFAULT '',
            estado_drenaje_comentario TEXT DEFAULT '',
            limp_general TEXT DEFAULT '',
            limp_general_foto TEXT DEFAULT '',
            limp_general_comentario TEXT DEFAULT '',
            golpes_terminal TEXT DEFAULT '',
            golpes_terminal_foto TEXT DEFAULT '',
            golpes_terminal_comentario TEXT DEFAULT '',
            nivelacion TEXT DEFAULT '',
            nivelacion_foto TEXT DEFAULT '',
            nivelacion_comentario TEXT DEFAULT '',
            limp_recepto TEXT DEFAULT '',
            limp_recepto_foto TEXT DEFAULT '',
            limp_recepto_comentario TEXT DEFAULT '',
            golpes_receptor TEXT DEFAULT '',
            golpes_receptor_foto TEXT DEFAULT '',
            golpes_receptor_comentario TEXT DEFAULT '',
            encendido TEXT DEFAULT '',
            encendido_foto TEXT DEFAULT '',
            encendido_comentario TEXT DEFAULT '',
            precarga1 REAL DEFAULT '',
            p_indicador1 REAL DEFAULT '',
            precarga2 REAL DEFAULT '',
            p_indicador2 REAL DEFAULT '',
            precarga3 REAL DEFAULT '',
            p_indicador3 REAL DEFAULT '',
            precarga4 REAL DEFAULT '',
            p_indicador4 REAL DEFAULT '',
            precarga5 REAL DEFAULT '',
            p_indicador5 REAL DEFAULT '',
            precarga6 REAL DEFAULT '',
            p_indicador6 REAL DEFAULT '',
            ajuste TEXT DEFAULT '',
            tipo TEXT DEFAULT '',
            cargas_pesas TEXT DEFAULT '',
            hora TEXT DEFAULT '',
            hri TEXT DEFAULT '',
            ti TEXT DEFAULT '',
            patmi TEXT DEFAULT '',
            
            excentricidad_comentario TEXT DEFAULT '',
            tipo_plataforma TEXT DEFAULT '',
            puntos_ind TEXT DEFAULT '',
            carga TEXT DEFAULT '',
            posicion1 REAL DEFAULT '',
            indicacion1 REAL DEFAULT '',
            retorno1 REAL DEFAULT '',
            posicion2 REAL DEFAULT '',
            indicacion2 REAL DEFAULT '',
            retorno2 REAL DEFAULT '',
            posicion3 REAL DEFAULT '',
            indicacion3 REAL DEFAULT '',
            retorno3 REAL DEFAULT '',
            posicion4 REAL DEFAULT '',
            indicacion4 REAL DEFAULT '',
            retorno4 REAL DEFAULT '',
            posicion5 REAL DEFAULT '',
            indicacion5 REAL DEFAULT '',
            retorno5 REAL DEFAULT '',
            posicion6 REAL DEFAULT '',
            indicacion6 REAL DEFAULT '',
            retorno6 REAL DEFAULT '',
            
            repetibilidad_comentario TEXT DEFAULT '',
            repetibilidad1 REAL DEFAULT '',
            indicacion1_1 REAL DEFAULT '',
            retorno1_1 REAL DEFAULT '',      
            indicacion1_2 REAL DEFAULT '',
            retorno1_2 REAL DEFAULT '',
            indicacion1_3 REAL DEFAULT '',
            retorno1_3 REAL DEFAULT '',
            indicacion1_4 REAL DEFAULT '',
            retorno1_4 REAL DEFAULT '',
            indicacion1_5 REAL DEFAULT '',
            retorno1_5 REAL DEFAULT '',
            indicacion1_6 REAL DEFAULT '',
            retorno1_6 REAL DEFAULT '',
            indicacion1_7 REAL DEFAULT '',
            retorno1_7 REAL DEFAULT '',
            indicacion1_8 REAL DEFAULT '',
            retorno1_8 REAL DEFAULT '',
            indicacion1_9 REAL DEFAULT '',
            retorno1_9 REAL DEFAULT '',
            indicacion1_10 REAL DEFAULT '',
            retorno1_10 REAL DEFAULT '',
           
            repetibilidad2 REAL DEFAULT '',
            indicacion2_1 REAL DEFAULT '',
            retorno2_1 REAL DEFAULT '',
            indicacion2_2 REAL DEFAULT '',
            retorno2_2 REAL DEFAULT '',
            indicacion2_3 REAL DEFAULT '',
            retorno2_3 REAL DEFAULT '',
            indicacion2_4 REAL DEFAULT '',
            retorno2_4 REAL DEFAULT '',
            indicacion2_5 REAL DEFAULT '',
            retorno2_5 REAL DEFAULT '',
            indicacion2_6 REAL DEFAULT '',
            retorno2_6 REAL DEFAULT '',
            indicacion2_7 REAL DEFAULT '',
            retorno2_7 REAL DEFAULT '',
            indicacion2_8 REAL DEFAULT '',
            retorno2_8 REAL DEFAULT '',
            indicacion2_9 REAL DEFAULT '',
            retorno2_9 REAL DEFAULT '',
            indicacion2_10 REAL DEFAULT '',
            retorno2_10 REAL DEFAULT '',
            
            repetibilidad3 REAL DEFAULT '',
            indicacion3_1 REAL DEFAULT '',
            retorno3_1 REAL DEFAULT '',
            indicacion3_2 REAL DEFAULT '',
            retorno3_2 REAL DEFAULT '',
            indicacion3_3 REAL DEFAULT '',
            retorno3_3 REAL DEFAULT '',
            indicacion3_4 REAL DEFAULT '',
            retorno3_4 REAL DEFAULT '',
            indicacion3_5 REAL DEFAULT '',
            retorno3_5 REAL DEFAULT '',
            indicacion3_6 REAL DEFAULT '',
            retorno3_6 REAL DEFAULT '',
            indicacion3_7 REAL DEFAULT '',
            retorno3_7 REAL DEFAULT '',
            indicacion3_8 REAL DEFAULT '',
            retorno3_8 REAL DEFAULT '',
            indicacion3_9 REAL DEFAULT '',
            retorno3_9 REAL DEFAULT '',
            indicacion3_10 REAL DEFAULT '',
            retorno3_10 REAL DEFAULT '',
            
            linealidad_comentario TEXT DEFAULT '',
            metodo TEXT DEFAULT '',
            metodo_carga TEXT DEFAULT '',
            lin1 REAL DEFAULT '',
            ind1 REAL DEFAULT '',
            retorno_lin1 REAL DEFAULT '',
            lin2 REAL DEFAULT '',
            ind2 REAL DEFAULT '',
            retorno_lin2 REAL DEFAULT '',
            lin3 REAL DEFAULT '',
            ind3 REAL DEFAULT '',
            retorno_lin3 REAL DEFAULT '',
            lin4 REAL DEFAULT '',
            ind4 REAL DEFAULT '',
            retorno_lin4 REAL DEFAULT '',
            lin5 REAL DEFAULT '',
            ind5 REAL DEFAULT '',
            retorno_lin5 REAL DEFAULT '',
            lin6 REAL DEFAULT '',
            ind6 REAL DEFAULT '',
            retorno_lin6 REAL DEFAULT '',
            lin7 REAL DEFAULT '',
            ind7 REAL DEFAULT '',
            retorno_lin7 REAL DEFAULT '',
            lin8 REAL DEFAULT '',
            ind8 REAL DEFAULT '',
            retorno_lin8 REAL DEFAULT '',
            lin9 REAL DEFAULT '',
            ind9 REAL DEFAULT '',
            retorno_lin9 REAL DEFAULT '',
            lin10 REAL DEFAULT '',
            ind10 REAL DEFAULT '',
            retorno_lin10 REAL DEFAULT '',
            lin11 REAL DEFAULT '',
            ind11 REAL DEFAULT '',
            retorno_lin11 REAL DEFAULT '',
            lin12 REAL DEFAULT '',
            ind12 REAL DEFAULT '',
            retorno_lin12 REAL DEFAULT '',
            lin13 REAL DEFAULT '',
            ind13 REAL DEFAULT '',
            retorno_lin13 REAL DEFAULT '',
            lin14 REAL DEFAULT '',
            ind14 REAL DEFAULT '',
            retorno_lin14 REAL DEFAULT '',
            lin15 REAL DEFAULT '',
            ind15 REAL DEFAULT '',
            retorno_lin15 REAL DEFAULT '',
            lin16 REAL DEFAULT '',
            ind16 REAL DEFAULT '',
            retorno_lin16 REAL DEFAULT '',
            lin17 REAL DEFAULT '',
            ind17 REAL DEFAULT '',
            retorno_lin17 REAL DEFAULT '',
            lin18 REAL DEFAULT '',
            ind18 REAL DEFAULT '',
            retorno_lin18 REAL DEFAULT '',
            lin19 REAL DEFAULT '',
            ind19 REAL DEFAULT '',
            retorno_lin19 REAL DEFAULT '',
            lin20 REAL DEFAULT '',
            ind20 REAL DEFAULT '',
            retorno_lin20 REAL DEFAULT '',
            lin21 REAL DEFAULT '',
            ind21 REAL DEFAULT '',
            retorno_lin21 REAL DEFAULT '',
            lin22 REAL DEFAULT '',
            ind22 REAL DEFAULT '',
            retorno_lin22 REAL DEFAULT '',
            lin23 REAL DEFAULT '',
            ind23 REAL DEFAULT '',
            retorno_lin23 REAL DEFAULT '',
            lin24 REAL DEFAULT '',
            ind24 REAL DEFAULT '',
            retorno_lin24 REAL DEFAULT '',
            lin25 REAL DEFAULT '',
            ind25 REAL DEFAULT '',
            retorno_lin25 REAL DEFAULT '',
            lin26 REAL DEFAULT '',
            ind26 REAL DEFAULT '',
            retorno_lin26 REAL DEFAULT '',
            lin27 REAL DEFAULT '',
            ind27 REAL DEFAULT '',
            retorno_lin27 REAL DEFAULT '',
            lin28 REAL DEFAULT '',
            ind28 REAL DEFAULT '',
            retorno_lin28 REAL DEFAULT '',
            lin29 REAL DEFAULT '',
            ind29 REAL DEFAULT '',
            retorno_lin29 REAL DEFAULT '',
            lin30 REAL DEFAULT '',
            ind30 REAL DEFAULT '',
            retorno_lin30 REAL DEFAULT '',
            lin31 REAL DEFAULT '',
            ind31 REAL DEFAULT '',
            retorno_lin31 REAL DEFAULT '',
            lin32 REAL DEFAULT '',
            ind32 REAL DEFAULT '',
            retorno_lin32 REAL DEFAULT '',
            lin33 REAL DEFAULT '',
            ind33 REAL DEFAULT '',
            retorno_lin33 REAL DEFAULT '',
            lin34 REAL DEFAULT '',
            ind34 REAL DEFAULT '',
            retorno_lin34 REAL DEFAULT '',
            lin35 REAL DEFAULT '',
            ind35 REAL DEFAULT '',
            retorno_lin35 REAL DEFAULT '',
            lin36 REAL DEFAULT '',
            ind36 REAL DEFAULT '',
            retorno_lin36 REAL DEFAULT '',
            lin37 REAL DEFAULT '',
            ind37 REAL DEFAULT '',
            retorno_lin37 REAL DEFAULT '',
            lin38 REAL DEFAULT '',
            ind38 REAL DEFAULT '',
            retorno_lin38 REAL DEFAULT '',
            lin39 REAL DEFAULT '',
            ind39 REAL DEFAULT '',
            retorno_lin39 REAL DEFAULT '',
            lin40 REAL DEFAULT '',
            ind40 REAL DEFAULT '',
            retorno_lin40 REAL DEFAULT '',
            lin41 REAL DEFAULT '',
            ind41 REAL DEFAULT '',
            retorno_lin41 REAL DEFAULT '',
            lin42 REAL DEFAULT '',
            ind42 REAL DEFAULT '',
            retorno_lin42 REAL DEFAULT '',
            lin43 REAL DEFAULT '',
            ind43 REAL DEFAULT '',
            retorno_lin43 REAL DEFAULT '',
            lin44 REAL DEFAULT '',
            ind44 REAL DEFAULT '',
            retorno_lin44 REAL DEFAULT '',
            lin45 REAL DEFAULT '',
            ind45 REAL DEFAULT '',
            retorno_lin45 REAL DEFAULT '',
            lin46 REAL DEFAULT '',
            ind46 REAL DEFAULT '',
            retorno_lin46 REAL DEFAULT '',
            lin47 REAL DEFAULT '',
            ind47 REAL DEFAULT '',
            retorno_lin47 REAL DEFAULT '',
            lin48 REAL DEFAULT '',
            ind48 REAL DEFAULT '',
            retorno_lin48 REAL DEFAULT '',
            lin49 REAL DEFAULT '',
            ind49 REAL DEFAULT '',
            retorno_lin49 REAL DEFAULT '',
            lin50 REAL DEFAULT '',
            ind50 REAL DEFAULT '',
            retorno_lin50 REAL DEFAULT '',
            lin51 REAL DEFAULT '',
            ind51 REAL DEFAULT '',
            retorno_lin51 REAL DEFAULT '',
            lin52 REAL DEFAULT '',
            ind52 REAL DEFAULT '',
            retorno_lin52 REAL DEFAULT '',
            lin53 REAL DEFAULT '',
            ind53 REAL DEFAULT '',
            retorno_lin53 REAL DEFAULT '',
            lin54 REAL DEFAULT '',
            ind54 REAL DEFAULT '',
            retorno_lin54 REAL DEFAULT '',
            lin55 REAL DEFAULT '',
            ind55 REAL DEFAULT '',
            retorno_lin55 REAL DEFAULT '',
            lin56 REAL DEFAULT '',
            ind56 REAL DEFAULT '',
            retorno_lin56 REAL DEFAULT '',
            lin57 REAL DEFAULT '',
            ind57 REAL DEFAULT '',
            retorno_lin57 REAL DEFAULT '',
            lin58 REAL DEFAULT '',
            ind58 REAL DEFAULT '',
            retorno_lin58 REAL DEFAULT '',
            lin59 REAL DEFAULT '',
            ind59 REAL DEFAULT '',
            retorno_lin59 REAL DEFAULT '',
            lin60 REAL DEFAULT '',
            ind60 REAL DEFAULT '',
            retorno_lin60 REAL DEFAULT '',
    
            hora_fin TEXT DEFAULT '',
            hri_fin TEXT DEFAULT '',
            ti_fin TEXT DEFAULT '',
            patmi_fin TEXT DEFAULT '',
            mant_soporte TEXT DEFAULT '',
            venta_pesas TEXT DEFAULT '',
            reemplazo TEXT DEFAULT '',
            observaciones TEXT DEFAULT '',
            emp TEXT DEFAULT '',
            indicar TEXT DEFAULT '',
            factor TEXT DEFAULT '',
            regla_aceptacion TEXT DEFAULT '',
            estado_servicio_bal TEXT DEFAULT ''
          )
        ''');
      },
    );

    // Insertar los datos depurados
    for (final registro in registros) {
      await tempDb.insert('registros_calibracion', registro);
    }

    await tempDb.close();

    // Leer el archivo de base de datos como bytes
    final dbBytes = await tempDbFile.readAsBytes();

    // Eliminar archivo temporal
    await tempDbFile.delete();

    return dbBytes;
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

      final List<Map<String, dynamic>> rows = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [widget.secaValue, widget.sessionId],
        orderBy: 'id DESC',
      );

      final nuevoSessionId = await dbHelper.generateSessionId(widget.secaValue);

      final Map<String, dynamic> nuevoRegistro = {
        'seca': widget.secaValue,
        'session_id': nuevoSessionId,
        'fecha_servicio': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };

      const columnsToCarry = [
        'cliente',
        'razon_social',
        'planta',
        'dir_planta',
        'dep_planta',
        'cod_planta',
        'personal',
        'equipo6',
        'certificado6',
        'ente_calibrador6',
        'estado6',
        'cantidad6',
        'equipo7',
        'certificado7',
        'ente_calibrador7',
        'estado7',
        'cantidad7',
      ];

      for (final col in columnsToCarry) {
        for (final row in rows) {
          final v = row[col];
          if (v != null && (v is! String || v.toString().trim().isNotEmpty)) {
            nuevoRegistro[col] = v;
            break;
          }
        }
      }

      await dbHelper.upsertRegistroCalibracion(nuevoRegistro);

      final userName = nuevoRegistro['personal']?.toString() ?? 'Usuario';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrecargaScreen(
            userName: userName,
            initialStep: 3, // Paso de Balanza
            sessionId: nuevoSessionId,
            secaValue: widget.secaValue,
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
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30.0),
              _buildInfoSection(
                'FINALIZAR SERVICIO',
                'Al dar clic se finalizará el servicio de calibración y se exportarán los datos en un archivo ZIP con formatos CSV, TXT y SMET.',
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
