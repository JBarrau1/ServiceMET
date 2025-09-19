// widgets/cliente_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class ClienteStep extends StatefulWidget {
  const ClienteStep({Key? key}) : super(key: key);

  @override
  State<ClienteStep> createState() => _ClienteStepState();
}

class _ClienteStepState extends State<ClienteStep> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreComercialController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _nombreComercialController.dispose();
    _razonSocialController.dispose();
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
              'SELECCIÓN DE CLIENTE',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Botones de selección
            _buildClientTypeButtons(controller),

            const SizedBox(height: 30),

            // Contenido según el tipo seleccionado
            if (!controller.isNewClient)
              _buildExistingClientSection(controller)
            else
              _buildNewClientSection(controller),

            const SizedBox(height: 20),

            // Información del cliente seleccionado
            if (controller.selectedClienteName != null)
              _buildSelectedClientInfo(controller),
          ],
        );
      },
    );
  }

  Widget _buildClientTypeButtons(PrecargaController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                controller.clearClientSelection();
                _searchController.clear();
              });
              controller.fetchClientes();
            },
            icon: const Icon(Icons.search),
            label: const Text('Cliente Existente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: !controller.isNewClient
                  ? const Color(0xFF007195)
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                controller.clearClientSelection();
                _nombreComercialController.clear();
                _razonSocialController.clear();
              });
              controller.selectNewClient('', '');
            },
            icon: const Icon(Icons.add_business),
            label: const Text('Cliente Nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isNewClient
                  ? const Color(0xFF3e7732)
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildExistingClientSection(PrecargaController controller) {
    return Column(
      children: [
        // Campo de búsqueda
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar cliente',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                controller.filterClientes('');
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => controller.filterClientes(value),
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        // Lista de clientes
        if (controller.filteredClientes != null)
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: controller.filteredClientes!.isEmpty
                ? const Center(
              child: Text(
                'No se encontraron clientes',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: controller.filteredClientes!.length,
              itemBuilder: (context, index) {
                final cliente = controller.filteredClientes![index];
                final isSelected = controller.selectedClienteId ==
                    cliente['cliente_id']?.toString();

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                        : null,
                  ),
                  child: ListTile(
                    title: Text(
                      cliente['cliente'] ?? 'Cliente desconocido',
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      cliente['razonsocial'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => controller.selectClientFromList(cliente),
                  ),
                );
              },
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildNewClientSection(PrecargaController controller) {
    return Column(
      children: [
        TextField(
          controller: _nombreComercialController,
          decoration: InputDecoration(
            labelText: 'Nombre Comercial *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
          onChanged: (value) {
            controller.selectNewClient(value, _razonSocialController.text);
          },
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 16),

        TextField(
          controller: _razonSocialController,
          decoration: InputDecoration(
            labelText: 'Razón Social',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.assignment),
          ),
          onChanged: (value) {
            controller.selectNewClient(_nombreComercialController.text, value);
          },
        ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Al crear un cliente nuevo, no podrá ver la lista de balanzas registradas.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 500.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildTermohigrometroSelection(PrecargaController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Text(
            'SELECCIÓN INICIAL DE TERMOHIGRÓMETROS',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showTermohigrometrosSelection(controller),
              icon: const Icon(Icons.device_thermostat),
              label: Text(
                'Seleccionar Termohigrómetros (${controller.selectedTermohigrometros.length}/2)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF337743),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3);
  }

  void _showTermohigrometrosSelection(PrecargaController controller) {
    final termohigrometros = controller.equipos.where((equipo) {
      final instrumento = equipo['instrumento']?.toString() ?? '';
      return instrumento.contains('Termohigrómetro') ||
          instrumento.contains('Termohigrobarómetro');
    }).toList();

    // Obtener la versión más reciente de cada termohigrómetro
    final Map<String, Map<String, dynamic>> uniqueTermos = {};
    for (var termo in termohigrometros) {
      final codInstrumento = termo['cod_instrumento'].toString();
      final certFecha = DateTime.parse(termo['cert_fecha']);

      if (!uniqueTermos.containsKey(codInstrumento) ||
          certFecha.isAfter(DateTime.parse(uniqueTermos[codInstrumento]!['cert_fecha']))) {
        uniqueTermos[codInstrumento] = termo;
      }
    }

    final termosUnicos = uniqueTermos.values.toList()
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                              'SELECCIONAR TERMOHIGRÓMETROS',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seleccione los termohigrómetros para el servicio (1-2)',
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
                          itemCount: termosUnicos.length,
                          itemBuilder: (context, index) {
                            final termo = termosUnicos[index];
                            final isSelected = controller.selectedTermohigrometros.any((e) =>
                            e['cod_instrumento'] == termo['cod_instrumento']);

                            final certFecha = DateTime.parse(termo['cert_fecha']);
                            final difference = DateTime.now().difference(certFecha).inDays;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: CheckboxListTile(
                                title: Text(
                                  '${termo['cod_instrumento']}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${termo['instrumento']}'),
                                    Text(
                                      'Certificado: ${termo['cert_fecha']} ($difference días)',
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
                                      'Ente: ${termo['ente_calibrador']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (controller.selectedTermohigrometros.length < 2) {
                                        controller.addEquipo(termo, 'termohigrometro', '1');
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Máximo 2 termohigrómetros permitidos')),
                                        );
                                      }
                                    } else {
                                      controller.removeEquipo(termo['cod_instrumento'], 'termohigrometro');
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

  Widget _buildSelectedClientInfo(PrecargaController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[50]!,
            Colors.green[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente Seleccionado',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      controller.selectedClienteName!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (controller.selectedClienteRazonSocial != null &&
              controller.selectedClienteRazonSocial!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Razón Social: ${controller.selectedClienteRazonSocial}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (controller.isNewClient) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.new_releases,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cliente Nuevo - Se registrará en el sistema',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Agregar después de _buildSelectedClientInfo()
          if (controller.selectedClienteName != null && controller.equipos.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 30),
                _buildTermohigrometroSelection(controller),
              ],
            ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3);
  }
}