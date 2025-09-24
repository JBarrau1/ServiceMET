import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class DetallesSecaScreen extends StatefulWidget {
  final ServicioSeca servicioSeca;

  const DetallesSecaScreen({super.key, required this.servicioSeca});

  @override
  State<DetallesSecaScreen> createState() => _DetallesSecaScreenState();
}

class _DetallesSecaScreenState extends State<DetallesSecaScreen> {
  List<Map<String, dynamic>> registrosEditados = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con los datos originales
    registrosEditados = List.from(widget.servicioSeca.balanzas);
  }

  void _editarRegistro(int index, Map<String, dynamic> nuevosDatos) {
    setState(() {
      registrosEditados[index] = {...registrosEditados[index], ...nuevosDatos};
    });
  }

  String _getTituloRegistro(Map<String, dynamic> registro) {
    if (widget.servicioSeca.tipoServicio == 'calibracion') {
      return registro['cod_metrica']?.toString() ?? 'Sin código';
    } else {
      // Para soporte técnico
      final tabla = registro['tabla_origen']?.toString() ?? '';
      if (tabla == 'inf_cliente_balanza') {
        return registro['otst']?.toString() ?? 'Sin OTST';
      } else {
        return registro['cod_metrica']?.toString() ?? 'Sin código';
      }
    }
  }

  String _getSubtituloRegistro(Map<String, dynamic> registro) {
    if (widget.servicioSeca.tipoServicio == 'calibracion') {
      return 'Modelo: ${registro['modelo']?.toString() ?? 'N/A'}';
    } else {
      // Para soporte técnico
      final tabla = registro['tabla_origen']?.toString() ?? '';
      final tipoServicio = registro['tipo_servicio']?.toString() ?? 'N/A';
      return 'Tabla: ${tabla.replaceAll('_', ' ').toUpperCase()} | Tipo: $tipoServicio';
    }
  }

  Color _getColorPorTipo() {
    return widget.servicioSeca.tipoServicio == 'calibracion'
        ? const Color(0xFF667EEA)
        : const Color(0xFF11998E);
  }

  IconData _getIconoPorTipo() {
    return widget.servicioSeca.tipoServicio == 'calibracion'
        ? FontAwesomeIcons.scaleBalanced
        : FontAwesomeIcons.screwdriverWrench;
  }

  Future<void> _exportarCSV() async {
    try {
      final List<List<dynamic>> csvData = [];

      // Encabezados
      if (registrosEditados.isNotEmpty) {
        csvData.add(registrosEditados.first.keys.toList());
      }

      // Datos
      for (var registro in registrosEditados) {
        csvData.add(registro.values.toList());
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
      final tipoAbreviado = widget.servicioSeca.tipoServicio == 'calibracion' ? 'CAL' : 'SOP';
      final fileName = '${tipoAbreviado}_${widget.servicioSeca.seca.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';

      // Guardar archivo
      final File file = File(filePath);
      await file.writeAsString(csv);

      // Abrir el archivo
      OpenFilex.open(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo exportado: $fileName'),
            backgroundColor: _getColorPorTipo(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'DETALLES',
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.7)
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.download, size: 18),
            onPressed: _exportarCSV,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header con información del servicio
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.servicioSeca.tipoServicio == 'calibracion'
                      ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                      : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getColorPorTipo().withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getIconoPorTipo(),
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.servicioSeca.seca,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.servicioSeca.tipoServicio == 'calibracion'
                        ? 'Servicio de Calibración'
                        : 'Servicio de Soporte Técnico',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${registrosEditados.length} ${widget.servicioSeca.tipoServicio == 'calibracion' ? 'balanza' : 'registro'}${registrosEditados.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de registros
            Expanded(
              child: registrosEditados.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.exclamationTriangle,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay registros disponibles',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: registrosEditados.length,
                itemBuilder: (context, index) {
                  final registro = registrosEditados[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getColorPorTipo().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconoPorTipo(),
                          color: _getColorPorTipo(),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _getTituloRegistro(registro),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                      subtitle: Text(
                        _getSubtituloRegistro(registro),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          FontAwesomeIcons.penToSquare,
                          color: _getColorPorTipo(),
                          size: 18,
                        ),
                        onPressed: () => _mostrarDialogoEdicion(context, index, registro),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportarCSV,
        backgroundColor: _getColorPorTipo(),
        icon: const Icon(FontAwesomeIcons.download, color: Colors.white),
        label: Text(
          'Exportar CSV',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEdicion(BuildContext context, int index, Map<String, dynamic> registro) {
    final Map<String, TextEditingController> controllers = {};

    // Crear controladores para cada campo
    registro.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconoPorTipo(),
              color: _getColorPorTipo(),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Editar ${widget.servicioSeca.tipoServicio == 'calibracion' ? 'Balanza' : 'Registro'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key.replaceAll('_', ' ').toUpperCase(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _getColorPorTipo(), width: 2),
                      ),
                    ),
                    maxLines: entry.key.contains('comentario') ||
                        entry.key.contains('reporte') ||
                        entry.key.contains('evaluacion') ? 3 : 1,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorPorTipo(),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final Map<String, dynamic> nuevosDatos = {};
              controllers.forEach((key, controller) {
                nuevosDatos[key] = controller.text;
              });

              _editarRegistro(index, nuevosDatos);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );

    // Disponer controladores al cerrar el diálogo
    controllers.values.forEach((controller) => controller.dispose());
  }
}