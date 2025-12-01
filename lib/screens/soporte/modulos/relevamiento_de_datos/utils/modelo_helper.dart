import '../models/relevamiento_de_datos_model.dart';
import 'constants.dart';

class ModeloHelper {
  static RelevamientoDeDatosModel inicializarModelo({
    required String codMetrica,
    required String sessionId,
    required String secaValue,
  }) {
    // Inicializar campos de estado
    final Map<String, CampoEstado> camposEstado = {};

    // Campos de Terminal
    for (final campo in AppConstants.terminalCampos) {
      camposEstado[campo] = CampoEstado();
    }

    // Campos de Plataforma
    for (final campo in AppConstants.plataformaCampos) {
      camposEstado[campo] = CampoEstado();
    }

    // Campos de Celdas de Carga
    for (final campo in AppConstants.celdasCargaCampos) {
      camposEstado[campo] = CampoEstado();
    }

    // Campos de Entorno (con valores por defecto de las opciones)
    AppConstants.entornoCampos.forEach((campo, opciones) {
      camposEstado[campo] = CampoEstado(
        initialValue: opciones.first, // Primer valor como default
        solutionValue: 'No aplica',
        comentario: 'Sin comentario',
      );
    });

    // Crear modelo
    return RelevamientoDeDatosModel(
      codMetrica: codMetrica,
      sessionId: sessionId,
      secaValue: secaValue,
      camposEstado: camposEstado,
      pruebasFinales: PruebasMetrologicas(),
    );
  }
}
