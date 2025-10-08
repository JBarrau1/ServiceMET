import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/bdb/precarga_bd.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DescargaDeDatosScreen extends StatefulWidget {
  final String userName;
  const DescargaDeDatosScreen({
    super.key,
    required this.userName,
  });

  @override
  _DescargaDeDatosScreenState createState() => _DescargaDeDatosScreenState();
}

class _DescargaDeDatosScreenState extends State<DescargaDeDatosScreen> {
  final dbHelper = DatabaseHelperPrecarga();
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  String? errorMessage;
  String? lastUpdate;
  Timer? _autoDeleteTimer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
    _startAutoDeleteTimer();
    _checkIfDataExpired();
  }

  @override
  void dispose() {
    _autoDeleteTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAutoDeleteTimer() async {
    _autoDeleteTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      await _checkAndDeleteExpiredData();
    });
  }

  Future<void> _checkIfDataExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString('lastUpdate');

    if (lastUpdate != null) {
      final lastUpdateDate = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateDate);

      if (difference.inDays >= 15) {
        _showDataExpiredNotification();
      }
    }
  }

  Future<void> _checkAndDeleteExpiredData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString('lastUpdate');

    if (lastUpdate != null) {
      final lastUpdateDate = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateDate);

      if (difference.inDays >= 15) {
        await _deleteDatabase(silent: true);
        _showDataExpiredNotification();
      }
    }
  }

  void _showDataExpiredNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Los datos han expirado. Por favor, realice una nueva precarga.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ACTUALIZAR',
          onPressed: () => _updateDataWithExistingConnection(),
        ),
      ),
    );
  }

  Future<void> _loadLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdate = prefs.getString('lastUpdate');
    });
  }

  Future<Map<String, String>?> _showConnectionDialog(BuildContext context) async {
    final ipController = TextEditingController();
    final portController = TextEditingController();
    final dbNameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    ipController.text = prefs.getString('ip') ?? '';
    portController.text = prefs.getString('port') ?? '1433';
    dbNameController.text = prefs.getString('databaseName') ?? '';
    usernameController.text = prefs.getString('username') ?? '';
    passwordController.text = prefs.getString('password') ?? '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'CONFIGURACIÓN DE CONEXIÓN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'IP del servidor*',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    contentPadding: const EdgeInsets.all(15.0),
                  ),
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Puerto*',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    contentPadding: const EdgeInsets.all(15.0),
                  ),
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: dbNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Base de Datos*',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    contentPadding: const EdgeInsets.all(15.0),
                  ),
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario*',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    contentPadding: const EdgeInsets.all(15.0),
                  ),
                ),
                const SizedBox(height: 15.0),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña*',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    contentPadding: const EdgeInsets.all(15.0),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10.0),
                Text(
                  '* Campos obligatorios',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ipController.text.isEmpty ||
                    portController.text.isEmpty ||
                    dbNameController.text.isEmpty ||
                    usernameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, complete todos los campos obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!_isValidIP(ipController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, ingrese una dirección IP válida'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!_isValidPort(portController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, ingrese un puerto válido (1-65535)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final connectionData = {
                  'ip': ipController.text,
                  'port': portController.text,
                  'databaseName': dbNameController.text,
                  'username': usernameController.text,
                  'password': passwordController.text,
                };

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('ip', ipController.text);
                await prefs.setString('port', portController.text);
                await prefs.setString('databaseName', dbNameController.text);
                await prefs.setString('username', usernameController.text);
                await prefs.setString('password', passwordController.text);

                Navigator.of(context).pop(connectionData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF264024),
              ),
              child: const Text('Conectar'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidIP(String ip) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    return true;
  }

  bool _isValidPort(String port) {
    final portNum = int.tryParse(port);
    return portNum != null && portNum > 0 && portNum <= 65535;
  }

  Future<void> _downloadAndStoreData(BuildContext context) async {
    final connectionData = await _showConnectionDialog(context);

    if (connectionData == null) {
      return;
    }

    await _performDataSync(connectionData);
  }

  Future<void> _updateDataWithExistingConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final port = prefs.getString('port');
    final databaseName = prefs.getString('databaseName');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (ip == null || port == null || databaseName == null || username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron datos de conexión guardados. Por favor, configure la conexión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final connectionData = {
      'ip': ip,
      'port': port,
      'databaseName': databaseName,
      'username': username,
      'password': password ?? '',
    };

    await _performDataSync(connectionData);
  }

  Future<void> _performDataSync(Map<String, String> connectionData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Descargando datos del servidor...'),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: _progressNotifier,
                builder: (context, progress, _) {
                  return Text('Progreso: $progress%');
                },
              ),
            ],
          ),
        );
      },
    );

    MssqlConnection? connection;
    try {
      connection = MssqlConnection.getInstance();

      final connectionFuture = connection.connect(
        ip: connectionData['ip']!,
        port: connectionData['port']!,
        databaseName: connectionData['databaseName']!,
        username: connectionData['username']!,
        password: connectionData['password']!,
      );

      final isConnected = await connectionFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La conexión tardó demasiado tiempo. Verifique los datos de conexión.');
        },
      );

      if (!isConnected) {
        throw Exception('No se pudo conectar a la base de datos');
      }

      final queries = [
        'SELECT codigo_cliente, cliente, cliente_id, razonsocial FROM DATA_CLIENTES',
        'SELECT cliente_id, codigo_planta, planta_id, dep, dep_id, planta, dir FROM DATA_PLANTAS',
        'SELECT * FROM DATA_EQUIPOS_BALANZAS',
        'SELECT * FROM DATA_EQUIPOS',
        'SELECT * FROM DATA_EQUIPOS_CAL',
        'SELECT * FROM DATA_SERVICIOS_LEC'
      ];

      final results = await Future.wait([
        for (var query in queries)
          _executeQueryWithTimeout(connection, query, const Duration(seconds: 60))
      ]);

      final dbHelper = DatabaseHelperPrecarga();
      final db = await dbHelper.database;

      int totalItems = results.fold(0, (sum, result) => sum + result.length);
      int itemsProcesados = 0;

      await db.transaction((txn) async {
        await txn.delete('clientes');
        await txn.delete('plantas');
        await txn.delete('balanzas');
        await txn.delete('inf');
        await txn.delete('equipamientos');
        await txn.delete('servicios');

        for (var cliente in results[0]) {
          await txn.insert('clientes', {
            'codigo_cliente': cliente['codigo_cliente'],
            'cliente_id': cliente['cliente_id'],
            'cliente': cliente['cliente'],
            'razonsocial': cliente['razonsocial'],
          });

          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }

        for (var planta in results[1]) {
          await txn.insert('plantas', {
            'planta': planta['planta'],
            'planta_id': planta['planta_id'],
            'cliente_id': planta['cliente_id'],
            'dep_id': planta['dep_id'],
            'unique_key': '${planta['planta_id']}_${planta['dep_id']}',
            'codigo_planta': planta['codigo_planta'],
            'dep': planta['dep'],
            'dir': planta['dir'],
          });

          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }

        for (var balanza in results[2]) {
          await txn.insert('balanzas', {
            'cod_metrica': balanza['cod_metrica'],
            'serie': balanza['serie'],
            'unidad': balanza['unidad'],
            'n_celdas': balanza['n_celdas'],
            'cap_max1': balanza['cap_max1'],
            'd1': balanza['d1'],
            'e1': balanza['e1'],
            'dec1': balanza['dec1'],
            'cap_max2': balanza['cap_max2'],
            'd2': balanza['d2'],
            'e2': balanza['e2'],
            'dec2': balanza['dec2'],
            'cap_max3': balanza['cap_max3'],
            'd3': balanza['d3'],
            'e3': balanza['e3'],
            'dec3': balanza['dec3'],
            'categoria': balanza['categoria'],
          });
          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }

        for (var infItem in results[3]) {
          await txn.insert('inf', {
            'cod_interno': infItem['cod_interno'],
            'cod_metrica': infItem['cod_metrica'],
            'instrumento': infItem['instrumento'],
            'tipo_instrumento': infItem['tipo_instrumento'],
            'marca': infItem['marca'],
            'modelo': infItem['modelo'],
            'serie': infItem['serie'],
            'estado': infItem['estado'],
            'detalles': infItem['detalles'],
            'ubicacion': infItem['ubicacion'],
          });
          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }

        for (var equipamiento in results[4]) {
          await txn.insert('equipamientos', {
            'cod_instrumento': equipamiento['cod_instrumento'],
            'instrumento': equipamiento['instrumento'],
            'cert_fecha': equipamiento['cert_fecha'],
            'ente_calibrador': equipamiento['ente_calibrador'],
            'estado': equipamiento['estado'],
          });
          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }

        for (var servicio in results[5]) {
          await txn.insert('servicios', {
            'cod_metrica': servicio['cod_metrica'],
            'seca': servicio['seca'],
            'reg_fecha': servicio['reg_fecha'],
            'reg_usuario': servicio['reg_usuario'],
            'exc': servicio['exc'],
            'rep1': servicio['rep1'],
            'rep2': servicio['rep2'],
            'rep3': servicio['rep3'],
            'rep4': servicio['rep4'],
            'rep5': servicio['rep5'],
            'rep6': servicio['rep6'],
            'rep7': servicio['rep7'],
            'rep8': servicio['rep8'],
            'rep9': servicio['rep9'],
            'rep10': servicio['rep10'],
            'rep11': servicio['rep11'],
            'rep12': servicio['rep12'],
            'rep13': servicio['rep13'],
            'rep14': servicio['rep14'],
            'rep15': servicio['rep15'],
            'rep16': servicio['rep16'],
            'rep17': servicio['rep17'],
            'rep18': servicio['rep18'],
            'rep19': servicio['rep19'],
            'rep20': servicio['rep20'],
            'rep21': servicio['rep21'],
            'rep22': servicio['rep22'],
            'rep23': servicio['rep23'],
            'rep24': servicio['rep24'],
            'rep25': servicio['rep25'],
            'rep26': servicio['rep26'],
            'rep27': servicio['rep27'],
            'rep28': servicio['rep28'],
            'rep29': servicio['rep29'],
            'rep30': servicio['rep30'],
            'lin1': servicio['lin1'],
            'lin2': servicio['lin2'],
            'lin3': servicio['lin3'],
            'lin4': servicio['lin4'],
            'lin5': servicio['lin5'],
            'lin6': servicio['lin6'],
            'lin7': servicio['lin7'],
            'lin8': servicio['lin8'],
            'lin9': servicio['lin9'],
            'lin10': servicio['lin10'],
            'lin11': servicio['lin11'],
            'lin12': servicio['lin12'],
            'lin13': servicio['lin13'],
            'lin14': servicio['lin14'],
            'lin15': servicio['lin15'],
            'lin16': servicio['lin16'],
            'lin17': servicio['lin17'],
            'lin18': servicio['lin18'],
            'lin19': servicio['lin19'],
            'lin20': servicio['lin20'],
            'lin21': servicio['lin21'],
            'lin22': servicio['lin22'],
            'lin23': servicio['lin23'],
            'lin24': servicio['lin24'],
            'lin25': servicio['lin25'],
            'lin26': servicio['lin26'],
            'lin27': servicio['lin27'],
            'lin28': servicio['lin28'],
            'lin29': servicio['lin29'],
            'lin30': servicio['lin30'],
            'lin31': servicio['lin31'],
            'lin32': servicio['lin32'],
            'lin33': servicio['lin33'],
            'lin34': servicio['lin34'],
            'lin35': servicio['lin35'],
            'lin36': servicio['lin36'],
            'lin37': servicio['lin37'],
            'lin38': servicio['lin38'],
            'lin39': servicio['lin39'],
            'lin40': servicio['lin40'],
            'lin41': servicio['lin41'],
            'lin42': servicio['lin42'],
            'lin43': servicio['lin43'],
            'lin44': servicio['lin44'],
            'lin45': servicio['lin45'],
            'lin46': servicio['lin46'],
            'lin47': servicio['lin47'],
            'lin48': servicio['lin48'],
            'lin49': servicio['lin49'],
            'lin50': servicio['lin50'],
            'lin51': servicio['lin51'],
            'lin52': servicio['lin52'],
            'lin53': servicio['lin53'],
            'lin54': servicio['lin54'],
            'lin55': servicio['lin55'],
            'lin56': servicio['lin56'],
            'lin57': servicio['lin57'],
            'lin58': servicio['lin58'],
            'lin59': servicio['lin59'],
            'lin60': servicio['lin60'],
          });
          itemsProcesados++;
          if (itemsProcesados % 10 == 0) {
            int progress = ((itemsProcesados / totalItems) * 100).toInt();
            _progressNotifier.value = progress;
          }
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toString();
      await prefs.setString('lastUpdate', now);

      setState(() {
        lastUpdate = now;
        _isUpdating = false;
      });

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PRECARGA REALIZADA EXITOSAMENTE')),
      );
    } on TimeoutException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de timeout: ${e.message}')),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      await connection?.disconnect();
    }
  }

  Future<List<Map<String, dynamic>>> _executeQueryWithTimeout(
      MssqlConnection connection,
      String query,
      Duration timeout
      ) async {
    return await connection.getData(query)
        .timeout(timeout, onTimeout: () {
      throw TimeoutException('La consulta tardó demasiado tiempo: $query');
    })
        .then((resultString) {
      List<dynamic> resultList = json.decode(resultString);
      return resultList.cast<Map<String, dynamic>>().toList();
    });
  }

  Future<void> _deleteDatabase({bool silent = false}) async {
    if (!silent) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Confirmar Eliminación',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
              '¿Está seguro de eliminar la precarga realizada? Esto borrará los datos de la base de datos interna.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await dbHelper.deleteDatabase();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastUpdate');

      setState(() {
        lastUpdate = null;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precarga eliminada correctamente')),
        );
      }
    } catch (e) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la precarga: $e')),
        );
      }
    }
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
                'PRECARGA DE DATOS',
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
          await _loadLastUpdate();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),

              const SizedBox(height: 30),

              Text(
                'Gestión de Datos',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              if (lastUpdate == null)
                _buildDownloadCard(context)
              else
                _buildUpdateCard(context),

              const SizedBox(height: 20),

              if (lastUpdate != null) _buildStatusCard(context),

              const SizedBox(height: 30),

              _buildInfoSection(context),

              const SizedBox(height: 80),
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
                  FontAwesomeIcons.cloudArrowDown,
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
                      'Precarga de Datos',
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
                  FontAwesomeIcons.database,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sincronización de datos del servidor',
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

  Widget _buildDownloadCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _downloadAndStoreData(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFD6D4A7).withOpacity(0.8),
                              const Color(0xFFD6D4A7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.cloudArrowDown,
                          size: 28,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descargar Datos',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sincroniza los datos del servidor con la aplicación',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D4A7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFD6D4A7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadAndStoreData(context),
                          icon: const Icon(FontAwesomeIcons.download, size: 16),
                          label: const Text('Iniciar Descarga'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D4A7),
                            foregroundColor: const Color(0xFF212121),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3);
  }

  Widget _buildUpdateCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateDataWithExistingConnection(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.8),
                              Colors.green
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.arrowRotateRight,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actualizar Datos',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Actualiza los datos sin solicitar la configuración',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateDataWithExistingConnection(),
                          icon: const Icon(FontAwesomeIcons.arrowRotateRight, size: 16),
                          label: const Text('Actualizar Datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _downloadAndStoreData(context),
                        icon: const Icon(FontAwesomeIcons.gears, size: 16),
                        label: const Text('Reconfigurar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                          side: BorderSide(
                            color: isDarkMode ? Colors.white70 : Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3);
  }

  Widget _buildStatusCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        'Última Actualización',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${_formatDate(lastUpdate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Hora: ${_formatTime(lastUpdate!)}',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteDatabase,
                    icon: const Icon(FontAwesomeIcons.trash, size: 16),
                    label: const Text('Eliminar Precarga'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideX(begin: 0.3);
  }

  Widget _buildInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C3E50) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.circleInfo,
                color: Color(0xFF667EEA),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Información Importante',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'La precarga descarga y sincroniza todos los datos necesarios del servidor para el funcionamiento offline de la aplicación.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8CB0C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8CB0C).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Color(0xFFE8CB0C),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tenga en cuenta que para tener la información actualizada, debe realizar la actualización periódicamente.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
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

  String _formatDate(String dateString) {
    final DateTime parsedDate = DateTime.parse(dateString);
    return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(String dateString) {
    final DateTime parsedDate = DateTime.parse(dateString);
    return '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}';
  }
}