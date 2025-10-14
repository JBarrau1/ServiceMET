import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/bdb/precarga_bd.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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
  final ValueNotifier<String> _currentTableNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _currentOperationNotifier = ValueNotifier<String>('');
  String? errorMessage;
  String? lastUpdate;
  Timer? _autoDeleteTimer;
  bool _isUpdating = false;
  bool _isCancelled = false;
  MssqlConnection? _currentConnection;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
    _startAutoDeleteTimer();
    _checkIfDataExpired();
  }

  @override
  void dispose() {
    _cancelOperation();
    _autoDeleteTimer?.cancel();
    _progressNotifier.dispose();
    _currentTableNotifier.dispose();
    _currentOperationNotifier.dispose();
    super.dispose();
  }

  void _cancelOperation() {
    _isCancelled = true;
    _currentConnection?.disconnect();
  }

  Future<void> _startAutoDeleteTimer() async {
    _autoDeleteTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      await _checkAndDeleteExpiredData();
    });
  }

  Future<void> _checkIfDataExpired() async {
    if (!mounted) return;

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
        if (mounted) {
          _showDataExpiredNotification();
        }
      }
    }
  }

  void _showDataExpiredNotification() {
    if (!mounted) return;

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
    if (!mounted) return;

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
                // No guardar la contraseña por seguridad
                // await prefs.setString('password', passwordController.text);

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
      if (!mounted) return;
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
    _isCancelled = false;

    // Verificar si las tablas existen antes de proceder
    final db = await dbHelper.database;
    final tables = ['clientes', 'plantas', 'balanzas', 'inf', 'equipamientos', 'servicios'];

    bool shouldDeleteTables = true;

    // Verificar si todas las tablas existen
    for (var table in tables) {
      try {
        await db.rawQuery('SELECT COUNT(*) FROM $table LIMIT 1');
      } catch (e) {
        // Si alguna tabla no existe, no podemos hacer backup
        shouldDeleteTables = false;
        break;
      }
    }

    // Mostrar diálogo de confirmación si hay datos existentes
    if (shouldDeleteTables) {
      final confirm = await _showConfirmDialog(context);
      if (!confirm) return;
    }

    // Mostrar diálogo de progreso con opción de cancelar
    final progressDialog = _showProgressDialog(context);

    try {
      await _performDataSyncInternal(connectionData, db, shouldDeleteTables);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cerrar progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PRECARGA REALIZADA EXITOSAMENTE')),
      );

    } on TimeoutException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de timeout: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // Mostrar error genérico sin detalles técnicos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error durante la sincronización. Por favor, verifique la conexión e intente nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );

      // Log del error real (en producción usar un logger)
      debugPrint('Error en sincronización: $e');
    } finally {
      await _currentConnection?.disconnect();
      _currentConnection = null;
    }
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Sincronización',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
            '¿Está seguro de realizar una nueva sincronización? Esto reemplazará los datos existentes.'),
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
              backgroundColor: const Color(0xFF264024),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future _showProgressDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sincronizando Datos', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: _currentOperationNotifier,
                builder: (context, operation, _) {
                  return Text(operation);
                },
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: _currentTableNotifier,
                builder: (context, table, _) {
                  return Text('Tabla: $table');
                },
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: _progressNotifier,
                builder: (context, progress, _) {
                  return Text('Progreso: $progress%');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _cancelOperation();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDataSyncInternal(
      Map<String, String> connectionData,
      Database db,
      bool shouldDeleteTables
      ) async {
    _currentConnection = MssqlConnection.getInstance();

    _currentOperationNotifier.value = 'Conectando con el servidor...';

    final connectionFuture = _currentConnection!.connect(
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

    // Verificar permisos de tablas
    _currentOperationNotifier.value = 'Verificando permisos...';
    await _verifyTablePermissions(_currentConnection!);

    final queries = [
      'SELECT codigo_cliente, cliente, cliente_id, razonsocial FROM DATA_CLIENTES',
      'SELECT cliente_id, codigo_planta, planta_id, dep, dep_id, planta, dir FROM DATA_PLANTAS',
      'SELECT * FROM DATA_EQUIPOS_BALANZAS',
      'SELECT * FROM DATA_EQUIPOS',
      'SELECT * FROM DATA_EQUIPOS_CAL',
      'SELECT * FROM DATA_SERVICIOS_LEC'
    ];

    _currentOperationNotifier.value = 'Descargando datos...';
    final results = await Future.wait([
      for (var i = 0; i < queries.length; i++)
        _executeQueryWithTimeout(_currentConnection!, queries[i], const Duration(seconds: 60))
    ]);

    // Procesar cada tabla por separado para evitar transacciones gigantes
    await _processTableInTransaction(db, 'clientes', results[0], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    await _processTableInTransaction(db, 'plantas', results[1], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    await _processTableInTransaction(db, 'balanzas', results[2], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    await _processTableInTransaction(db, 'inf', results[3], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    await _processTableInTransaction(db, 'equipamientos', results[4], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    await _processTableInTransaction(db, 'servicios', results[5], shouldDeleteTables);
    if (_isCancelled) throw Exception('Operación cancelada por el usuario');

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toString();
    await prefs.setString('lastUpdate', now);

    if (mounted) {
      setState(() {
        lastUpdate = now;
        _isUpdating = false;
      });
    }

    // Reiniciar el timer de auto-delete
    _autoDeleteTimer?.cancel();
    _startAutoDeleteTimer();
  }

  Future<void> _verifyTablePermissions(MssqlConnection connection) async {
    final testQueries = [
      'SELECT TOP 1 * FROM DATA_CLIENTES',
      'SELECT TOP 1 * FROM DATA_PLANTAS',
      'SELECT TOP 1 * FROM DATA_EQUIPOS_BALANZAS',
      'SELECT TOP 1 * FROM DATA_EQUIPOS',
      'SELECT TOP 1 * FROM DATA_EQUIPOS_CAL',
      'SELECT TOP 1 * FROM DATA_SERVICIOS_LEC'
    ];

    for (var query in testQueries) {
      try {
        await _executeQueryWithTimeout(connection, query, const Duration(seconds: 10));
      } catch (e) {
        throw Exception('No tiene permisos para acceder a todas las tablas necesarias');
      }
    }
  }

  Future<void> _processTableInTransaction(
      Database db,
      String tableName,
      List<Map<String, dynamic>> data,
      bool shouldDeleteTables
      ) async {
    _currentTableNotifier.value = tableName;

    await db.transaction((txn) async {
      if (shouldDeleteTables) {
        await txn.delete(tableName);
      }

      int itemsProcesados = 0;
      final totalItems = data.length;

      for (var item in data) {
        if (_isCancelled) break;

        try {
          await _insertValidatedData(txn, tableName, item);
        } catch (e) {
          debugPrint('Error insertando en $tableName: $e');
          // Continuar con el siguiente registro en lugar de fallar toda la transacción
          continue;
        }

        itemsProcesados++;
        if (itemsProcesados % 10 == 0 || itemsProcesados == totalItems) {
          final progress = ((itemsProcesados / totalItems) * 100).toInt();
          _progressNotifier.value = progress;
        }
      }
    });
  }

  Future<void> _insertValidatedData(Transaction txn, String tableName, Map<String, dynamic> data) async {
    switch (tableName) {
      case 'clientes':
        final codigoCliente = data['codigo_cliente']?.toString();
        final clienteId = data['cliente_id']?.toString();
        if (codigoCliente == null || clienteId == null) {
          throw Exception('Datos inválidos para cliente');
        }
        await txn.insert('clientes', {
          'codigo_cliente': codigoCliente,
          'cliente_id': clienteId,
          'cliente': data['cliente']?.toString() ?? '',
          'razonsocial': data['razonsocial']?.toString() ?? '',
        });
        break;

      case 'plantas':
        final plantaId = data['planta_id']?.toString();
        final clienteId = data['cliente_id']?.toString();
        final depId = data['dep_id']?.toString();
        if (plantaId == null || clienteId == null || depId == null) {
          throw Exception('Datos inválidos para planta');
        }
        await txn.insert('plantas', {
          'planta': data['planta']?.toString() ?? '',
          'planta_id': plantaId,
          'cliente_id': clienteId,
          'dep_id': depId,
          'unique_key': '${plantaId}_$depId',
          'codigo_planta': data['codigo_planta']?.toString() ?? '',
          'dep': data['dep']?.toString() ?? '',
          'dir': data['dir']?.toString() ?? '',
        });
        break;

      case 'balanzas':
        final codMetrica = data['cod_metrica']?.toString();
        if (codMetrica == null) {
          throw Exception('Datos inválidos para balanza');
        }
        await txn.insert('balanzas', {
          'cod_metrica': codMetrica,
          'serie': data['serie']?.toString() ?? '',
          'unidad': data['unidad']?.toString() ?? '',
          'n_celdas': data['n_celdas']?.toString() ?? '',
          'cap_max1': data['cap_max1']?.toString() ?? '',
          'd1': data['d1']?.toString() ?? '',
          'e1': data['e1']?.toString() ?? '',
          'dec1': data['dec1']?.toString() ?? '',
          'cap_max2': data['cap_max2']?.toString() ?? '',
          'd2': data['d2']?.toString() ?? '',
          'e2': data['e2']?.toString() ?? '',
          'dec2': data['dec2']?.toString() ?? '',
          'cap_max3': data['cap_max3']?.toString() ?? '',
          'd3': data['d3']?.toString() ?? '',
          'e3': data['e3']?.toString() ?? '',
          'dec3': data['dec3']?.toString() ?? '',
          'categoria': data['categoria']?.toString() ?? '',
        });
        break;

      case 'inf':
        final codInterno = data['cod_interno']?.toString();
        if (codInterno == null) {
          throw Exception('Datos inválidos para inf');
        }
        await txn.insert('inf', {
          'cod_interno': codInterno,
          'cod_metrica': data['cod_metrica']?.toString() ?? '',
          'instrumento': data['instrumento']?.toString() ?? '',
          'tipo_instrumento': data['tipo_instrumento']?.toString() ?? '',
          'marca': data['marca']?.toString() ?? '',
          'modelo': data['modelo']?.toString() ?? '',
          'serie': data['serie']?.toString() ?? '',
          'estado': data['estado']?.toString() ?? '',
          'detalles': data['detalles']?.toString() ?? '',
          'ubicacion': data['ubicacion']?.toString() ?? '',
        });
        break;

      case 'equipamientos':
        final codInstrumento = data['cod_instrumento']?.toString();
        if (codInstrumento == null) {
          throw Exception('Datos inválidos para equipamiento');
        }
        await txn.insert('equipamientos', {
          'cod_instrumento': codInstrumento,
          'instrumento': data['instrumento']?.toString() ?? '',
          'cert_fecha': data['cert_fecha']?.toString() ?? '',
          'ente_calibrador': data['ente_calibrador']?.toString() ?? '',
          'estado': data['estado']?.toString() ?? '',
        });
        break;

      case 'servicios':
        final codMetrica = data['cod_metrica']?.toString();
        if (codMetrica == null) {
          throw Exception('Datos inválidos para servicio');
        }
        // Insertar solo campos esenciales para servicios, el resto pueden ser null
        final Map<String, dynamic> servicioData = {
          'cod_metrica': codMetrica,
          'seca': data['seca']?.toString() ?? '',
          'reg_fecha': data['reg_fecha']?.toString() ?? '',
          'reg_usuario': data['reg_usuario']?.toString() ?? '',
          'exc': data['exc']?.toString() ?? '',
        };

        // Agregar campos rep y lin solo si existen
        for (int i = 1; i <= 30; i++) {
          final repKey = 'rep$i';
          if (data.containsKey(repKey)) {
            servicioData[repKey] = data[repKey]?.toString() ?? '';
          }
        }

        for (int i = 1; i <= 60; i++) {
          final linKey = 'lin$i';
          if (data.containsKey(linKey)) {
            servicioData[linKey] = data[linKey]?.toString() ?? '';
          }
        }

        await txn.insert('servicios', servicioData);
        break;

      default:
        throw Exception('Tabla desconocida: $tableName');
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

      if (mounted) {
        setState(() {
          lastUpdate = null;
        });
      }

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precarga eliminada correctamente')),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
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