  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:path/path.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:sqflite/sqflite.dart';
  import 'package:service_met/bdb/calibracion_bd.dart';
  import '../../database/app_database.dart';
  import 'iden_balanza_screen.dart';
  
  class CalibracionScreen extends StatefulWidget {
    final String secaValue;
    final String dbName;
    final String userName;
    final String sessionId; // <-- Nuevo parámetro
    const CalibracionScreen({
      super.key,
      required this.dbName,
      required this.userName,
      required this.secaValue,
      required this.sessionId, // <-- obligatorio al crear la pantalla
    });
  
    @override
    _CalibracionScreenState createState() => _CalibracionScreenState();
  }
  
  class _CalibracionScreenState extends State<CalibracionScreen> {
    List<dynamic> equipos = [];
    List<dynamic> filteredEquipos = [];
    List<Map<String, dynamic>> selectedEquipos = [];
    final List<TextEditingController> _cantidadControllers = [];
    List<dynamic>? clientes;
    List<dynamic>? filteredClientes;
    List<dynamic>? plantas;
    String? errorMessage;
    String? userName;
    DatabaseHelper? _dbHelper;
    bool isDatabaseCreated = false;
    bool isDataSaved = false;
  
    String? selectedClienteId;
    String? selectedClienteName;
    String? selectedClienteRazonSocial;
    String? selectedPlantaKey;
    String? selectedPlantaDir;
    String? selectedPlantaDep;
    String? selectedPlantaCodigo;
    DateTime? _lastPressedTime;
    bool isNewClient = false; // Variable para controlar si es un cliente nuevo
  
    final TextEditingController _depController = TextEditingController();
    final TextEditingController _codigoPlantaController = TextEditingController();
    final TextEditingController _plantaController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();
    final TextEditingController _plantaDirController = TextEditingController();
    final TextEditingController _plantaDepController = TextEditingController();
    final TextEditingController _razonSocialController = TextEditingController();
    final TextEditingController _dbNameController = TextEditingController();
    final ValueNotifier<bool> _isNextButtonVisible = ValueNotifier<bool>(false);
    final TextEditingController _nombreComercialController =
        TextEditingController();
  
    @override
    void initState() {
      super.initState();
      _fetchClientes();
      _fetchEquipos(); // Nuevo: cargar equipos al iniciar
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
      _isNextButtonVisible.dispose();
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
        selectedClienteId = cliente['cliente_id']?.toString() ?? '';
        selectedClienteName = cliente['cliente']?.toString() ?? 'No especificado';
        selectedClienteRazonSocial =
            cliente['razonsocial']?.toString() ?? 'No especificado';
        _razonSocialController.text = selectedClienteRazonSocial ?? '';
        _nombreComercialController.text = selectedClienteName ?? '';
        _clearPlantaData();
        _fetchPlantas(selectedClienteId!);
      });
    }
  
    Future<void> _fetchEquipos() async {
      try {
        String path = join(await getDatabasesPath(), 'precarga_database.db');
        final db = await openDatabase(path);
  
        final List<Map<String, dynamic>> equiposList = await db.query(
          'equipamientos',
          where: "estado != 'DESACTIVADO'",
        );
  
        setState(() {
          equipos = equiposList;
          filteredEquipos = equiposList;
          errorMessage = null;
        });
  
        await db.close();
      } catch (e) {
        setState(() {
          errorMessage = 'Error al cargar los equipos de ayuda: $e';
        });
      }
    }
  
    void _showTermohigrometrosSelection(BuildContext context) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          final termohigrometros = equipos.where((equipo) {
            final instrumento = equipo['instrumento']?.toString() ?? '';
            return instrumento.contains('Termohigrómetro') ||
                instrumento.contains('Termohigrobarómetro');
          }).toList();
  
          final Map<String, Map<String, dynamic>> uniqueTermos = {};
          for (var termo in termohigrometros) {
            final codInstrumento = termo['cod_instrumento'].toString();
            final certFecha = DateTime.parse(termo['cert_fecha']);
  
            if (!uniqueTermos.containsKey(codInstrumento)) {
              uniqueTermos[codInstrumento] = termo;
            } else {
              final currentFecha =
                  DateTime.parse(uniqueTermos[codInstrumento]!['cert_fecha']);
              if (certFecha.isAfter(currentFecha)) {
                uniqueTermos[codInstrumento] = termo;
              }
            }
          }
  
          final List<Map<String, dynamic>> termosUnicos =
              uniqueTermos.values.toList();
  
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                children: [
                  const SizedBox(height: 16.0),
                  const Text(
                    'SELECCIONAR TERMOHIGRÓMETROS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Seleccione los termohigrómetros para el servicio (1-2)',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: termosUnicos.length,
                      itemBuilder: (context, index) {
                        final equipo = termosUnicos[index];
                        final certFecha = DateTime.parse(equipo['cert_fecha']);
                        final difference =
                            DateTime.now().difference(certFecha).inDays;
  
                        return CheckboxListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${equipo['cod_instrumento']}'),
                              Text(
                                'Certificado: ${equipo['cert_fecha']} ($difference días)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: difference > 365
                                      ? Colors.red
                                      : difference > 300
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              'Ente calibrador: ${equipo['ente_calibrador']}'),
                          value: selectedEquipos.any((e) =>
                              e['cod_instrumento'] == equipo['cod_instrumento'] &&
                              e['tipo'] == 'termohigrometro'),
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                if (selectedEquipos
                                        .where(
                                            (e) => e['tipo'] == 'termohigrometro')
                                        .length <
                                    2) {
                                  selectedEquipos.add({
                                    ...equipo,
                                    'cantidad': '1',
                                    'tipo': 'termohigrometro'
                                  });
                                  _cantidadControllers
                                      .add(TextEditingController(text: '1'));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Máximo 2 termohigrómetros permitidos')),
                                  );
                                }
                              } else {
                                final index = selectedEquipos.indexWhere((e) =>
                                    e['cod_instrumento'] ==
                                        equipo['cod_instrumento'] &&
                                    e['tipo'] == 'termohigrometro');
                                if (index != -1) {
                                  selectedEquipos.removeAt(index);
                                  _cantidadControllers.removeAt(index);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedEquipos
                          .any((e) => e['tipo'] == 'termohigrometro')) {
                        setState(() {});
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Seleccione al menos un termohigrómetro')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('CONFIRMAR SELECCIÓN'),
                  ),
                  const SizedBox(height: 16.0),
                ],
              );
            },
          );
        },
      );
    }

    Future<void> _saveDataToDatabase(BuildContext context) async {
      if ((selectedClienteName ?? '').isEmpty) {
        _showSnackBar(context, 'Por favor seleccione un cliente');
        return;
      }

      if (_codigoPlantaController.text.trim().isEmpty) {
        _showSnackBar(context, 'Por favor seleccione una planta');
        return;
      }

      if (selectedEquipos.isEmpty) {
        _showSnackBar(
            context, 'Por favor seleccione al menos un termohigrómetro');
        return;
      }

      try {
        final dbHelper = AppDatabase();
        // Verificar si el registro ya existe
        final existingRecord = await dbHelper.getRegistroBySeca(widget.secaValue, widget.sessionId);
        // Obtener el valor de la planta (lo que se muestra en el dropdown)
        final nombrePlanta = _plantaController.text.trim().isNotEmpty
            ? _plantaController.text.trim()
            : 'No especificado';

        // Armar registro con valores seguros (nunca null)
        final registro = {
          'seca': widget.secaValue,
          'session_id': widget.sessionId,
          'personal': widget.userName,
          'cliente': selectedClienteName?.trim().isNotEmpty == true
              ? selectedClienteName!.trim()
              : 'No especificado',
          'razon_social': _razonSocialController.text.trim().isNotEmpty
              ? _razonSocialController.text.trim()
              : 'No especificado',
          'planta': nombrePlanta, // ← CAMBIO AQUÍ: usar el nombre de la planta
          'dir_planta': _plantaDirController.text.trim().isNotEmpty // ← NUEVA COLUMNA
              ? _plantaDirController.text.trim()
              : 'No especificado',
          'dep_planta': _plantaDepController.text.trim().isNotEmpty
              ? _plantaDepController.text.trim()
              : 'No especificado',
          'cod_planta': _codigoPlantaController.text.trim().isNotEmpty
              ? _codigoPlantaController.text.trim()
              : 'No especificado',
          ..._getEquiposData(),
        };

        if (existingRecord != null) {
          await dbHelper.upsertRegistroCalibracion(registro);
        } else {
          await dbHelper.insertRegistroCalibracion(registro);
        }

        setState(() {
          isDataSaved = true;
        });

        _showSnackBar(context, 'Datos guardados exitosamente');
        _isNextButtonVisible.value = true;
      } catch (e, stackTrace) {
        _showSnackBar(context, 'Error al guardar los datos: $e', isError: true);
        debugPrint('Error al guardar los datos: $e');
        debugPrint('StackTrace: $stackTrace');
      }
    }
  
    Map<String, dynamic> _getEquiposData() {
      final data = <String, dynamic>{};
  
      final termohigrometros =
          selectedEquipos.where((e) => e['tipo'] == 'termohigrometro').toList();
  
      for (int i = 0; i < termohigrometros.length; i++) {
        if (i < 2) {
          final equipo = termohigrometros[i];
          // Asegurar que ningún valor sea null usando ?.toString() ?? ''
          data['equipo${6 + i}'] = equipo['cod_instrumento']?.toString() ?? '';
          data['certificado${6 + i}'] = equipo['cert_fecha']?.toString() ?? '';
          data['ente_calibrador${6 + i}'] =
              equipo['ente_calibrador']?.toString() ?? '';
          data['estado${6 + i}'] = equipo['estado']?.toString() ?? '';
          data['cantidad${6 + i}'] = '1'; // Este siempre tiene valor
        }
      }
      return data;
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
        _depController.text = planta['dep']?.toString() ?? '';
        _codigoPlantaController.text = planta['codigo_planta']?.toString() ?? '';
        _plantaController.text = planta['planta']?.toString() ?? '';
        selectedPlantaDir = planta['dir']?.toString() ?? 'No especificado';
        selectedPlantaDep = planta['dep']?.toString() ?? 'No especificado';
        selectedPlantaCodigo =
            planta['codigo_planta']?.toString() ?? 'No especificado';
        _plantaDirController.text = selectedPlantaDir ?? '';
        _plantaDepController.text = selectedPlantaDep ?? '';
        _nombreComercialController.text =
            planta['planta']?.toString() ?? selectedClienteName ?? '';
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
  
    void _showConfirmationDialog(BuildContext context) {
      if (isNewClient) {
        // Mostrar diálogo de confirmación para cliente nuevo
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'REGISTRANDO CLIENTE NUEVO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              content: const Text(
                'Está registrando un cliente nuevo. No podrá ver una lista de balanzas.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancelar',
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IdenBalanzaScreen(
                          selectedPlantaCodigo: _codigoPlantaController.text,
                          selectedCliente: selectedClienteName!,
                          secaValue: widget.secaValue,
                          sessionId: widget.sessionId,
                          loadFromSharedPreferences: false,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        // Validación para cliente existente
        if (selectedClienteId == null) {
          _showErrorDialog(context, 'Por favor seleccione un cliente.');
          return;
        }
        if (selectedPlantaKey == null) {
          _showErrorDialog(context, 'Por favor seleccione una planta.');
          return;
        }
  
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'CONFIRMACIÓN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              content: const Text(
                '¿Está seguro de los datos registrados?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'No',
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    if (!isDataSaved) {
                      _showSnackBar(context,
                          'Por favor guarde los datos antes de continuar.');
                      Navigator.of(context).pop();
                      return;
                    }
                    _saveSelectedClientAndPlant(
                        selectedPlantaCodigo!, selectedClienteName!);
  
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IdenBalanzaScreen(
                          selectedPlantaCodigo: selectedPlantaCodigo!,
                          selectedCliente: selectedClienteName!,
                          secaValue: widget.secaValue,
                          sessionId: widget.sessionId,
                          loadFromSharedPreferences: false,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Sí',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  
    void _saveSelectedClientAndPlant(
        String selectedPlantaCodigo, String selectedCliente) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedPlantaCodigo', selectedPlantaCodigo);
      await prefs.setString('selectedCliente', selectedCliente);
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
                          prefixIcon: const Icon(Icons.manage_search),
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
        {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white), // color del texto
          ),
          // Usa `SnackBarTheme` o personaliza aquí:
          backgroundColor: isError
              ? Colors.red
              : Colors.green, // esto aún funciona en versiones actuales
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  
    Future<bool> _onWillPop(BuildContext context) async {
      final now = DateTime.now();
      if (_lastPressedTime == null ||
          now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
        _lastPressedTime = now;
        _showSnackBar(context,
            'Presione nuevamente para retroceder. Los datos registrados se perderán.');
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
  
    @override
    Widget build(BuildContext context) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
      return WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: 70,
            title: const Text(
              'CALIBRACIÓN',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            centerTitle: true,
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
            actions: [
              if (selectedPlantaDir != null && selectedPlantaDep != null ||
                  isNewClient)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.device_thermostat, size: 28),
                        if (selectedEquipos
                            .any((e) => e['tipo'] == 'termohigrometro'))
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${selectedEquipos.where((e) => e['tipo'] == 'termohigrometro').length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => _showTermohigrometrosSelection(context),
                    tooltip: 'Seleccionar termohigrómetros',
                  ),
                ),
            ],
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
                        top: kToolbarHeight +
                            MediaQuery.of(context).padding.top +
                            40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
                        left: 16.0, // Tu padding horizontal original
                        right: 16.0, // Tu padding horizontal original
                        bottom: 16.0, // Tu padding inferior original
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SELECCIÓN DE CLIENTE Y PLANTA',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20.0),
                          TextFormField(
                            initialValue: widget.userName.isNotEmpty
                                ? widget.userName
                                : null,
                            decoration: buildInputDecoration(
                              'Técnico Responsable',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            readOnly: widget.userName.isNotEmpty,
                            onChanged: (value) {
                              if (widget.userName.isEmpty) {
                                setState(() {
                                  userName = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 5.0),
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white60
                                    : Colors.black,
                                size: 16.0,
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  'El nombre del técnico responsable no es editable',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontStyle:
                                        FontStyle.italic, // Texto en cursiva
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showClientSearch(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF007195),
                                  ),
                                  child: const Text(
                                    'SELECCIONAR CLIENTE',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _showNewClientFields,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3e7732),
                                  ),
                                  child: const Text(
                                    'CLIENTE NUEVO',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                    ),
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
                                  'EMPRESA - NOMBRE COMERCIAL:',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 5.0),
                                if (isNewClient)
                                  TextFormField(
                                    controller: _nombreComercialController, // Controlador para Nombre Comercial
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre Comercial',
                                      border: OutlineInputBorder(),
                                    ),
                                    readOnly: false, // Permitir edición
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
                                        fontWeight: FontWeight.w900),
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 20.0),
                                TextFormField(
                                  controller:
                                      _razonSocialController, // Controlador para Razón Social
                                  decoration: buildInputDecoration(
                                    'Razón Social',
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                              ],
                            ),
                          const SizedBox(height: 16.0),
                          if (isNewClient)
                            Column(
                              children: [
                                TextFormField(
                                  controller:
                                      _plantaDirController, // Controlador para Dirección de la Planta
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección de la Planta',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                                const SizedBox(height: 10.0),
                                TextFormField(
                                  controller:
                                      _plantaDepController, // Controlador para Departamento de la Planta
                                  decoration: const InputDecoration(
                                    labelText: 'Departamento de la Planta',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                                const SizedBox(height: 10.0),
                                TextFormField(
                                  controller:
                                      _codigoPlantaController, // Controlador para Código de la Planta
                                  decoration: const InputDecoration(
                                    labelText: 'Código de la Planta',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: false, // Permitir edición
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
                                    _nombreComercialController.text =
                                        '${selectedPlanta['planta']}';
                                  } else {
                                    setState(() {
                                      errorMessage =
                                          'No se encontró la planta seleccionada';
                                    });
                                  }
                                }
                              },
                              decoration: buildInputDecoration(
                                'Seleccione una planta',
                              ),
                            ),
                          if (selectedPlantaDir != null &&
                                  selectedPlantaDep != null ||
                              isNewClient)
                            Column(
                              children: [
                                const SizedBox(height: 14.0),
                                TextFormField(
                                  controller:
                                      _plantaDirController, // Controlador para Dirección de la Planta
                                  decoration: buildInputDecoration(
                                    'Dirección de la Planta',
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                                const SizedBox(height: 14.0),
                                TextFormField(
                                  controller:
                                      _plantaDepController, // Controlador para Departamento de la Planta
                                  decoration: buildInputDecoration(
                                    'Departamento de la Planta',
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                                const SizedBox(height: 14.0),
                                TextFormField(
                                  controller:
                                      _codigoPlantaController, // Controlador para Código de la Planta
                                  decoration: buildInputDecoration(
                                    'Código de la Planta',
                                  ),
                                  readOnly: false, // Permitir edición
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _saveDataToDatabase(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF007195),
                                          ),
                                          child: const Text('1: GUARDAR'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 48,
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: _isNextButtonVisible,
                                          builder: (context, isVisible, child) {
                                            return AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              transitionBuilder:
                                                  (child, animation) =>
                                                      FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                ),
                                              ),
                                              child: isVisible
                                                  ? ElevatedButton.icon(
                                                      key: const ValueKey(
                                                          'next_button'),
                                                      onPressed: () => _showConfirmationDialog(context),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF3e7732),
                                                      ),
                                                      icon: const Icon(Icons.arrow_forward),
                                                      label: const Text('2: SIGUIENTE'),
                                                    )
                                                  : const SizedBox.shrink(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          const SizedBox(height: 16.0),
                          const Form(
                            child: Column(
                              children: [],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      );
    }
  }
