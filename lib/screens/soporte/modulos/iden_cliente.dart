import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_met/screens/soporte/modulos/iden_balanza.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:service_met/bdb/calibracion_bd.dart';

class IdenClienteScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String fechaServicio;
  final String numeroOT;
  final String dbPath;
  final String otValue;

  const IdenClienteScreen({
    super.key,
    required this.dbName,
    required this.dbPath,
    required this.userName,
    required this.fechaServicio,
    required this.numeroOT,
    required this.otValue,
  });

  @override
  _IdenClienteScreenState createState() => _IdenClienteScreenState();
}

class _IdenClienteScreenState extends State<IdenClienteScreen> {
  List<dynamic>? clientes;
  List<dynamic>? filteredClientes;
  List<dynamic>? plantas;
  String? errorMessage;
  String? userName;
  DatabaseHelper? _dbHelper;

  String? selectedClienteId;
  String? selectedClienteName;
  String? selectedClienteRazonSocial;
  String? selectedPlantaKey;
  String? selectedPlantaDir;
  String? selectedPlantaDep;
  String? selectedPlantaCodigo;
  DateTime? _lastPressedTime;
  bool isNewClient = false;

  final TextEditingController _depController = TextEditingController();
  final TextEditingController _codigoPlantaController = TextEditingController();
  final TextEditingController _plantaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _plantaDirController = TextEditingController();
  final TextEditingController _plantaDepController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _dbNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClientes();
    _searchController.addListener(_filterClientes);
  }

  @override
  void dispose() {
    _depController.dispose();
    _codigoPlantaController.dispose();
    _plantaController.dispose();
    _searchController.dispose();
    _plantaDirController.dispose();
    _plantaDepController.dispose();
    _razonSocialController.dispose();
    super.dispose();
  }

  void _showNewClientFields() {
    setState(() {
      isNewClient = true;
      selectedClienteName = null;
      selectedClienteId = null;
      plantas = null;
      selectedPlantaKey = null;
      _razonSocialController.clear();
      _plantaDirController.clear();
      _plantaDepController.clear();
      _codigoPlantaController.clear();
    });
  }

  void _selectClientFromList(Map<String, dynamic> cliente) {
    setState(() {
      isNewClient = false;
      selectedClienteId = cliente['cliente_id'].toString();
      selectedClienteName = cliente['cliente'];
      selectedClienteRazonSocial = cliente['razonsocial'];
      _razonSocialController.text = selectedClienteRazonSocial ?? '';
      _clearPlantaData();
      _fetchPlantas(selectedClienteId!);
    });
  }

  Future<void> _fetchClientes() async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path);
      final List<Map<String, dynamic>> clientesList =
          await db.query('clientes');

      setState(() {
        clientes = clientesList;
        filteredClientes = clientesList;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener clientes: $e';
      });
    }
  }

  void _filterClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredClientes = clientes?.where((cliente) {
        final clienteName = cliente['cliente']?.toLowerCase() ?? '';
        return clienteName.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPlantas(String clienteId) async {
    Database? db;
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      db = await openDatabase(path);

      final List<Map<String, dynamic>> plantasList = await db.query(
        'plantas',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
      );

      final plantasModificadas = plantasList.map((planta) {
        return {
          ...planta,
          'unique_key': '${planta['planta_id']}_${planta['dep_id']}',
        };
      }).toList();

      setState(() {
        plantas = plantasModificadas;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener plantas: $e';
      });
    } finally {
      if (db != null) {
        await db.close();
      }
    }
  }

  void _fillFormWithPlantaData(Map<String, dynamic> planta) {
    setState(() {
      _depController.text = planta['dep'] ?? '';
      _codigoPlantaController.text = planta['codigo_planta'] ?? '';
      _plantaController.text = planta['planta'] ?? '';
      selectedPlantaDir = planta['dir'];
      selectedPlantaDep = planta['dep'];
      selectedPlantaCodigo = planta['codigo_planta'];
      _plantaDirController.text = selectedPlantaDir ?? '';
      _plantaDepController.text = selectedPlantaDep ?? '';
    });
  }

  void _clearPlantaData() {
    setState(() {
      selectedPlantaKey = null;
      selectedPlantaDir = null;
      selectedPlantaDep = null;
      selectedPlantaCodigo = null;
      _depController.clear();
      _codigoPlantaController.clear();
      _plantaController.clear();
      _plantaDirController.clear();
      _plantaDepController.clear();
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'ERROR',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showClientSearch(BuildContext context) async {
    try {
      String path = join(await getDatabasesPath(), 'precarga_database.db');
      final db = await openDatabase(path, readOnly: false);

      final List<Map<String, dynamic>> clientesList =
          await db.query('clientes');

      setState(() {
        clientes = clientesList;
        filteredClientes = clientesList;
      });

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'LISTA DE CLIENTES',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar cliente',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _filterClientes();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredClientes?.length ?? 0,
                      itemBuilder: (context, index) {
                        final cliente = filteredClientes![index];
                        return ListTile(
                          title:
                              Text(cliente['cliente'] ?? 'Cliente desconocido'),
                          onTap: () {
                            _selectClientFromList(cliente);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error al buscar clientes: $e';
      });
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: textColor ?? Colors.black), // Texto blanco por defecto
        ),
        backgroundColor:
            backgroundColor ?? Colors.grey, // Fondo naranja por defecto
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(
        context,
        'Presione nuevamente para retroceder. Los datos registrados se perderán.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  Future<void> _saveClientData(BuildContext context) async {
    try {
      // Abrir la base de datos específica para esta OTST
      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      // Crear el mapa de datos a insertar o actualizar
      final Map<String, dynamic> clienteData = {
        'id': 1, // Asegurarse de que siempre sea la primera fila
        'cliente': isNewClient ? selectedClienteName : _plantaController.text,
        'razon_social': _razonSocialController.text,
        'dep_planta': _plantaDepController.text,
        'direccion_planta': _plantaDirController.text,
      };

      // Intentar actualizar la fila con id=1
      int updatedRows = await db.update(
        'inf_cliente_balanza',
        clienteData,
        where: 'id = ?',
        whereArgs: [1],
      );

      // Si no se actualizó ninguna fila, insertar una nueva con id=1
      if (updatedRows == 0) {
        await db.insert(
          'inf_cliente_balanza',
          clienteData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Cerrar la base de datos
      await db.close();

      if (!mounted) return; // <-- Agrega esto antes de usar context
      _showSnackBar(
        context,
        'Datos del cliente guardados exitosamente',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      if (!mounted) return; // <-- Agrega esto antes de usar context
      _showSnackBar(
        context,
        'Error al guardar datos del cliente: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    bool isSaved = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isNewClient ? 'REGISTRANDO CLIENTE NUEVO' : 'CONFIRMACIÓN',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              content: Text(
                isNewClient
                    ? '¿Está seguro de continuar con este cliente nuevo?'
                    : '¿Está seguro de continuar con los datos seleccionados?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancelar',
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSaved
                      ? null
                      : () async {
                          await _saveClientData(context);
                          setState(() {
                            isSaved = true;
                          });
                        },
                  child: const Text('Guardar',
                      style: TextStyle(color: Colors.white)),
                ),
                if (isSaved)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF077dbc),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IdenBalanzaScreen(
                            selectedPlantaCodigo: isNewClient
                                ? _codigoPlantaController.text
                                : selectedPlantaCodigo!,
                            selectedCliente: selectedClienteName!,
                            selectedPlantaNombre: _plantaController.text,
                            loadFromSharedPreferences: false,
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                          ),
                        ),
                      );
                    },
                    child: const Text('Siguiente',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 70,
          title: Text(
            'SOPORTE TÉCNICO',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16, // Tamaño del texto ajustado a 17 px
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
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          centerTitle: true,
        ),
        body: errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : clientes == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
                        left: 16.0, // Tu padding horizontal original
                        right: 16.0, // Tu padding horizontal original
                        bottom: 16.0, // Tu padding inferior original
                      ),
                      child: Column(
                      children: [
                        const Text(
                          'SELECCION DE CLIENTE Y PLANTA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                              size: 16.0,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Haga clic en el botón "VER CLIENTES" para seleccionar un cliente, en caso de no existir un cliente puede registrar un cliente nuevo haciendo clic en el botón "CLIENTE NUEVO".',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showClientSearch(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                      0xFF077d8b), // Color cambiado aquí
                                ),
                                child: const Text(
                                  'VER CLIENTES',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showNewClientFields,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                      0xFF5cb207), // Color cambiado aquí
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.plus,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'CLIENTE NUEVO',
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        if (isNewClient || selectedClienteName != null)
                          Column(
                            children: [
                              const Text(
                                'EMPRESA SELECCIONADA:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5.0),
                              if (isNewClient)
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre Comercial',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedClienteName = value;
                                    });
                                  },
                                )
                              else
                                Text(
                                  selectedClienteName!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF629BC6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 20.0),
                              TextFormField(
                                controller: _razonSocialController,
                                decoration:
                                    buildInputDecoration('Razón Social'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16.0),
                        if (isNewClient)
                          Column(
                            children: [
                              TextFormField(
                                controller: _plantaDirController,
                                decoration: const InputDecoration(
                                  labelText: 'Dirección de la Planta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              TextFormField(
                                controller: _plantaDepController,
                                decoration: const InputDecoration(
                                  labelText: 'Departamento de la Planta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              TextFormField(
                                controller: _codigoPlantaController,
                                decoration: const InputDecoration(
                                  labelText: 'Código de la Planta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          )
                        else if (selectedClienteId != null && plantas != null)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedPlantaKey,
                            items: plantas!.map((planta) {
                              final uniqueKey = planta['unique_key'];
                              return DropdownMenuItem<String>(
                                value: uniqueKey,
                                child: Text('${planta['planta']}'),
                              );
                            }).toList(),
                            onChanged: (uniqueKey) {
                              if (uniqueKey != null) {
                                setState(() {
                                  selectedPlantaKey = uniqueKey;
                                });

                                final selectedPlanta = plantas!.firstWhere(
                                  (planta) => planta['unique_key'] == uniqueKey,
                                  orElse: () => <String, dynamic>{},
                                );

                                if (selectedPlanta != null &&
                                    selectedPlanta.isNotEmpty) {
                                  _fillFormWithPlantaData(selectedPlanta);
                                } else {
                                  setState(() {
                                    errorMessage =
                                        'No se encontró la planta seleccionada';
                                  });
                                }
                              }
                            },
                            decoration:
                                buildInputDecoration('Seleccione una planta'),
                          ),
                        if (selectedPlantaDir != null &&
                                selectedPlantaDep != null ||
                            isNewClient)
                          Column(
                            children: [
                              const SizedBox(height: 14.0),
                              TextFormField(
                                controller: _plantaDirController,
                                decoration: buildInputDecoration(
                                    'Dirección de la Planta'),
                              ),
                              const SizedBox(height: 14.0),
                              TextFormField(
                                controller: _plantaDepController,
                                decoration: buildInputDecoration(
                                    'Departamento de la Planta'),
                              ),
                              const SizedBox(height: 14.0),
                              TextFormField(
                                controller: _codigoPlantaController,
                                decoration:
                                    buildInputDecoration('Código de la Planta'),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () =>
                                    _showConfirmationDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('IR A SELECCIÓN DE BALANZA'),
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    size: 16.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      'Verifique los datos del cliente seleccionado antes de continuar, ya que al dar click en este boton estos datos son los que se visualizaran en el CSV.',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
