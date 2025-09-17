import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/screens/calibracion/qr/qr_scanner_screen.dart';
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

        if (mounted) {
          setState(() {
            _secaController.text = seca;
            _secaValue = seca;
            _showSecaField = true;
            _isDatabaseReady = true;
          });

          _showSnackBar(context, 'Nueva sesión creada para SECA: $seca (Session: $newSessionId)');
        }
      }
    } catch (e) {
      debugPrint('Error completo en _prepareSecaRecord: $e');
      if (mounted) {
        _showSnackBar(context, 'Error al preparar SECA: ${e.toString()}', isError: true);
      }
    }
  }

  void _showExistingSecaDialog(BuildContext context, String seca, String fechaServicio) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'SECA Ya Registrado',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.triangleExclamation,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los datos anteriores se mantendrán intactos.',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              onPressed: () async {
                final dbHelper = AppDatabase();

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

                Navigator.of(dialogContext).pop();
                _showSnackBar(context, 'Nueva sesión creada: $newSessionId');
              },
              child: const Text('Crear Nueva Sesión'),
            )
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
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
              'SECAs Registrados',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: secasLista.length,
                itemBuilder: (context, index) {
                  final registro = secasLista[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFD6A7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.scaleBalanced,
                          color: Color(0xFFBFD6A7),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        registro['seca'] ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(FontAwesomeIcons.calendar, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Fecha: ${registro['fecha_servicio'] ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () async {
                        Navigator.of(dialogContext).pop();
                        await _prepareSecaRecord(context, registro['seca']);
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
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
    return DateTime(1900);
  }

  void _showCreateDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Ingrese Número SECA',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dbNameController,
                decoration: _buildInputDecoration('Código SECA'),
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.lightbulb, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Formato: 1234-C01-25',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
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

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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
          title: Text(
            'Confirmación',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text('¿Está seguro de comenzar el servicio de calibración?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              onPressed: () async {
                final dbHelper = AppDatabase();

                final ultimoRegistro = await dbHelper.getUltimoRegistroPorSeca(_secaController.text);

                if (ultimoRegistro == null || ultimoRegistro['session_id'] == null) {
                  _showSnackBar(context, 'Error: No se encontró la sesión', isError: true);
                  return;
                }

                final sessionIdExistente = ultimoRegistro['session_id'].toString();

                Navigator.of(dialogContext).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalibracionScreen(
                      dbName: _secaController.text,
                      userName: widget.userName,
                      secaValue: _secaController.text,
                      sessionId: sessionIdExistente,
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

  void _showMetricaFormatError(BuildContext context, String qrContent, String extractedCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error en Formato',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El código métrica escaneado no tiene el formato correcto.',
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato esperado:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'XXXX-XX-XXX (11 caracteres)',
                      style: GoogleFonts.inter(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contenido QR:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              Text(qrContent, style: GoogleFonts.inter(fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                'Código extraído:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              Text(
                extractedCode,
                style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _processMetricaCode(BuildContext context, String qrContent) async {
    String codigoMetrica = _extractMetricaCode(qrContent);

    if (!_isValidMetricaFormat(codigoMetrica)) {
      _showMetricaFormatError(context, qrContent, codigoMetrica);
      return;
    }

    String parteNumerica = codigoMetrica.substring(0, 4);
    String secaSugerido = '$parteNumerica-C00-25';

    _showBalanzaInfoDialog(context, codigoMetrica, secaSugerido);
  }

  void _showBalanzaInfoDialog(BuildContext context, String codigoMetrica, String secaSugerido) {
    TextEditingController secaController = TextEditingController(text: secaSugerido);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Información de la Balanza',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: secaController,
                decoration: _buildInputDecoration('Formato: NNNN-CXX-25'),
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Modifique los números después de la "C" según corresponda\nEjemplo: C01, C02, etc.',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            onPressed: () async {
              if (!_isValidSecaFormat(secaController.text)) {
                _showSnackBar(context, 'Formato de SECA inválido. Use NNNN-CXX-25', isError: true);
                return;
              }
              try {
                await _prepareSecaRecord(context, secaController.text);
                Navigator.pop(context);
              } catch (e) {
                _showSnackBar(context, 'Error al procesar SECA: $e', isError: true);
              }
            },
            child: const Text('Continuar'),
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
          style: GoogleFonts.inter(),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' ${value.isNotEmpty ? value : 'No disponible'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: AppBar(
              toolbarHeight: 70,
              title: Text(
                'Calibración',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                ),
              ),
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de bienvenida
              _buildWelcomeHeader(context),

              const SizedBox(height: 30),

              // Información de fecha
              _buildDateSection(context),

              const SizedBox(height: 30),

              // Título de métodos
              Text(
                'Métodos de Identificación',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              // Cards de métodos
              Row(
                children: [
                  _buildMethodCard(
                    icon: FontAwesomeIcons.qrcode,
                    title: 'Búsqueda por QR',
                    onTap: () => _scanQRCode(context),
                    color: const Color(0xFF89B2CC),
                  ),
                  _buildMethodCard(
                    icon: FontAwesomeIcons.keyboard,
                    title: 'Código Métrica',
                    onTap: () {}, // Implementar según necesidad
                    color: const Color(0xFFBFD6A7),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),

              const SizedBox(height: 16),

              Row(
                children: [
                  _buildMethodCard(
                    icon: FontAwesomeIcons.handPointer,
                    title: 'Selección Manual',
                    onTap: () => _showCreateDatabaseDialog(context),
                    color: const Color(0xFFD6D4A7),
                  ),
                  _buildMethodCard(
                    icon: FontAwesomeIcons.list,
                    title: 'SECAs Registrados',
                    onTap: () => _showPrecargadosList(context),
                    color: const Color(0xFF89B2CC),
                  ),
                ],
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

              const SizedBox(height: 30),

              // Campo SECA si está disponible
              if (_showSecaField) _buildSecaSection(context),

              const SizedBox(height: 30),

              // Botón de iniciar calibración
              _buildStartButton(context),

              const SizedBox(height: 80), // Espacio para navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF34495E)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  FontAwesomeIcons.scaleBalanced,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servicio de Calibración',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FontAwesomeIcons.clipboardCheck,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Registro de datos para calibración',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildDateSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C3E50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FontAwesomeIcons.calendar,
                  color: Color(0xFF667EEA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha del Servicio',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      _fechaController.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.circleInfo, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fecha generada automáticamente por el sistema',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildSecaSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C3E50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FontAwesomeIcons.circleCheck,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECA Registrado',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      _secaController.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.check, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SECA registrado correctamente. Puede continuar con el servicio.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDatabaseReady ? () => _showConfirmationDialog(context) : null,
        icon: Icon(
          FontAwesomeIcons.play,
          size: 16,
          color: _isDatabaseReady ? Colors.white : Colors.grey,
        ),
        label: Text(
          'Iniciar Calibración',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isDatabaseReady ? Colors.white : Colors.grey,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDatabaseReady ? const Color(0xFF667EEA) : Colors.grey[300],
          elevation: _isDatabaseReady ? 4 : 0,
        ),
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.3);
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.inter(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF667EEA)),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}