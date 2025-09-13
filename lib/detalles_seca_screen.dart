import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class DetallesSecaScreen extends StatefulWidget {
  final ServicioSeca servicioSeca;

  const DetallesSecaScreen({super.key, required this.servicioSeca});

  @override
  State<DetallesSecaScreen> createState() => _DetallesSecaScreenState();
}

class _DetallesSecaScreenState extends State<DetallesSecaScreen> {
  List<Map<String, dynamic>> balanzasEditadas = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con los datos originales
    balanzasEditadas = List.from(widget.servicioSeca.balanzas);
  }

  void _editarBalanza(int index, Map<String, dynamic> nuevosDatos) {
    setState(() {
      balanzasEditadas[index] = {...balanzasEditadas[index], ...nuevosDatos};
    });
  }

  Future<void> _exportarCSV() async {
    try {
      final List<List<dynamic>> csvData = [];

      // Encabezados
      if (balanzasEditadas.isNotEmpty) {
        csvData.add(balanzasEditadas.first.keys.toList());
      }

      // Datos
      for (var balanza in balanzasEditadas) {
        csvData.add(balanza.values.toList());
      }

      // Convertir a CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // Obtener directorio de descargas
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      // Crear nombre de archivo
      final fileName = 'SECA_${widget.servicioSeca.seca}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';

      // Guardar archivo
      final File file = File(filePath);
      await file.writeAsString(csv);

      // Abrir el archivo
      OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo exportado: $fileName'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'))
      );
    }
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
      body: ListView.builder(
        itemCount: balanzasEditadas.length,
        itemBuilder: (context, index) {
          final balanza = balanzasEditadas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(balanza['cod_metrica']?.toString() ?? 'Sin nombre'),
              subtitle: Text('Modelo: ${balanza['modelo']?.toString() ?? 'N/A'}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _mostrarDialogoEdicion(context, index, balanza),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoEdicion(BuildContext context, int index, Map<String, dynamic> balanza) {
    final Map<String, TextEditingController> controllers = {};

    // Crear controladores para cada campo
    balanza.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Editar Balanza',
            style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: controllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final Map<String, dynamic> nuevosDatos = {};
              controllers.forEach((key, controller) {
                nuevosDatos[key] = controller.text;
              });

              _editarBalanza(index, nuevosDatos);
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          )
        ],
      ),
    );
  }
}