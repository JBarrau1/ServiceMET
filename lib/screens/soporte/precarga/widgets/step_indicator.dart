// widgets/step_indicator.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaControllerSop>(
      builder: (context, controller, child) {
        final steps = ['Servicio', 'Cliente', 'Planta', 'OTST', 'Balanza', 'Confirmar'];

        // Mapear step interno a índice visual
        int getVisualIndex(int internalStep) {
          return internalStep + 1; // -1 -> 0, 0 -> 1, 1 -> 2, etc.
        }

        final currentVisualIndex = getVisualIndex(controller.currentStep);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Línea de progreso
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: currentVisualIndex / (steps.length - 1),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Indicadores de pasos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(steps.length, (visualIndex) {
                  final isActive = visualIndex <= currentVisualIndex;
                  final isCompleted = visualIndex < currentVisualIndex;
                  final isCurrent = visualIndex == currentVisualIndex;

                  return Expanded(
                    child: Column(
                      children: [
                        // Círculo del paso
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? Colors.green
                                : isCurrent
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            border: Border.all(
                              color: isActive
                                  ? (isCompleted ? Colors.green : Theme.of(context).primaryColor)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                                : Text(
                              '${visualIndex + 1}',
                              style: GoogleFonts.inter(
                                color: isActive ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Texto del paso
                        Text(
                          steps[visualIndex],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isActive
                                ? (isCurrent ? Theme.of(context).primaryColor : Colors.green)
                                : Colors.grey[600],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Indicador de validación
                        if (isCompleted)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}