// widgets/equipos_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class EquiposStep extends StatefulWidget {
  const EquiposStep({super.key});

  @override
  State<EquiposStep> createState() => _EquiposStepState();
}

class _EquiposStepState extends State<EquiposStep> {
  final List<TextEditingController> _cantidadControllers = [];

  @override
  void dispose() {
    for (var controller in _cantidadControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
            Text(
              'SELECCIÓN DE EQUIPOS',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Botones de selección de equipos
            _buildEquiposSelectionButtons(controller),

            const SizedBox(height: 30),

            // Lista de equipos seleccionados
            if (controller.getAllSelectedEquipos().isNotEmpty)
              _buildSelectedEquiposList(controller),

            const SizedBox(height: 20),

            // Resumen de equipos
            _buildEquiposResumen(controller),
          ],
        );
      },
    );
  }

  Widget _buildEquiposSelectionButtons(PrecargaController controller) {
    return Column(
      children: [
        // Pesas Patrón
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPesasPatronSelection(controller),
            icon: const Icon(Icons.scale),
            label: Text(
              'Seleccionar Pesas Patrón (${controller.selectedEquipos.length}/5)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF773243),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.3),
      ],
    );
  }

  Widget _buildSelectedEquiposList(PrecargaController controller) {
    final allEquipos = controller.getAllSelectedEquipos();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EQUIPOS SELECCIONADOS',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),
          ...allEquipos.asMap().entries.map((entry) {
            final index = entry.key;
            final equipo = entry.value;

            // Asegurar que hay suficientes controladores
            while (_cantidadControllers.length <= index) {
              _cantidadControllers
                  .add(TextEditingController(text: equipo['cantidad'] ?? '1'));
            }

            return _buildEquipoCard(equipo, index, controller);
          }),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildEquipoCard(
      Map<String, dynamic> equipo, int index, PrecargaController controller) {
    final certFecha = DateTime.parse(equipo['cert_fecha']);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(certFecha).inDays;
    final tipo = equipo['tipo'] as String;

    Color getStatusColor() {
      if (difference > 365) return Colors.red;
      if (difference > 300) return Colors.orange;
      return Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipo == 'pesa' ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tipo == 'pesa' ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del equipo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipo == 'pesa' ? Colors.blue[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tipo == 'pesa' ? Icons.scale : Icons.device_thermostat,
                  color: tipo == 'pesa' ? Colors.blue[700] : Colors.green[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equipo ${index + 1}: ${equipo['cod_instrumento']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tipo == 'pesa'
                            ? Colors.blue[800]
                            : Colors.green[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tipo == 'pesa'
                            ? Colors.blue[200]
                            : Colors.green[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tipo == 'pesa' ? 'PESA PATRÓN' : 'TERMOHIGRÓMETRO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tipo == 'pesa'
                              ? Colors.blue[800]
                              : Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  controller.removeEquipo(equipo['cod_instrumento'], tipo);
                  setState(() {
                    _cantidadControllers.removeAt(index);
                  });
                },
                icon: const Icon(Icons.remove_circle, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información del equipo
          _buildInfoRow('Tipo', equipo['instrumento']),
          _buildInfoRow('Fecha Certificación', equipo['cert_fecha']),
          _buildInfoRow('Ente Calibrador', equipo['ente_calibrador']),

          // Estado de certificación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Estado: $difference días desde certificación',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campo de cantidad
          TextField(
            controller: _cantidadControllers[index],
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.updateEquipoCantidad(
                equipo['cod_instrumento'],
                tipo,
                value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquiposResumen(PrecargaController controller) {
    final totalEquipos = controller.getAllSelectedEquipos().length;
    final pesas = controller.selectedEquipos.length;
    final termohigrometros = controller.selectedTermohigrometros.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: totalEquipos > 0 ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: totalEquipos > 0 ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                totalEquipos > 0 ? Icons.check_circle : Icons.warning,
                color:
                    totalEquipos > 0 ? Colors.green[600] : Colors.orange[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  totalEquipos > 0
                      ? 'Equipos Listos para Calibración'
                      : 'Seleccione al menos un equipo',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: totalEquipos > 0
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          if (totalEquipos > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem(
                    'Pesas Patrón', pesas.toString(), Icons.scale),
                _buildResumenItem('Termohigrómetros',
                    termohigrometros.toString(), Icons.device_thermostat),
                _buildResumenItem(
                    'Total', totalEquipos.toString(), Icons.construction),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildResumenItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.green[600],
          ),
        ),
      ],
    );
  }

  void _showPesasPatronSelection(PrecargaController controller) {
    // Filtrar solo pesas patrón
    final pesas = controller.equipos.where((equipo) {
      final instrumento = equipo['instrumento']?.toString() ?? '';
      return !instrumento.contains('Termohigrómetro') &&
          !instrumento.contains('Termohigrobarómetro');
    }).toList();

    // Obtener la versión más reciente de cada pesa
    final Map<String, Map<String, dynamic>> uniquePesas = {};
    for (var pesa in pesas) {
      final codInstrumento = pesa['cod_instrumento'].toString();
      final certFecha = DateTime.parse(pesa['cert_fecha']);

      if (!uniquePesas.containsKey(codInstrumento) ||
          certFecha.isAfter(
              DateTime.parse(uniquePesas[codInstrumento]!['cert_fecha']))) {
        uniquePesas[codInstrumento] = pesa;
      }
    }

    final pesasUnicas = uniquePesas.values.toList()
      ..sort((a, b) => (a['cod_instrumento']?.toString() ?? '')
          .compareTo(b['cod_instrumento']?.toString() ?? ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'SELECCIONAR PESAS PATRÓN',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seleccione las pesas patrón para el servicio (máximo 5)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: pesasUnicas.length,
                          itemBuilder: (context, index) {
                            final pesa = pesasUnicas[index];
                            final isSelected = controller.selectedEquipos.any(
                                (e) =>
                                    e['cod_instrumento'] ==
                                    pesa['cod_instrumento']);

                            final certFecha =
                                DateTime.parse(pesa['cert_fecha']);
                            final difference =
                                DateTime.now().difference(certFecha).inDays;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: CheckboxListTile(
                                title: Text(
                                  '${pesa['cod_instrumento']}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${pesa['instrumento']}'),
                                    Text(
                                      'Certificado: ${pesa['cert_fecha']} ($difference días)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: difference > 365
                                            ? Colors.red
                                            : difference > 300
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'Ente: ${pesa['ente_calibrador']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (controller.selectedEquipos.length <
                                          5) {
                                        final cantidad =
                                            !pesa['cod_instrumento']
                                                    .toString()
                                                    .startsWith('M')
                                                ? '1'
                                                : '';
                                        controller.addEquipo(
                                            pesa, 'pesa', cantidad);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Máximo 5 pesas patrón permitidas')),
                                        );
                                      }
                                    } else {
                                      controller.removeEquipo(
                                          pesa['cod_instrumento'], 'pesa');
                                    }
                                  });
                                  this.setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('CONFIRMAR SELECCIÓN'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
