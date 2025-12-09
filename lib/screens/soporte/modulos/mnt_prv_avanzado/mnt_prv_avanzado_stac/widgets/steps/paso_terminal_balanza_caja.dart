import 'package:flutter/material.dart';
import '../../controllers/mnt_prv_avanzado_stac_controller.dart';
import '../../models/mnt_prv_avanzado_stac_model.dart';
import '../campo_inspeccion_widget.dart';

// PASO 2: TERMINAL DE PESAJE

class PasoTerminal extends StatefulWidget {
  final MntPrvAvanzadoStacModel model;
  final MntPrvAvanzadoStacController controller;
  final VoidCallback onChanged;

  const PasoTerminal({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<PasoTerminal> createState() => _PasoTerminalState();
}

class _PasoTerminalState extends State<PasoTerminal> {
  bool _isAllGood = false;

  @override
  Widget build(BuildContext context) {
    final campos = [
      'Carcasa',
      'Teclado Fisico',
      'Display Fisico',
      'Fuente de poder',
      'Bateria operacional',
      'Bracket',
      'Teclado Operativo',
      'Display Operativo',
      'Contector de celda',
      'Bateria de memoria',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            title: 'TERMINAL DE PESAJE',
            subtitle: 'Inspeccione el estado físico y operacional del terminal',
            icon: Icons.computer_outlined,
            color: Colors.purple,
          ),
          _buildAllGoodCheckbox(campos),
          const SizedBox(height: 24),
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllGoodCheckbox(List<String> campos) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isAllGood
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAllGood
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Marcar todo como "Buen Estado"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isAllGood
              ? 'Todos los campos están en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos',
          style: TextStyle(
            fontSize: 12,
            color: _isAllGood ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        value: _isAllGood,
        onChanged: (bool? value) {
          _toggleAllGood(value ?? false, campos);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleAllGood(bool isGood, List<String> campos) {
    setState(() {
      _isAllGood = isGood;

      if (isGood) {
        for (final fieldName in campos) {
          final campo = widget.model.camposEstado[fieldName];
          if (campo != null) {
            campo.initialValue = '1 Bueno';
            campo.comentario = 'En buen estado';
            campo.solutionValue = 'No aplica';
          }
        }
        widget.onChanged();
      }
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PASO 3: ESTADO DE BALANZA

class PasoBalanza extends StatefulWidget {
  final MntPrvAvanzadoStacModel model;
  final MntPrvAvanzadoStacController controller;
  final VoidCallback onChanged;

  const PasoBalanza({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<PasoBalanza> createState() => _PasoBalanzaState();
}

class _PasoBalanzaState extends State<PasoBalanza> {
  bool _isAllGood = false;

  @override
  Widget build(BuildContext context) {
    final campos = [
      'Limpieza general',
      'Golpes al terminal',
      'Nivelacion',
      'Limpieza receptor',
      'Golpes al receptor de carga',
      'Encendido',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            title: 'ESTADO GENERAL DE LA BALANZA',
            subtitle: 'Inspeccione el estado general del instrumento',
            icon: Icons.balance_outlined,
            color: Colors.teal,
          ),
          _buildAllGoodCheckbox(campos),
          const SizedBox(height: 24),
          ...campos.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllGoodCheckbox(List<String> campos) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isAllGood
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAllGood
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Marcar todo como "Buen Estado"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isAllGood
              ? 'Todos los campos están en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos',
          style: TextStyle(
            fontSize: 12,
            color: _isAllGood ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        value: _isAllGood,
        onChanged: (bool? value) {
          _toggleAllGood(value ?? false, campos);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleAllGood(bool isGood, List<String> campos) {
    setState(() {
      _isAllGood = isGood;

      if (isGood) {
        for (final fieldName in campos) {
          final campo = widget.model.camposEstado[fieldName];
          if (campo != null) {
            campo.initialValue = '1 Bueno';
            campo.comentario = 'En buen estado';
            campo.solutionValue = 'No aplica';
          }
        }
        widget.onChanged();
      }
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PASO 4: CAJA SUMADORA

class PasoCajaSumadora extends StatefulWidget {
  final MntPrvAvanzadoStacModel model;
  final MntPrvAvanzadoStacController controller;
  final VoidCallback onChanged;

  const PasoCajaSumadora({
    super.key,
    required this.model,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<PasoCajaSumadora> createState() => _PasoCajaSumadoraState();
}

class _PasoCajaSumadoraState extends State<PasoCajaSumadora> {
  bool _isAllGood = false;

  @override
  Widget build(BuildContext context) {
    final camposPlataforma = [
      'Limitador de movimiento',
      'Suspensión',
      'Limitador de carga',
      'Celda de carga',
    ];

    final camposCajaSumadora = [
      'Tapa de caja sumadora',
      'Humedad Interna',
      'Estado de prensacables',
      'Estado de borneas',
    ];

    final allCampos = [...camposPlataforma, ...camposCajaSumadora];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllGoodCheckbox(allCampos),
          const SizedBox(height: 16),
          _buildHeader(
            context,
            title: 'BALANZA | PLATAFORMA',
            subtitle: 'Inspeccione los componentes de la plataforma',
            icon: Icons.square_outlined,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          ...camposPlataforma.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),
          const SizedBox(height: 32),
          _buildHeader(
            context,
            title: 'CAJA SUMADORA',
            subtitle: 'Inspeccione el estado de la caja sumadora',
            icon: Icons.electrical_services_outlined,
            color: Colors.amber[700]!,
          ),
          const SizedBox(height: 16),
          ...camposCajaSumadora.map((campo) {
            return CampoInspeccionWidget(
              label: campo,
              campo: widget.model.camposEstado[campo]!,
              controller: widget.controller,
              onChanged: widget.onChanged,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllGoodCheckbox(List<String> campos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isAllGood
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAllGood
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Marcar todo como "Buen Estado"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isAllGood
              ? 'Todos los campos están en "1 Bueno" con comentario "En buen estado"'
              : 'Active esta opción para aplicar "Buen Estado" a todos los campos',
          style: TextStyle(
            fontSize: 12,
            color: _isAllGood ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        value: _isAllGood,
        onChanged: (bool? value) {
          _toggleAllGood(value ?? false, campos);
        },
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _toggleAllGood(bool isGood, List<String> campos) {
    setState(() {
      _isAllGood = isGood;

      if (isGood) {
        for (final fieldName in campos) {
          final campo = widget.model.camposEstado[fieldName];
          if (campo != null) {
            campo.initialValue = '1 Bueno';
            campo.comentario = 'En buen estado';
            campo.solutionValue = 'No aplica';
          }
        }
        widget.onChanged();
      }
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
