import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/bdb/precarga_bd.dart';
import 'package:flutter/material.dart';
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
          label: 'PRECARGAR',
          onPressed: () => _downloadAndStoreData(context),
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
            'INGRESE LOS DATOS PARA LA CONEXIÓN',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                backgroundColor: Colors.green,
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

        // CORRECCIÓN: Usar results[index] en lugar de variables no definidas
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

        // CORRECCIÓN: results[1] para plantas
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

        // CORRECCIÓN: results[2] para balanzas
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

        // CORRECCIÓN: results[3] para inf
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

        // CORRECCIÓN: results[4] para equipamientos
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

        // CORRECCIÓN: results[5] para servicios
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
      }); // CORRECCIÓN: Esta llave cierra la transacción

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toString();
      await prefs.setString('lastUpdate', now);

      setState(() {
        lastUpdate = now;
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
            'CONFIRMAR ELIMINACIÓN',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
              '¿Esta seguro de eliminar la precarga realizada?, esto borrara los datos de la base de datos interna.'),
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
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'PRECARGA',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'DESCARGA DE DATOS DEL SERVIDOR',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () => _downloadAndStoreData(context),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('images/tarjetas/t6.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'HAGA CLICK EN ESTA TARJETA PARA DESCARGAR O ACTUALIZAR LOS DATOS.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            if (lastUpdate != null) ...[
              Column(
                children: [
                  Text(
                    'ÚLTIMA ACTUALIZACIÓN DE DATOS:',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fecha: ${_formatDate(lastUpdate!)}',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Hora: ${_formatTime(lastUpdate!)}',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _deleteDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'ELIMINAR PRECARGA',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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