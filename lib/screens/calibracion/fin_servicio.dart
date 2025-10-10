import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_met/screens/calibracion/precarga/precarga_screen.dart';
import 'package:service_met/bdb/calibracion_bd.dart';
import '../../database/app_database.dart';
import '../../home_screen.dart';

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

      // 4. Mostrar pantalla de resumen
      if (!mounted) return;
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ResumenExportacionScreen(
            cantidad: cantidad,
            seca: widget.secaValue,
            registros: updatedRows,
            onExport: (registros) => _exportToCSV(context, registros),
          ),
        ),
      );

      if (resultado == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
          '${widget.secaValue}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';

      // 4. Guardar internamente
      final internalDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${internalDir.path}/export_servicios');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);

      final internalFile = File('${exportDir.path}/$fileName');
      await internalFile.writeAsBytes(csvBytes);

      // 5. Preguntar ubicación de destino
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona carpeta de destino para exportación',
      );

      if (directoryPath != null) {
        final userFile = File('$directoryPath/$fileName');
        await userFile.writeAsBytes(csvBytes, mode: FileMode.write);
        _showSnackBar(context, 'Archivo CSV exportado exitosamente a: ${userFile.path}');
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
            initialStep: 3,
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
                'Al dar clic se finalizará el servicio de calibración y se exportarán los datos en un archivo CSV.',
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

// Pantalla de resumen antes de exportar
class _ResumenExportacionScreen extends StatefulWidget {
  final int cantidad;
  final String seca;
  final List<Map<String, dynamic>> registros;
  final Future<void> Function(List<Map<String, dynamic>>) onExport;

  const _ResumenExportacionScreen({
    required this.cantidad,
    required this.seca,
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
    // Contar balanzas únicas por cod_metrica
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
      'seca': widget.seca,
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
          final balanzas =
          resumen['balanzas'] as List<Map<String, dynamic>>;
          final totalBalanzas = resumen['totalBalanzas'] as int;
          final totalRegistros = resumen['totalRegistros'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de resumen general
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
                        Text(
                          'RESUMEN GENERAL',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResumenItem(
                          'SECA:',
                          resumen['seca'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Fecha/Hora:',
                          resumen['fecha'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Balanzas calibradas:',
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
                Text(
                  'DETALLE DE BALANZAS',
                  style: const TextStyle(
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
                    onPressed: _isExporting ? null : () async {
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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