import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/screens/calibracion/qr/qr_scanner_screen.dart';
import 'package:service_met/screens/soporte/modulos/iden_balanza.dart';

import 'package:service_met/screens/soporte/modulos/iden_cliente.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../bdb/soporte_tecnico_bd.dart';

class SoporteScreen extends StatefulWidget {
  final String userName;
  const SoporteScreen({
    super.key,
    required this.userName,
  });

  @override
  _SoporteScreenState createState() => _SoporteScreenState();
}

class _SoporteScreenState extends State<SoporteScreen> {
  String? errorMessage;
  String? _otValue;
  bool _showOtField = false;
  bool _isDatabaseReady = false;

  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _otController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fechaController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _generateTemporaryOTST() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final randomNegotiation =
        (Random().nextInt(99) + 1).toString().padLeft(2, '0');
    return '0000-S$randomNegotiation-1-$year';
  }

  bool _isValidOtstFormat(String otst) {
    final regex = RegExp(r'^\d{4}-S\d{2}-[1-9]-\d{2}$');
    return regex.hasMatch(otst);
  }

  Future<File> _getServiciosDbFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/servicios_soporte_db.txt');
  }

  Future<void> _saveDatabaseName(String dbName) async {
    final file = await _getServiciosDbFile();
    await file.writeAsString('$dbName\n', mode: FileMode.append);
  }

  Future<bool> _databaseExists(String dbName) async {
    String path = join(await _getCustomDatabasePath(), '$dbName.db');
    return databaseExists(path);
  }

  Future<String> _getCustomDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hiddenDir = Directory('${appDir.path}/.soporte_tec');

    if (!await hiddenDir.exists()) {
      await hiddenDir.create(recursive: true);
    }

    return hiddenDir.path;
  }

  Future<void> _createDatabase(BuildContext context, String dbName) async {
    try {
      if (!_isValidOtstFormat(dbName)) {
        throw 'Formato de OTST inválido. Debe ser NNNN-SNN-1-AA';
      }

      final dbHelper = DatabaseHelperSop();
      String path = join(await _getCustomDatabasePath(), '$dbName.db');

      await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await dbHelper.onCreate(db, version);
        },
      );

      await _saveDatabaseName(dbName);

      setState(() {
        _otController.text = dbName;
        _otValue = dbName;
        _showOtField = true;
        _isDatabaseReady = true;
      });
    } catch (e) {
      _showSnackBar(context, 'Error al crear el almacenamiento: $e',
          isError: true);
      rethrow;
    }
  }

  Future<void> _prepareExistingDatabase(
      BuildContext context, String dbName) async {
    try {
      String path = join(await _getCustomDatabasePath(), '$dbName.db');
      final db = await openDatabase(path);

      final backupDir =
          Directory(join(await _getCustomDatabasePath(), 'backups'));
      if (!await backupDir.exists()) await backupDir.create();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await File(path)
          .copy(join(backupDir.path, '${dbName}_backup_$timestamp.db'));

      setState(() {
        _otController.text = dbName;
        _otValue = dbName;
        _showOtField = true;
        _isDatabaseReady = true;
      });
    } catch (e) {
      _showSnackBar(context, 'Error al preparar la base de datos existente: $e',
          isError: true);
    }
  }

  void _showCreateDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'INGRESE NÚMERO OTST',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dbNameController,
                decoration: buildInputDecoration('Número OTST:'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ejemplo: 1234-S01-1-25',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _dbNameController.text = _generateTemporaryOTST();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF08779d), // Color cambiado aquí
                ),
                child: const Text('OTST Temporal'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                if (_dbNameController.text.isEmpty) {
                  _showSnackBar(context, 'Ingrese el número OTST',
                      isError: true);
                  return;
                }

                if (!_isValidOtstFormat(_dbNameController.text)) {
                  _showSnackBar(
                    context,
                    'Formato inválido. Use NNNN-SXX-1-AA',
                    isError: true,
                  );
                  return;
                }

                final dbName = _dbNameController.text;
                final exists = await _databaseExists(dbName);

                if (exists) {
                  Navigator.of(dialogContext).pop();
                  _showUseExistingDatabaseDialog(context, dbName);
                } else {
                  await _createDatabase(context, dbName);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showUseExistingDatabaseDialog(BuildContext context, String dbName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'OTST EXISTENTE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'La OTST "$dbName" ya existe. ¿Desea usar esta misma OTST para registrar nuevos datos?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                try {
                  await _prepareExistingDatabase(context, dbName);
                  Navigator.of(dialogContext).pop();
                  _showSnackBar(context, 'OTST listo para nuevos registros');
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  _showSnackBar(context, 'Error: $e', isError: true);
                }
              },
              child: const Text('Usar OTST'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'CONFIRMACIÓN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: const Text(
              '¿Está seguro de comenzar el servicio de soporte técnico?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigateToIdenCliente(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToIdenCliente(BuildContext context) async {
    final dbPath = await _getCustomDatabasePath();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdenClienteScreen(
          dbName: _otController.text,
          userName: widget.userName,
          fechaServicio: _fechaController.text,
          numeroOT: _otController.text,
          dbPath: dbPath,
          otValue: _otController.text,
        ),
      ),
    );
  }

  Future<void> _saveDataToDatabase(BuildContext context, String dbName) async {
    if (_otController.text.isEmpty) {
      _showSnackBar(context, 'Por favor ingrese el número de OTST');
      return;
    }

    try {
      String path = join(await _getCustomDatabasePath(), '$dbName.db');
      final db = await openDatabase(path);

      final registro = {
        'fecha_servicio': _fechaController.text,
        'otst': _otController.text,
        'tec_responsable': widget.userName,
      };

      await db.insert('inf_cliente_balanza', registro);
      _showSnackBar(context, 'OTST Guardada Exitosamente');
    } catch (e) {
      _showSnackBar(context, 'Error al guardar la OTST: $e');
    }
  }

  Future<void> _scanQRCode(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
      _processMetricaCode(context, result);
    }
  }

  void _showMetricaFormatError(
      BuildContext context, String qrContent, String extractedCode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error en formato de código métrica',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El código métrica escaneado no tiene el formato correcto.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Formato esperado: XXXX-XX-XXX (11 caracteres)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.yellow : Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contenido QR completo:',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              Text(
                qrContent,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Código extraído:',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              Text(
                extractedCode,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: isDarkMode ? Colors.yellow : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processMetricaCode(
      BuildContext context, String qrContent) async {
    String codigoMetrica = _extractMetricaCode(qrContent);

    if (!_isValidMetricaFormat(codigoMetrica)) {
      _showMetricaFormatError(context, qrContent, codigoMetrica);
      return;
    }

    // Extraer los primeros 4 dígitos para sugerir OTST (NNNN)
    String parteNumerica = codigoMetrica.substring(0, 4);
    // Generar OTST sugerido (NNNN-S00-1-AA)
    String otstSugerido =
        '$parteNumerica-S00-1-${DateTime.now().year.toString().substring(2)}';

    _showBalanzaInfoDialog(context, codigoMetrica, otstSugerido);
  }

  void _showBalanzaInfoDialog(
      BuildContext context, String codigoMetrica, String otstSugerido) {
    TextEditingController otstController =
        TextEditingController(text: otstSugerido);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'INFORMACIÓN DE LA BALANZA',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Código Métrica:', codigoMetrica),
              const SizedBox(height: 20),
              Text(
                'OTST Sugerido:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: otstController,
                decoration: InputDecoration(
                  hintText: 'Formato: NNNN-SXX-1-AA',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onChanged: (value) {
                  if (!_isValidOtstFormat(value)) {
                    otstController.value = otstController.value.copyWith(
                      text: value,
                      selection: otstController.selection,
                      composing: TextRange.empty,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Modifique los números después de la "S" según corresponda\nEjemplo: S01, S02, etc.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDarkMode ? Colors.yellow : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              if (!_isValidOtstFormat(otstController.text)) {
                _showSnackBar(
                    context, 'Formato de OTST inválido. Use NNNN-SXX-1-AA',
                    isError: true);
                return;
              }

              try {
                await _createDatabase(context, otstController.text);
                await _saveDataToDatabase(context, otstController.text);
                Navigator.pop(context);

                // Navegar a pantalla de identificación por QR
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IdenBalanzaScreen(
                      dbName: otstController.text,
                      loadFromSharedPreferences: false,
                      selectedPlantaCodigo: '',
                      selectedCliente: '',
                      selectedPlantaNombre: '',
                      dbPath: '',
                      otValue: '',
                    ),
                  ),
                );
              } catch (e) {
                _showSnackBar(context, 'Error al crear registro: $e',
                    isError: true);
              }
            },
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidMetricaFormat(String codigo) {
    if (codigo.length != 11) return false;
    if (codigo[4] != '-' || codigo[7] != '-') return false;
    final digits = codigo.replaceAll('-', '');
    return RegExp(r'^\d+$').hasMatch(digits);
  }

  String _extractMetricaCode(String qrContent) {
    if (_isValidMetricaFormat(qrContent)) return qrContent;
    if (qrContent.length >= 11) {
      String possibleCode = qrContent.substring(0, 11);
      if (_isValidMetricaFormat(possibleCode)) return possibleCode;
    }
    final regex = RegExp(r'(\d{4}-\d{2}-\d{3})');
    final match = regex.firstMatch(qrContent);
    if (match != null) return match.group(1)!;
    return qrContent;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' ${value.isNotEmpty ? value : 'No disponible'}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'SOPORTE TÉCNICO',
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
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
          children: [
            const Text(
              'REGISTRO DE DATOS PARA EL SERVICIO DE SOPORTE TÉCNICO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: widget.userName,
                  decoration: buildInputDecoration('Técnico Responsable'),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _fechaController,
                  decoration: buildInputDecoration('Fecha del Servicio'),
                  readOnly: true,
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: isDarkMode ? Colors.white60 : Colors.black,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        'Fecha generada automáticamente por el sistema.',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white60 : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Método de busqueda o\nidentificación de la balanza',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _scanQRCode(context),
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF525656),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'BÚSQUEDA POR QR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                          SizedBox(height: 10),
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF363737),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'CODIGO METRICA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12.0,
                          ),
                        ),
                        SizedBox(height: 10),
                        Icon(
                          Icons.keyboard_alt_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showCreateDatabaseDialog(context),
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5c5f5f),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'SELECCIÓN MANUAL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                          SizedBox(height: 10),
                          Icon(
                            Icons.next_plan_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3e3e3e),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'LISTA DE OTST PRECARGADOS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                          SizedBox(height: 10),
                          Icon(
                            Icons.featured_play_list,
                            size: 40,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            if (_showOtField) ...[
              TextFormField(
                controller: _otController,
                decoration: buildInputDecoration('OTST REGISTRADA'),
                readOnly: true,
              ),
              const SizedBox(height: 8.0),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16.0,
                  ),
                  SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      'OTST registrada correctamente. Puede continuar con el servicio.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
            ],
            ElevatedButton(
              onPressed: _isDatabaseReady
                  ? () async {
                      await _saveDataToDatabase(context, _otController.text);
                      _showConfirmationDialog(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDatabaseReady ? Colors.green : Colors.grey,
                elevation: 4.0,
              ),
              child: const Text(
                'INICIAR SOPORTE TÉCNICO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }
}
