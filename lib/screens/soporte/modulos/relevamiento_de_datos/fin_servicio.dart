import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:service_met/screens/soporte/precarga/precarga_screen.dart';
import 'package:service_met/home_screen.dart';

import '../../../../database/soporte_tecnico/database_helper_relevamiento.dart';

class FinServicioScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName; // ✅ AGREGAR
  final String clienteId; // ✅ AGREGAR
  final String plantaCodigo; // ✅ AGREGAR
  final String? tableName; // NUEVO: Nombre de la tabla (opcional)

  const FinServicioScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName, // ✅ AGREGAR
    required this.clienteId, // ✅ AGREGAR
    required this.plantaCodigo, // ✅ AGREGAR
    required this.tableName, // NUEVO: Nombre de la tabla (opcional)
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

  /// ---- NUEVO: Exporta CSV + TXT + MET y empaqueta en ZIP (tras copiar a BD interna).
  Future<void> _exportToCSV(BuildContext context) async {
    if (_isExporting) return;
    _isExporting = true;

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
                Text('Generando archivo CSV...'),
              ],
            ),
          ),
        );
      }

      // ✅ Obtener datos desde BD interna
      final dbHelper = DatabaseHelperRelevamiento();
      final db = await dbHelper.database;

      // ✅ Consultar SOLO la tabla relevamiento_de_datos por session_id
      final List<Map<String, dynamic>> registros = await db.query(
        'relevamiento_de_datos',
        where: 'session_id = ?',
        whereArgs: [widget.sessionId],
      );

      if (registros.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSnackBar(context, 'No hay datos para exportar', isError: true);
        }
        return;
      }

      // ✅ Obtener headers de las columnas
      final headers = registros.first.keys.toList();

      // ✅ Construir matriz CSV
      final matrix = <List<dynamic>>[
        headers,
        ...registros.map((reg) {
          return headers.map((header) {
            final value = reg[header];
            return (value is num) ? value.toString() : (value?.toString() ?? '');
          }).toList();
        })
      ];

      // ✅ Convertir a CSV con punto y coma
      final csvString = const ListToCsvConverter(
        fieldDelimiter: ';',
        textDelimiter: '"',
      ).convert(matrix);

      final csvBytes = utf8.encode(csvString);

      // ✅ Nombre del archivo
      final now = DateTime.now();
      final csvName = '${widget.secaValue}_${widget.codMetrica}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(now)}_relevamiento_de_datos.csv';

      // ✅ Pedir al usuario dónde guardar
      if (mounted) Navigator.of(context).pop();

      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccione carpeta para guardar el CSV',
      );

      if (directoryPath != null) {
        final outFile = File(join(directoryPath, csvName));
        await outFile.writeAsBytes(csvBytes);

        if (mounted) {
          _showSnackBar(context, 'CSV guardado en: ${outFile.path}');
        }
      } else {
        if (mounted) {
          _showSnackBar(context, 'Exportación cancelada');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(context, 'Error en exportación: $e', isError: true);
      }
      debugPrint('Error exportando CSV: $e');
    } finally {
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
                'Los datos actuales se mantendrán guardados.',
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

    if (confirmado != true) return;

    try {
      final dbHelper = DatabaseHelperRelevamiento();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> rows = await db.query(
        widget.tableName ?? 'relevamiento_de_datos',
        where: 'otst = ?',
        whereArgs: [widget.secaValue],
        orderBy: 'session_id DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('No se encontraron datos del SECA actual');
      }

      final registroActual = rows.first;

      String? codigoPlanta;

      // Opción 1: Si existe en la BD
      codigoPlanta = registroActual['cod_planta']?.toString();

      // Opción 2: Si no existe, extraer del OTST (formato: 25-1234-S01)
      if (codigoPlanta == null || codigoPlanta.isEmpty) {
        final partesSeca = widget.secaValue.split('-');
        if (partesSeca.length >= 2) {
          codigoPlanta = partesSeca[1]; // Extrae "1234"
        }
      }

      if (codigoPlanta == null || codigoPlanta.isEmpty) {
        throw Exception('No se pudo determinar el código de planta');
      }

      final nuevoSessionId = await dbHelper.generateSessionId(widget.secaValue);


      final nuevoRegistro = {
        'session_id': nuevoSessionId,
        'otst': widget.secaValue,
        'tipo_servicio': registroActual['tipo_servicio'],
        'fecha_servicio': registroActual['fecha_servicio'],
        'personal': registroActual['personal'],
        'cliente': registroActual['cliente'],
        'razon_social': registroActual['razon_social'],
        'planta': registroActual['planta'],
        'dep_planta': registroActual['dep_planta'],
        'dir_planta': registroActual['dir_planta'],
        'cod_planta': codigoPlanta,
        'cod_metrica': '', // Vacío para nueva balanza
      };

      await dbHelper.upsertRegistroRelevamiento(nuevoRegistro);


      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => PrecargaScreenSop(
            tableName: widget.tableName ?? 'relevamiento_de_datos', // NUEVO: Nombre de la tabla
            userName: widget.userName,
            clienteId: widget.clienteId,
            plantaCodigo: codigoPlanta!,
            initialStep: 3,
            sessionId: nuevoSessionId,
            secaValue: widget.secaValue,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      if (mounted) {
        _showSnackBar(context, 'Error: ${e.toString()}', isError: true);
      }
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
              'CÓDIGO MET: ${widget.codMetrica}',
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
              'Generará un archivo CSV con todos los datos del relevamiento. ' // ✅ NUEVO TEXTO
                  'El archivo se guardará con separador punto y coma (;).',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t4.png',
              'EXPORTAR',
                  () => _exportToCSV(context), // ✅ CAMBIAR DE _exportAllAndZip
              textColor,
              cardOpacity,
            ),
            const SizedBox(height: 40),
            _buildInfoSection(
              'SELECCIONAR OTRA BALANZA',
              'Volverá a la pantalla de identificación para seleccionar otra balanza. ' // ✅ NUEVO TEXTO
                  'Los datos actuales se mantendrán guardados en la sesión.',
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

                await _exportToCSV(context);

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
