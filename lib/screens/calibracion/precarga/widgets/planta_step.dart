// widgets/planta_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class PlantaStep extends StatefulWidget {
  const PlantaStep({Key? key}) : super(key: key);

  @override
  State<PlantaStep> createState() => _PlantaStepState();
}

class _PlantaStepState extends State<PlantaStep> {
  final TextEditingController _plantaDirController = TextEditingController();
  final TextEditingController _plantaDepController = TextEditingController();
  final TextEditingController _codigoPlantaController = TextEditingController();

  @override
  void dispose() {
    _plantaDirController.dispose();
    _plantaDepController.dispose();
    _codigoPlantaController.dispose();
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
              'SELECCIÓN DE PLANTA',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Información del cliente seleccionado
            _buildClienteInfo(controller),

            const SizedBox(height: 30),

            // Selección de planta según el tipo de clientea
            if (controller.isNewClient)
              _buildNewPlantaSection(controller)
            else
              _buildExistingPlantaSection(controller),

            const SizedBox(height: 20),

            // Información de la planta seleccionada
            if (controller.selectedPlantaCodigo != null)
              _buildSelectedPlantaInfo(controller),
          ],
        );
      },
    );
  }

  Widget _buildClienteInfo(PrecargaController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
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
                  'Cliente Seleccionado:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  controller.selectedClienteName ?? 'No especificado',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                if (controller.isNewClient)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NUEVO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3);
  }

  Widget _buildNewPlantaSection(PrecargaController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATOS DE LA NUEVA PLANTA',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextField(
          controller: _plantaDirController,
          decoration: InputDecoration(
            labelText: 'Dirección de la Planta *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          onChanged: (value) => _updatePlantaData(controller),
        ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 16),

        TextField(
          controller: _plantaDepController,
          decoration: InputDecoration(
            labelText: 'Departamento de la Planta *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.map),
          ),
          onChanged: (value) => _updatePlantaData(controller),
        ).animate(delay: 500.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 16),

        TextField(
          controller: _codigoPlantaController,
          decoration: InputDecoration(
            labelText: 'Código de la Planta *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.code),
            helperText: 'Ej: 1234, ABCD',
          ),
          onChanged: (value) => _updatePlantaData(controller),
        ).animate(delay: 600.ms).fadeIn().slideX(begin: -0.3),

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
                  'El código de planta se utilizará para generar el código SECA automáticamente.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 700.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildExistingPlantaSection(PrecargaController controller) {
    if (controller.plantas == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.plantas!.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[600],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay plantas registradas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este cliente no tiene plantas registradas en el sistema.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLANTAS DISPONIBLES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: controller.plantas!.map((planta) {
              final uniqueKey = planta['unique_key'];
              final isSelected = controller.selectedPlantaKey == uniqueKey;

              return Container(
                margin: const EdgeInsets.all(4),
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
                    planta['planta']?.toString() ?? 'Planta sin nombre',
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (planta['dir'] != null)
                        Text(
                          'Dirección: ${planta['dir']}',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      if (planta['dep'] != null)
                        Text(
                          'Departamento: ${planta['dep']}',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      if (planta['codigo_planta'] != null)
                        Text(
                          'Código: ${planta['codigo_planta']}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => controller.selectPlanta(uniqueKey),
                ),
              );
            }).toList(),
          ),
        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildSelectedPlantaInfo(PrecargaController controller) {
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
                      'Planta Seleccionada',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Código: ${controller.selectedPlantaCodigo}',
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

          const SizedBox(height: 12),

          if (controller.selectedPlantaDir != null) ...[
            _buildInfoRow('Dirección', controller.selectedPlantaDir!),
            const SizedBox(height: 8),
          ],

          if (controller.selectedPlantaDep != null) ...[
            _buildInfoRow('Departamento', controller.selectedPlantaDep!),
            const SizedBox(height: 8),
          ],

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Código SECA se generará automáticamente usando: ${controller.selectedPlantaCodigo}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            label == 'Dirección' ? Icons.location_on : Icons.map,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePlantaData(PrecargaController controller) {
    controller.setPlantaManualData(
      _plantaDirController.text,
      _plantaDepController.text,
      _codigoPlantaController.text,
    );
  }
}