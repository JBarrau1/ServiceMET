// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class StepData {
  final String title;
  final String subtitle;
  final IconData icon;

  const StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<StepData> steps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Validar que el paso actual esté dentro de los límites
    final safeCurrentStep = currentStep.clamp(0, steps.length - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título del paso actual
          Row(
            children: [
              Icon(
                steps[safeCurrentStep].icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${safeCurrentStep + 1} de ${steps.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      steps[safeCurrentStep].title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      steps[safeCurrentStep].subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso visual
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index < safeCurrentStep;
              final isCurrent = index == safeCurrentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == steps.length - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
