// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/precarga/widgets/step_indicator.dart';
import 'fin_servicios_controller.dart';
import 'widgets/condiciones_finales_step.dart';
import 'widgets/exportacion_step.dart';

class FinServiciosScreen extends StatelessWidget {
  final String secaValue;
  final String sessionId;
  final String codMetrica;
  final Map<String, dynamic> selectedBalanza;

  const FinServiciosScreen({
    super.key,
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
    required this.selectedBalanza,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FinServiciosController(
        secaValue: secaValue,
        sessionId: sessionId,
        codMetrica: codMetrica,
        context: context,
      ),
      child: Consumer<FinServiciosController>(
        builder: (context, controller, child) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDarkMode ? Colors.white : Colors.black;

          final List<StepData> steps = [
            StepData(
              title: 'Condiciones Finales',
              subtitle: 'Registro de datos',
              icon: Icons.assignment,
            ),
            StepData(
              title: 'Finalizar',
              subtitle: 'Exportación',
              icon: Icons.check_circle,
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              title: Text(
                'CALIBRACIÓN',
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
            body: Column(
              children: [
                StepIndicator(
                  currentStep: controller.currentStep,
                  steps: steps,
                ),
                Expanded(
                  child: IndexedStack(
                    index: controller.currentStep,
                    children: const [
                      CondicionesFinalesStep(),
                      ExportacionStep(),
                    ],
                  ),
                ),
                _buildBottomButtons(context, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, FinServiciosController controller) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.currentStep > 0)
            ElevatedButton(
              onPressed: controller.previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child:
                  const Text('Anterior', style: TextStyle(color: Colors.white)),
            )
          else
            const SizedBox.shrink(),
          if (controller.currentStep < 1)
            ElevatedButton(
              onPressed: () async {
                if (controller.currentStep == 0) {
                  // Validate and save step 1 before moving
                  await controller.saveStep1();
                  if (controller.isDataSaved) {
                    controller.nextStep();
                  }
                } else {
                  controller.nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc0101a),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Siguiente',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
