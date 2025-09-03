import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/screens/calibracion/qr/qr_scanner_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/app_database.dart';
import 'selec_cliente.dart';

class PrecargaScreen extends StatefulWidget {
  final String userName;
  const PrecargaScreen({
    super.key,
    required this.userName,
  });

  @override
  _PrecargaScreenState createState() => _PrecargaScreenState();
}

class _PrecargaScreenState extends State<PrecargaScreen> {
  String? errorMessage;
  String? _secaValue;
  bool _showSecaField = false;
  bool _isDatabaseReady = false;

  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _secaController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fechaController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _dbNameController.dispose();
    _secaController.dispose();
    super.dispose();
  }

  bool _isValidSecaFormat(String seca) {
    final regex = RegExp(r'^\d{4}-C\d{2}-25$');
    return regex.hasMatch(seca);
  }

  Future<File> _getServiciosDbFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/servicios_db.txt');
  }

  Future<Map<String, dynamic>?> _checkExistingSeca(String seca, String sessionId) async {
    try {
      final dbHelper = AppDatabase();
      final existingRecord = await dbHelper.getRegistroBySeca(seca, sessionId);
      return existingRecord;
    } catch (e) {
      print('Error al verificar SECA existente: $e');
      return null;
    }
  }

  Future<void> _prepareSecaRecord(BuildContext context, String seca) async {
    try {
      final dbHelper = AppDatabase();

      // Verificar si el SECA ya existe
      final secaExiste = await dbHelper.secaExists(seca);

      if (secaExiste) {
        // Si el SECA existe, obtener el último registro y mostrar diálogo
        final ultimoRegistro = await dbHelper.getUltimoRegistroPorSeca(seca);
        _showExistingSecaDialog(context, seca, ultimoRegistro?['fecha_servicio'] ?? 'N/A');
      } else {
        // Si el SECA es nuevo, crear directamente nueva sesión
        String newSessionId = await dbHelper.generateSessionId(seca);

        await dbHelper.upsertRegistroCalibracion({
          'seca': seca,
          'fecha_servicio': _fechaController.text,
          'personal': widget.userName,
          'session_id': newSessionId,
        });

        setState(() {
          _secaController.text = seca;
          _secaValue = seca;
          _showSecaField = true;
          _isDatabaseReady = true;
        });

        _showSnackBar(context, 'Nueva sesión creada para SECA: $seca (Session: $newSessionId)');
      }
    } catch (e) {
      _showSnackBar(context, 'Error al preparar SECA: $e', isError: true);
    }
  }

  void _showExistingSecaDialog(BuildContext context, String seca, String fechaServicio) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('SECA YA REGISTRADO'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('El SECA "$seca" ya tiene registros anteriores.'),
              const SizedBox(height: 10),
              Text('Fecha del último servicio: $fechaServicio'),
              const SizedBox(height: 10),
              const Text('¿Desea crear una NUEVA sesión para este SECA?'),
              const SizedBox(height: 10),
              const Text('⚠️ Los datos anteriores se mantendrán intactos.',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dbHelper = AppDatabase();

                String newSessionId = await dbHelper.generateSessionId(seca);

                await dbHelper.upsertRegistroCalibracion({
                  'seca': seca,
                  'fecha_servicio': _fechaController.text,
                  'personal': widget.userName,
                  'session_id': newSessionId, // ← NUEVO sessionId
                });

                setState(() {
                  _secaController.text = seca;
                  _secaValue = seca;
                  _showSecaField = true;
                  _isDatabaseReady = true;
                });

                Navigator.of(dialogContext).pop();
                _showSnackBar(context, 'Nueva sesión creada: $newSessionId');
              },
              child: const Text('Crear Nueva Sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrecargadosList(BuildContext context) async {
    try {
      final dbHelper = AppDatabase();
      final List<Map<String, dynamic>> registros = await dbHelper.getAllRegistrosCalibracion();

      if (registros.isEmpty) {
        _showSnackBar(context, 'No hay SECAs precargados');
        return;
      }

      // Agrupar registros por SECA y obtener el más reciente de cada uno
      Map<String, Map<String, dynamic>> secasUnicos = {};

      for (var registro in registros) {
        String seca = registro['seca'];
        DateTime fechaRegistro = _parseDate(registro['fecha_servicio'] ?? '');

        // Si es la primera vez que vemos este SECA, o si este registro es más reciente
        if (!secasUnicos.containsKey(seca) ||
            fechaRegistro.isAfter(_parseDate(secasUnicos[seca]!['fecha_servicio'] ?? ''))) {
          secasUnicos[seca] = registro;
        }
      }

      // Convertir a lista y ordenar alfabéticamente por SECA
      List<Map<String, dynamic>> secasLista = secasUnicos.values.toList();
      secasLista.sort((a, b) => a['seca'].compareTo(b['seca']));

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'SECAS REGISTRADOS ANTERIORMENTE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: secasLista.length,
                itemBuilder: (context, index) {
                  final registro = secasLista[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8CB0C),
                        child: Icon(Icons.description, color: Colors.white),
                      ),
                      title: Text(
                        registro['seca'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Fecha: ${registro['fecha_servicio'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _secaController.text = registro['seca'];
                          _secaValue = registro['seca'];
                          _showSecaField = true;
                          _isDatabaseReady = true;
                        });
                        Navigator.of(context).pop();
                        _showSnackBar(context, 'SECA seleccionado: ${registro['seca']}');
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Error al cargar SECAs: $e', isError: true);
    }
  }

// Función auxiliar para parsear fechas en formato DD-MM-YYYY
  DateTime _parseDate(String dateString) {
    try {
      List<String> parts = dateString.split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime(1900); // Fecha por defecto para ordenamiento
  }

  void _showCreateDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'INGRESE NÚMERO SECA',
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
                decoration: buildInputDecoration('Codigo SECA:'),
              ),
              const SizedBox(height: 10),
              const Text('Ejemplo: 1234-C01-25'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3e7732),
              ),
              onPressed: () async {
                if (_dbNameController.text.isEmpty) {
                  _showSnackBar(context, 'Ingrese el número SECA', isError: true);
                  return;
                }
                if (!_isValidSecaFormat(_dbNameController.text)) {
                  _showSnackBar(context, 'Formato inválido. Use NNNN-CNN-25', isError: true);
                  return;
                }

                await _prepareSecaRecord(context, _dbNameController.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continuar'),
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
              '¿Está seguro de comenzar el servicio de calibración?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                final dbHelper = AppDatabase();

                // ⚠️ CAMBIO CRÍTICO: Generar NUEVO sessionId en lugar de usar el existente
                String newSessionId = await dbHelper.generateSessionId(_secaController.text);

                // Actualizar el registro con el NUEVO sessionId
                await dbHelper.upsertRegistroCalibracion({
                  'seca': _secaController.text,
                  'fecha_servicio': _fechaController.text,
                  'personal': widget.userName,
                  'session_id': newSessionId,
                });

                Navigator.of(dialogContext).pop(); // Cerrar diálogo

                // Navegar a CalibracionScreen con el NUEVO sessionId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalibracionScreen(
                      dbName: _secaController.text,
                      userName: widget.userName,
                      secaValue: _secaController.text,
                      sessionId: newSessionId, // ← NUEVO sessionId
                    ),
                  ),
                );
              },
              child: const Text("Continuar"),
            )
          ],
        );
      },
    );
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

    // Extraer los primeros 4 dígitos para el SECA (NNNN)
    String parteNumerica = codigoMetrica.substring(0, 4);
    // Generar SECA sugerido (NNNN-C00-25)
    String secaSugerido = '$parteNumerica-C00-25';

    // Mostrar diálogo con información y campo editable para el SECA
    _showBalanzaInfoDialog(context, codigoMetrica, secaSugerido);
  }

  void _showBalanzaInfoDialog(
      BuildContext context, String codigoMetrica, String secaSugerido) {
    TextEditingController secaController =
    TextEditingController(text: secaSugerido);
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
                'SECA Sugerido:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: secaController,
                decoration: buildInputDecoration(
                  'Formato: NNNN-CXX-25',
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onChanged: (value) {
                  if (!_isValidSecaFormat(value)) {
                    // Mostrar error sutil cambiando el color del borde
                    secaController.value = secaController.value.copyWith(
                      text: value,
                      selection: secaController.selection,
                      composing: TextRange.empty,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Modifique los números después de la "C" según corresponda\nEjemplo: C01, C02, etc.',
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
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              if (!_isValidSecaFormat(secaController.text)) {
                _showSnackBar(
                    context, 'Formato de SECA inválido. Use NNNN-CXX-25',
                    isError: true);
                return;
              }
              try {
                await _prepareSecaRecord(context, secaController.text);
                Navigator.pop(context); // Cerrar diálogo

              } catch (e) {
                _showSnackBar(context, 'Error al procesar SECA: $e',
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
    // Verificar longitud primero
    if (codigo.length != 11) return false;

    // Verificar guiones en las posiciones correctas
    if (codigo[4] != '-' || codigo[7] != '-') return false;

    // Verificar que los demás caracteres sean dígitos
    final digits = codigo.replaceAll('-', '');
    return RegExp(r'^\d+$').hasMatch(digits);
  }

  String _extractMetricaCode(String qrContent) {
    // Caso 1: El QR contiene exactamente el código métrica
    if (_isValidMetricaFormat(qrContent)) return qrContent;

    // Caso 2: El código métrica son los primeros 11 caracteres
    if (qrContent.length >= 11) {
      String possibleCode = qrContent.substring(0, 11);
      if (_isValidMetricaFormat(possibleCode)) return possibleCode;
    }

    // Caso 3: Buscar patrón en cualquier parte del QR
    final regex = RegExp(r'(\d{4}-\d{2}-\d{3})');
    final match = regex.firstMatch(qrContent);
    if (match != null) return match.group(1)!;

    // Si no se encuentra, devolver el contenido original para mostrar el error
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
          'CALIBRACIÓN',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
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
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 40,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: Column(
          children: [
            const Text(
              'REGISTRO DE DATOS PARA EL SERVICIO DE CALIBRACIÓN',
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
                    onTap: () => _showPrecargadosList(context),
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
                            'LISTA DE SECAS INGRESADOS',
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
            if (_showSecaField) ...[
              TextFormField(
                controller: _secaController,
                decoration: buildInputDecoration('SECA REGISTRADO'),
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
                      'SECA registrado correctamente. Puede continuar con el servicio.',
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
                _showConfirmationDialog(context);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDatabaseReady ? Colors.green : Colors.grey,
                elevation: 4.0,
              ),
              child: const Text(
                'INICIAR CALIBRACIÓN',
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