import 'dart:ui';
import 'package:service_met/screens/offline/rds_screen.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../bdb/calibracion_bd_bn.dart';



class PrecargaNbScreen extends StatefulWidget {
  final String userName;
  const PrecargaNbScreen({
    super.key,
    required this.userName,
  });

  @override
  _PrecargaNbScreenState createState() => _PrecargaNbScreenState();
}

class _PrecargaNbScreenState extends State<PrecargaNbScreen> {
  String? errorMessage;
  String? _secaValue;
  DatabaseHelperbn? _dbHelper;
  bool isDatabaseCreated = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  @override
  void dispose() {
    _dbNameController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<String> _createDatabase(BuildContext context, String dbName) async {
    try {
      final dbHelper = DatabaseHelperbn();
      String path = join(await getDatabasesPath(), '$dbName.db');
      await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await dbHelper.onCreate(db, version);
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La base de datos $dbName ha sido creada exitosamente')),
      );
      return path;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la base de datos: $e')),
      );
      return '';
    }
  }

  void _showCreateDatabaseDialog(BuildContext context) async {
    String dbName = 'balanzas_nuevas';
    String path = join(await getDatabasesPath(), '$dbName.db');
    bool dbExists = await databaseExists(path);

    if (dbExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tiene el almacenamiento creado.')),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'CONFIRMACIÓN',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text('Se creará el almacenamiento para el guardado de datos de las balanzas nuevas.'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _createDatabase(context, dbName);
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showConfirmationDialog(BuildContext context) async {
    String dbName = 'balanzas_nuevas';
    String path = join(await getDatabasesPath(), '$dbName.db');
    bool dbExists = await databaseExists(path);

    if (dbExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tiene el almacenamiento creado.')),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'CONFIRMACIÓN',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text('Se creará el almacenamiento para el guardado de datos de las balanzas nuevas.'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  String dbPath = await _createDatabase(context, dbName);
                  if (dbPath.isNotEmpty) {
                    Navigator.of(context).pop(); // Cerrar el diálogo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RdsScreen(
                          dbName: dbName,
                          userName: widget.userName,
                          dbPath: dbPath,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
    // Navegar a RdsScreen en ambos casos (si la base de datos ya existe o si se acaba de crear)
    if (dbExists) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RdsScreen(
            dbName: dbName,
            userName: widget.userName,
            dbPath: path, // Usar la ruta de la base de datos existente
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'NUEVA BALANZA',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'ELIJA EL ÁREA DE TRABAJO PARA LA NUEVA BALANZA.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                _showCreateDatabaseDialog(context);
                _showConfirmationDialog(context);
              },
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
                          image: AssetImage('images/tarjetas/t7.png'),
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
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'CALIBRACIÓN',
                          style: TextStyle(
                            fontSize: 18,
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
            Card(
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
                        image: AssetImage('images/tarjetas/t8.png'),
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
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SOPORTE TÉCNICO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}