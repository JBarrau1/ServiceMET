// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/servicio_model.dart';
import '../utils/pdf_generator.dart';

class DetallesOtstScreen extends StatefulWidget {
  final ServicioOtst servicioOtst;

  const DetallesOtstScreen({super.key, required this.servicioOtst});

  @override
  State<DetallesOtstScreen> createState() => _DetallesOtstScreenState();
}

class _DetallesOtstScreenState extends State<DetallesOtstScreen> {
  List<Map<String, dynamic>> serviciosEditados = [];
  int? servicioExpandido;

  @override
  void initState() {
    super.initState();
    serviciosEditados = List.from(widget.servicioOtst.servicios);
  }

  // Filtrar solo campos con datos válidos
  Map<String, dynamic> _obtenerCamposConDatos(Map<String, dynamic> servicio) {
    final Map<String, dynamic> camposValidos = {};

    servicio.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != '0' &&
          value.toString() != 'null' &&
          value.toString().trim().isNotEmpty) {
        camposValidos[key] = value;
      }
    });

    return camposValidos;
  }

  // Formatear nombres de campos
  String _formatearNombreCampo(String campo) {
    return campo
        .replaceAll('_', ' ')
        .split(' ')
        .map((palabra) => palabra.isEmpty
            ? ''
            : palabra[0].toUpperCase() + palabra.substring(1).toLowerCase())
        .join(' ');
  }

  // Obtener tipo de servicio para mostrar
  String _obtenerTipoServicio(Map<String, dynamic> servicio) {
    return servicio['tipo_servicio']?.toString() ?? 'Soporte Técnico';
  }

  // Obtener icono según tipo de servicio
  IconData _obtenerIconoTipoServicio(String tipoServicio) {
    switch (tipoServicio.toLowerCase()) {
      case 'ajustes':
        return FontAwesomeIcons.screwdriverWrench;
      case 'diagnóstico':
        return FontAwesomeIcons.stethoscope;
      case 'instalación':
        return FontAwesomeIcons.toolbox;
      case 'mantenimiento correctivo':
        return FontAwesomeIcons.hammer;
      case 'mantenimiento preventivo avanzado stac':
      case 'mantenimiento preventivo avanzado stil':
      case 'mantenimiento preventivo regular stac':
      case 'mantenimiento preventivo regular stil':
        return FontAwesomeIcons.screwdriver;
      case 'relevamiento':
        return FontAwesomeIcons.clipboardList;
      case 'verificaciones':
        return FontAwesomeIcons.checkDouble;
      default:
        return FontAwesomeIcons.gears;
    }
  }

  // Obtener color según tipo de servicio
  Color _obtenerColorTipoServicio(String tipoServicio) {
    switch (tipoServicio.toLowerCase()) {
      case 'ajustes':
        return const Color(0xFF4CAF50);
      case 'diagnóstico':
        return const Color(0xFF2196F3);
      case 'instalación':
        return const Color(0xFFFF9800);
      case 'mantenimiento correctivo':
        return const Color(0xFFF44336);
      case 'mantenimiento preventivo avanzado stac':
        return const Color(0xFF9C27B0);
      case 'mantenimiento preventivo avanzado stil':
        return const Color(0xFF673AB7);
      case 'mantenimiento preventivo regular stac':
        return const Color(0xFF3F51B5);
      case 'mantenimiento preventivo regular stil':
        return const Color(0xFF2196F3);
      case 'relevamiento':
        return const Color(0xFF607D8B);
      case 'verificaciones':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF667EEA);
    }
  }

  void _editarServicio(int index, Map<String, dynamic> nuevosDatos) {
    setState(() {
      serviciosEditados[index] = {...serviciosEditados[index], ...nuevosDatos};
    });
  }

  Future<void> _exportarCSV() async {
    try {
      final List<List<dynamic>> csvData = [];

      if (serviciosEditados.isNotEmpty) {
        csvData.add(serviciosEditados.first.keys.toList());
      }

      for (var servicio in serviciosEditados) {
        csvData.add(servicio.values.toList());
      }

      // Generar CSV
      final csv =
          const ListToCsvConverter(fieldDelimiter: ';').convert(csvData);

      // Codificar a bytes UTF-8 para evitar problemas de caracteres
      final List<int> csvBytes = utf8.encode(csv);

      final fileName =
          'OTST_${widget.servicioOtst.otst}_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Seleccionar directorio de destino
      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccione carpeta para guardar el respaldo',
      );

      if (directoryPath == null) {
        // Usuario canceló
        return;
      }

      final File file = File('$directoryPath/$fileName');
      await file.writeAsBytes(csvBytes);

      // Opcional: Abrir el archivo generado
      OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.circleCheck,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Archivo guardado en: ${file.path}')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.circleXmark,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al exportar: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _exportarPDF() async {
    try {
      final pdfBytes =
          await PdfGenerator.generateSoportePdf(widget.servicioOtst);

      final fileName =
          'Resumen_Soporte_OTST_${widget.servicioOtst.otst}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Seleccionar directorio de destino
      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccione carpeta para guardar el PDF',
      );

      if (directoryPath == null) {
        // Usuario canceló
        return;
      }

      final File file = File('$directoryPath/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Abrir el archivo generado
      OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.circleCheck,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('PDF guardado en: ${file.path}')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.circleXmark,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al exportar PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildServicioCard(
      BuildContext context, int index, Map<String, dynamic> servicio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camposConDatos = _obtenerCamposConDatos(servicio);
    final isExpanded = servicioExpandido == index;
    final tipoServicio = _obtenerTipoServicio(servicio);
    final iconoServicio = _obtenerIconoTipoServicio(tipoServicio);
    final colorServicio = _obtenerColorTipoServicio(tipoServicio);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    servicioExpandido = isExpanded ? null : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorServicio,
                              _darkenColor(colorServicio, 0.2)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: colorServicio.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          iconoServicio,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicio['cod_metrica']?.toString() ??
                                  servicio['modelo_balanza']?.toString() ??
                                  servicio['equipo']?.toString() ??
                                  'Servicio ${index + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorServicio.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tipoServicio,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorServicio,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${camposConDatos.length} campos',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorServicio.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isExpanded
                              ? FontAwesomeIcons.chevronUp
                              : FontAwesomeIcons.chevronDown,
                          size: 16,
                          color: colorServicio,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido expandible
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              isDark ? Colors.white24 : Colors.black12,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Información del servicio
                      _buildInfoServicio(
                          context, servicio, isDark, colorServicio),

                      const SizedBox(height: 16),

                      // Campos de datos
                      ...camposConDatos.entries.map((entry) {
                        // Excluir campos ya mostrados en la información del servicio
                        if ([
                          'tipo_servicio',
                          'cod_metrica',
                          'modelo',
                          'equipo',
                          'otst'
                        ].contains(entry.key)) {
                          return const SizedBox.shrink();
                        }
                        return _buildDataField(
                          context,
                          _formatearNombreCampo(entry.key),
                          entry.value.toString(),
                          isDark,
                        );
                      }),

                      const SizedBox(height: 16),

                      // Botón de editar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _mostrarDialogoEdicion(context, index, servicio),
                          icon: const Icon(FontAwesomeIcons.penToSquare,
                              size: 16),
                          label: const Text('Editar datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorServicio,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoServicio(BuildContext context, Map<String, dynamic> servicio,
      bool isDark, Color color) {
    final tipoServicio = _obtenerTipoServicio(servicio);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _obtenerIconoTipoServicio(tipoServicio),
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tipoServicio,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (servicio['cod_metrica'] != null)
            _buildInfoRow(
                'Código Métrica', servicio['cod_metrica'].toString(), isDark),
          if (servicio['modelo_balanza'] != null)
            _buildInfoRow(
                'Modelo', servicio['modelo_balanza'].toString(), isDark),
          if (servicio['equipo'] != null)
            _buildInfoRow('Equipo', servicio['equipo'].toString(), isDark),
          if (servicio['otst'] != null)
            _buildInfoRow('OTST', servicio['otst'].toString(), isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataField(
      BuildContext context, String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _darkenColor(Color color, double factor) {
    assert(factor >= 0 && factor <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: AppBar(
              toolbarHeight: 70,
              leading: IconButton(
                icon: Icon(
                  FontAwesomeIcons.arrowLeft,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                children: [
                  Text(
                    'OTST ${widget.servicioOtst.otst}',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    '${widget.servicioOtst.cantidadServicios} servicio${widget.servicioOtst.cantidadServicios != 1 ? 's' : ''} técnico${widget.servicioOtst.cantidadServicios != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.filePdf,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                  onPressed: _exportarPDF,
                  tooltip: 'Exportar PDF',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.download,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                  ),
                  onPressed: _exportarCSV,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: serviciosEditados.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.boxOpen,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay servicios técnicos registrados',
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
                padding: const EdgeInsets.all(20),
                itemCount: serviciosEditados.length,
                itemBuilder: (context, index) {
                  return _buildServicioCard(
                      context, index, serviciosEditados[index]);
                },
              ),
      ),
    );
  }

  void _mostrarDialogoEdicion(
      BuildContext context, int index, Map<String, dynamic> servicio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camposConDatos = _obtenerCamposConDatos(servicio);
    final Map<String, TextEditingController> controllers = {};

    camposConDatos.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C3E50) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FontAwesomeIcons.penToSquare,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Editar Servicio Técnico',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: entry.value,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: _formatearNombreCampo(entry.key),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                    ),
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
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final Map<String, dynamic> nuevosDatos = {};
              controllers.forEach((key, controller) {
                nuevosDatos[key] = controller.text;
              });

              _editarServicio(index, nuevosDatos);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(FontAwesomeIcons.circleCheck,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Text('Cambios guardados correctamente'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Guardar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
