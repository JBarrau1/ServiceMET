import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController _dbUserController = TextEditingController();
  final TextEditingController _dbPassController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _configFormKey = GlobalKey<FormState>();

  bool recordarCredenciales = false;
  bool showConfig = false;
  bool _loading = false;
  final connection = MssqlConnection.getInstance();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

// Función para sanitizar entradas SQL
  String sanitizeInput(String input) {
    // Remueve caracteres peligrosos para SQL
    return input.replaceAll("'", "''")  // Escapa comillas simples
        .replaceAll(";", "")     // Remueve punto y coma
        .replaceAll("--", "")    // Remueve comentarios SQL
        .replaceAll("/*", "")    // Remueve comentarios de bloque
        .replaceAll("*/", "")
        .replaceAll("xp_", "")   // Remueve procedimientos peligrosos
        .replaceAll("sp_", "")
        .trim();
  }

// Validación adicional de entrada
  bool isValidInput(String input) {
    // No debe contener caracteres sospechosos
    final dangerousPatterns = [
      'drop', 'delete', 'insert', 'update', 'create', 'alter',
      'exec', 'execute', 'union', 'select', 'script'
    ];

    final lowerInput = input.toLowerCase();
    return !dangerousPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('ip') ?? '';
    _portController.text = prefs.getString('port') ?? '1433';
    _dbController.text = prefs.getString('database') ?? '';
    _dbUserController.text = prefs.getString('dbuser') ?? '';
    _dbPassController.text = '';

    _usuarioController.text = prefs.getString('usuario') ?? '';
    _passController.text = '';

    recordarCredenciales = prefs.getBool('recordar') ?? false;
    setState(() {});
  }

  Future<void> _savePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('port', _portController.text);
    await prefs.setString('database', _dbController.text);
    await prefs.setString('dbuser', _dbUserController.text);

    //HASHEAR CONTRASEÑA DE BD ANTES DE GUARDAR
    await prefs.setString('dbpass', hashPassword(_dbPassController.text));

    await prefs.setBool('recordar', recordarCredenciales);

    if (recordarCredenciales) {
      await prefs.setString('usuario', _usuarioController.text);
      //HASHEAR CONTRASEÑA DE USUARIO ANTES DE GUARDAR
      await prefs.setString('contrasena', hashPassword(_passController.text));
    } else {
      await prefs.remove('usuario');
      await prefs.remove('contrasena');
    }
  }

  Future<void> _saveUserToSQLite(Map<String, dynamic> userData) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');

    Database? db;
    try {
      db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre1 TEXT,
          apellido1 TEXT,
          pass TEXT,
          usuario TEXT,
          titulo_abr TEXT,
          estado TEXT,
          fecha_guardado TEXT
        )
      ''');
          });

      await db.delete('usuarios');

      final userDataConFecha = {
        ...userData,
        'fecha_guardado': DateTime.now().toIso8601String(),
      };

      await db.insert('usuarios', userDataConFecha);

    } catch (e) {
      print('Error guardando en SQLite: $e');
    } finally {
      await db?.close();
    }
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    final dbName = _dbController.text.trim();
    final dbUser = _dbUserController.text.trim();
    final dbPass = _dbPassController.text.trim();
    final usuario = _usuarioController.text.trim();
    final pass = _passController.text.trim();

    try {
      // 🔒 VALIDACIÓN DE SEGURIDAD
      if (!isValidInput(usuario) || !isValidInput(pass)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caracteres no válidos detectados')),
        );
        return;
      }

      // 🔒 SANITIZAR ENTRADAS
      final usuarioSeguro = sanitizeInput(usuario);
      final passSeguro = sanitizeInput(pass);

      // Configurar timeout de 15 segundos
      final timeoutDuration = const Duration(seconds: 15);

      // Conexión con timeout
      final connected = await connection
          .connect(
        ip: ip,
        port: port,
        databaseName: dbName,
        username: dbUser,
        password: dbPass,
      )
          .timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException(
            'La conexión tardó demasiado. Verifique su conexión a internet.');
      });

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con el servidor')),
        );
        return;
      }

      // 🔒 QUERY SQL MÁS SEGURA (aunque no sea completamente parametrizada)
      final query = '''
      SELECT nombre1, apellido1, pass, usuario, titulo_abr, estado 
      FROM data_users 
      WHERE usuario = '$usuarioSeguro' AND pass = '$passSeguro'
    ''';

      // Usamos getData() con timeout
      final resultJson = await connection
          .getData(query)
          .timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException(
            'La consulta tardó demasiado. El servidor puede estar lento.');
      });

      final List<dynamic> result = jsonDecode(resultJson);

      if (result.isNotEmpty) {
        final userData = Map<String, dynamic>.from(result.first);

        // 🔒 HASHEAR LA CONTRASEÑA ANTES DE GUARDAR LOCALMENTE
        final userDataSeguro = {
          ...userData,
          'pass': hashPassword(userData['pass']), // Hashear contraseña
        };

        await _saveUserToSQLite(userDataSeguro);
        await _savePrefs();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrecta')),
        );
      }
    } on TimeoutException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Tiempo de espera agotado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      await connection.disconnect();
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          'INICIO DE SESIÓN',
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
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
        padding: EdgeInsets.only(
          top: kToolbarHeight +
              MediaQuery.of(context).padding.top +
              40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
          left: 16.0, // Tu padding horizontal original
          right: 16.0, // Tu padding horizontal original
          bottom: 16.0, // Tu padding inferior original
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/logo_met.png',
                      height: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80.0),
              Text(
                'BIENVENIDO',
                style: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20.0,
                ),
              ),
              const SizedBox(height: 10.0),
              Center(
                child: Text(
                  'Ingrese el usuario y contraseña asignado por el área de sistemas, deben ser los mismos que se utilizan en el DataMET.',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w300,
                    fontSize: 13.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su contraseña';
                  }
                  if (value.length < 4) {
                    return 'La contraseña debe tener al menos 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              CheckboxListTile(
                value: recordarCredenciales,
                onChanged: (bool? value) {
                  setState(() {
                    recordarCredenciales = value ?? false;
                  });
                },
                title: const Text('Recordar usuario y contraseña'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E8833),
                ),
                onPressed: _loading ? null : () => _login(context),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 20.0),
              if (showConfig)
                Form(
                  key: _configFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _ipController,
                        decoration: const InputDecoration(labelText: 'IP'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la dirección IP';
                          }
                          // Validación básica de formato IP
                          final ipRegex =
                              RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
                          if (!ipRegex.hasMatch(value)) {
                            return 'Ingrese una dirección IP válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(labelText: 'Puerto'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el puerto';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port <= 0 || port > 65535) {
                            return 'Puerto inválido (1-65535)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _dbController,
                        decoration:
                            const InputDecoration(labelText: 'Base de datos'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el nombre de la base de datos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _dbUserController,
                        decoration:
                            const InputDecoration(labelText: 'Usuario BD'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el usuario de BD';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _dbPassController,
                        decoration:
                            const InputDecoration(labelText: 'Contraseña BD'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la contraseña de BD';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 10.0),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Text(
                        'Al iniciar sesión sin conexión, se utilizarán los datos de usuario y contraseña almacenados en el dispositivo. Si no ha iniciado sesión previamente, debe iniciar sesión en línea al menos una vez para que se guarden los datos.',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                          fontWeight: FontWeight.w400,
                          fontSize: 11.0,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9E2B2E),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          child: const Text('Iniciar sesión sin conexión'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E756F),
                          ),
                          onPressed: () {
                            setState(() => showConfig = !showConfig);
                          },
                          child: const Text('Configuración de conexión'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Text(
                'versión 10.1.1_3_061025',
                style: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 9.0,
                ),
              ),
              Text(
                'DESARROLLADO POR: J.FARFAN',
                style: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 9.0,
                ),
              ),
              Text(
                '© 2025 METRICA LTDA',
                style: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 9.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
