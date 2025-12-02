import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../fin_servicios_controller.dart';

class ExportacionStep extends StatelessWidget {
  const ExportacionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FinServiciosController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardOpacity = isDarkMode ? 0.4 : 0.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30.0),
            _buildInfoSection(
              'FINALIZAR SERVICIO',
              'Al dar clic se finalizará el servicio de calibración y se exportarán los datos en un archivo CSV.',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t4.png',
              'FINALIZAR SERVICIO\nY EXPORTAR DATOS',
              () => _confirmarYExportar(context, controller),
              textColor,
              cardOpacity,
            ),
            const SizedBox(height: 40),
            _buildInfoSection(
              'SELECCIONAR OTRA BALANZA',
              'Al dar clic se volverá a la pantalla de identificación de balanza para seleccionar otra balanza.',
              textColor,
            ),
            _buildActionCard(
              'images/tarjetas/t7.png',
              'SELECCIONAR\nOTRA BALANZA',
              () => _confirmarSeleccionOtraBalanza(context, controller),
              textColor,
              cardOpacity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String description, Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: textColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionCard(
    String imagePath,
    String title,
    VoidCallback onTap,
    Color textColor,
    double opacity,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 300,
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.black.withOpacity(opacity),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 6.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarYExportar(
      BuildContext context, FinServiciosController controller) async {
    // Show dialog to get additional data
    final additionalData = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'DATOS ADICIONALES PARA EXPORTACIÓN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'EMP NB 23001',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: controller.selectedEmp23001,
                      items: ['Sí', 'No'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          controller.selectedEmp23001 = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.indicarController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Indicar (%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.factorSeguridadController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Factor Seguridad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Regla de Aceptación',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: controller.selectedReglaAceptacion,
                      items: ['Ninguna', 'Simple', 'Conservadora']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          controller.selectedReglaAceptacion = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46824B),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (additionalData == true) {
      final registros = await controller.prepareExportData();
      if (registros.isNotEmpty && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _ResumenExportacionScreen(
              cantidad: registros.length,
              seca: controller.secaValue,
              registros: registros,
              onExport: (registros) => controller.executeExport(registros),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmarSeleccionOtraBalanza(
      BuildContext context, FinServiciosController controller) async {
    final bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMAR ACCIÓN',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
          ),
          content:
              const Text('¿Está seguro que desea seleccionar otra balanza?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Sí, continuar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      await controller.confirmarSeleccionOtraBalanza();
    }
  }
}

class _ResumenExportacionScreen extends StatefulWidget {
  final int cantidad;
  final String seca;
  final List<Map<String, dynamic>> registros;
  final Future<void> Function(List<Map<String, dynamic>>) onExport;

  const _ResumenExportacionScreen({
    required this.cantidad,
    required this.seca,
    required this.registros,
    required this.onExport,
  });

  @override
  _ResumenExportacionScreenState createState() =>
      _ResumenExportacionScreenState();
}

class _ResumenExportacionScreenState extends State<_ResumenExportacionScreen> {
  late Future<Map<String, dynamic>> _resumenFuture;

  @override
  void initState() {
    super.initState();
    _resumenFuture = _generarResumen();
  }

  Future<Map<String, dynamic>> _generarResumen() async {
    // Contar balanzas únicas por cod_metrica
    final balanzasUnicas = <String, Map<String, dynamic>>{};
    int totalRegistros = widget.registros.length;

    for (final registro in widget.registros) {
      final codMetrica = registro['cod_metrica']?.toString() ?? 'N/A';
      final marca = registro['marca']?.toString() ?? 'N/A';
      final modelo = registro['modelo']?.toString() ?? 'N/A';

      if (!balanzasUnicas.containsKey(codMetrica)) {
        balanzasUnicas[codMetrica] = {
          'cod_metrica': codMetrica,
          'marca': marca,
          'modelo': modelo,
          'cantidad': 0,
        };
      }
      balanzasUnicas[codMetrica]?['cantidad'] =
          (balanzasUnicas[codMetrica]?['cantidad'] ?? 0) + 1;
    }

    return {
      'totalBalanzas': balanzasUnicas.length,
      'totalRegistros': totalRegistros,
      'balanzas': balanzasUnicas.values.toList(),
      'fecha': DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()),
      'seca': widget.seca,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'RESUMEN DE EXPORTACIÓN',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resumenFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resumen = snapshot.data!;
          final balanzas = resumen['balanzas'] as List<Map<String, dynamic>>;
          final totalBalanzas = resumen['totalBalanzas'] as int;
          final totalRegistros = resumen['totalRegistros'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de resumen general
                Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF46824B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESUMEN GENERAL',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResumenItem(
                          'SECA:',
                          resumen['seca'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Fecha/Hora:',
                          resumen['fecha'],
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Balanzas calibradas:',
                          totalBalanzas.toString(),
                          Colors.white,
                        ),
                        _buildResumenItem(
                          'Total de registros:',
                          totalRegistros.toString(),
                          Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DETALLE DE BALANZAS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: balanzas.length,
                  itemBuilder: (context, index) {
                    final balanza = balanzas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balanza ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            _buildDetalleItem(
                                'Código:', balanza['cod_metrica']),
                            _buildDetalleItem('Marca:', balanza['marca']),
                            _buildDetalleItem('Modelo:', balanza['modelo']),
                            _buildDetalleItem(
                                'Registros:', balanza['cantidad'].toString()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => widget.onExport(widget.registros),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF46824B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR Y EXPORTAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
