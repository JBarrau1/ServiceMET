// ignore_for_file: library_private_types_in_public_api, unused_field, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_met/home/home_screen.dart';
import 'package:service_met/screens/soporte/precarga/precarga_screen.dart';
import '../../../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';

class FinServicioMntAvaStacScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;
  final String? tableName;

  const FinServicioMntAvaStacScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
    required this.tableName,
  });

  @override
  _FinServicioMntAvaStacScreenState createState() =>
      _FinServicioMntAvaStacScreenState();
}

class _FinServicioMntAvaStacScreenState
    extends State<FinServicioMntAvaStacScreen> {
  String? errorMessage;
  bool _isExporting = false;

  String? _selectedEmp23001;
  final TextEditingController _indicarController = TextEditingController();
  final TextEditingController _factorSeguridadController =
      TextEditingController();
  String? _selectedReglaAceptacion;

  @override
  void dispose() {
    _indicarController.dispose();
    _factorSeguridadController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
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

  // ✅ NUEVO: Función principal de confirmación y exportación
  Future<void> _confirmarYExportar(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStac();
      final db = await dbHelper.database;

      // ✅ CAMBIO: Usar otst y estado_balanza = 'Balanza Realizada'
      final rows = await db.query(
        widget.tableName ?? 'mnt_prv_avanzado_stac',
        where: 'otst = ? AND estado_servicio = ?',
        whereArgs: [widget.secaValue, 'Completo'],
      );

      final cantidad = rows.length;

      if (cantidad == 0) {
        _showSnackBar(context,
            'No hay registros para exportar con este OTST (${widget.secaValue})',
            isError: true);
        return;
      }

      // 3. Obtener rows actualizados
      final updatedRows = await db.query(
        widget.tableName ?? 'mnt_prv_avanzado_stac',
        where: 'otst = ? AND estado_servicio = ?',
        whereArgs: [widget.secaValue, 'Completo'],
      );

      // 4. Mostrar pantalla de resumen
      if (!mounted) return;
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ResumenExportacionScreen(
            cantidad: cantidad,
            otst: widget.secaValue,
            registros: updatedRows,
            onExport: (registros) => _exportToCSV(context, registros),
          ),
        ),
      );

      if (resultado == true && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar(context, 'Error en exportación: $e', isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> _depurarDatos(
      List<Map<String, dynamic>> registros) async {
    // 1. Eliminar filas completamente vacías
    registros.removeWhere((registro) =>
        registro.values.every((value) => value == null || value == ''));

    final Map<String, Map<String, dynamic>> registrosUnicos = {};

    for (var registro in registros) {
      final String claveUnica = registro['cod_metrica']?.toString() ?? 'N/A';
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

  /// Exporta datos a CSV con depuración
  Future<void> _exportToCSV(
      BuildContext context, List<Map<String, dynamic>> registros) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      // 1. Depurar los datos
      final registrosDepurados = await _depurarDatos(registros);

      // 2. Generar CSV
      final csvBytes = await _generateCSVBytes(registrosDepurados);

      // 3. Crear nombre del archivo
      final fileName =
          '${widget.secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}_mnt_prv_avanzado_stac.csv';

      // 4. Guardar internamente
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final exportDir =
            Directory('${externalDir.path}/RespaldoSM/CSV_Automaticos');
        if (!await exportDir.exists()) await exportDir.create(recursive: true);

        final internalFile = File('${exportDir.path}/$fileName');
        await internalFile.writeAsBytes(csvBytes);
      }

      // 5. Preguntar ubicación de destino
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino para exportación',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$fileName');
        await userFile.writeAsBytes(csvBytes, mode: FileMode.write);
        _showSnackBar(
            context, 'Archivo CSV exportado exitosamente a: ${userFile.path}');
      } else {
        _showSnackBar(context, 'Exportación cancelada.', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error al exportar CSV: $e', isError: true);
    } finally {
      _isExporting = false;
    }
  }

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
      final dbHelper = DatabaseHelperMntPrvAvanzadoStac();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> rows = await db.query(
        widget.tableName ?? 'mnt_prv_avanzado_stac',
        where: 'otst = ?',
        whereArgs: [widget.secaValue],
        orderBy: 'session_id DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('No se encontraron datos del OTST actual');
      }

      final registroActual = rows.first;
      final nuevoSessionId = await dbHelper.generateSessionId(widget.secaValue);

      final nuevoRegistro = {
        'session_id': nuevoSessionId,
        'otst': widget.secaValue,
        'tipo_servicio': registroActual['tipo_servicio'],
        'fecha_servicio': registroActual['fecha_servicio'],
        'personal': registroActual['personal'],
        'cliente': registroActual['cliente'],
        'razon_social': registroActual['razon_social'] ?? '',
        'planta': registroActual['planta'],
        'dep_planta': registroActual['dep_planta'] ?? '',
        'dir_planta': registroActual['dir_planta'] ?? '',
        'cod_planta': widget.plantaCodigo,
        'cod_metrica': '',
      };

      await dbHelper.upsertRegistroRelevamiento(nuevoRegistro);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => PrecargaScreenSop(
            tableName: widget.tableName ?? 'mnt_prv_avanzado_stac',
            userName: widget.userName,
            clienteId: widget.clienteId,
            plantaCodigo: widget.plantaCodigo,
            initialStep: 3,
            sessionId: nuevoSessionId,
            secaValue: widget.secaValue,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error al navegar: $e');
      debugPrint(st.toString());

      if (mounted) {
        _showSnackBar(
          context,
          'Error al navegar: ${e.toString()}',
          isError: true,
        );
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
              'FINALIZAR SERVICIO',
              'Al dar clic se finalizará el servicio de mantenimiento preventivo y se exportarán los datos en un archivo CSV.',
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
              'Volverá a la pantalla de identificación para seleccionar otra balanza. '
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
                      textAlign: TextAlign.center,
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

// ✅ PANTALLA DE RESUMEN (NUEVA)
class _ResumenExportacionScreen extends StatefulWidget {
  final int cantidad;
  final String otst;
  final List<Map<String, dynamic>> registros;
  final Future<void> Function(List<Map<String, dynamic>>) onExport;

  const _ResumenExportacionScreen({
    required this.cantidad,
    required this.otst,
    required this.registros,
    required this.onExport,
  });

  @override
  _ResumenExportacionScreenState createState() =>
      _ResumenExportacionScreenState();
}

class _ResumenExportacionScreenState extends State<_ResumenExportacionScreen> {
  late Future<Map<String, dynamic>> _resumenFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _resumenFuture = _generarResumen();
  }

  Future<Map<String, dynamic>> _generarResumen() async {
    final balanzasUnicas = <String, Map<String, dynamic>>{};
    int totalRegistros = widget.registros.length;

    for (final registro in widget.registros) {
      final codMetrica = registro['cod_metrica']?.toString() ?? 'N/A';
      final marca = registro['marca']?.toString() ?? 'N/A';
      final modelo = registro['modelo']?.toString() ?? 'N/A';

      if (!balanzasUnicas.containsKey(codMetrica)) {
        balanzasUnicas[codMetrica] = {
          'cod_metrica': codMetrica,
          'marca': marca,
          'modelo': modelo,
          'cantidad': 0,
        };
      }
      balanzasUnicas[codMetrica]?['cantidad'] =
          (balanzasUnicas[codMetrica]?['cantidad'] ?? 0) + 1;
    }

    return {
      'totalBalanzas': balanzasUnicas.length,
      'totalRegistros': totalRegistros,
      'balanzas': balanzasUnicas.values.toList(),
      'fecha': DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()),
      'otst': widget.otst,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'RESUMEN DE EXPORTACIÓN',
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resumenFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resumen = snapshot.data!;
          final balanzas = resumen['balanzas'] as List<Map<String, dynamic>>;
          final totalBalanzas = resumen['totalBalanzas'] as int;
          final totalRegistros = resumen['totalRegistros'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF46824B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESUMEN GENERAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResumenItem(
                          'OTST:',
                          resumen['otst'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Fecha/Hora:',
                          resumen['fecha'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Balanzas realizadas:',
                          totalBalanzas.toString(),
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Total de registros:',
                          totalRegistros.toString(),
                          Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DETALLE DE BALANZAS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: balanzas.length,
                  itemBuilder: (context, index) {
                    final balanza = balanzas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balanza ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailItem(
                              'Código métrica:',
                              balanza['cod_metrica'],
                            ),
                            _buildDetailItem(
                              'Marca:',
                              balanza['marca'],
                            ),
                            _buildDetailItem(
                              'Modelo:',
                              balanza['modelo'],
                            ),
                            _buildDetailItem(
                              'Registros:',
                              balanza['cantidad'].toString(),
                              highlight: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF46824B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isExporting
                        ? null
                        : () async {
                            setState(() => _isExporting = true);

                            try {
                              await widget.onExport(widget.registros);

                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al exportar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isExporting = false);
                              }
                            }
                          },
                    child: _isExporting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'PROCEDER CON LA EXPORTACIÓN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? const Color(0xFF46824B) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
