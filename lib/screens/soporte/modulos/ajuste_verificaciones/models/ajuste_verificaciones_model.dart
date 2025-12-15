import '../../mnt_prv_regular/mnt_prv_regular_stil/models/mnt_prv_regular_stil_model.dart';

class AjusteVerificacionesModel {
  final String codMetrica;
  final String sessionId;
  final String secaValue;

  // Reutilizamos PruebasMetrologicas del módulo STIL para poder usar sus widgets
  PruebasMetrologicas pruebasIniciales;
  PruebasMetrologicas pruebasFinales;

  // Datos generales
  String horaInicio;
  String horaFin;

  // Lista de hasta 10 comentarios
  List<String?> comentarios;

  AjusteVerificacionesModel({
    required this.codMetrica,
    required this.sessionId,
    required this.secaValue,
    PruebasMetrologicas? pruebasIniciales,
    PruebasMetrologicas? pruebasFinales,
    this.horaInicio = '',
    this.horaFin = '',
    List<String?>? comentarios,
  })  : pruebasIniciales = pruebasIniciales ?? PruebasMetrologicas(),
        pruebasFinales = pruebasFinales ?? PruebasMetrologicas(),
        comentarios = comentarios ?? List.filled(10, null);

  void reset() {
    pruebasIniciales = PruebasMetrologicas();
    pruebasFinales = PruebasMetrologicas();
    horaInicio = '';
    horaFin = '';
    comentarios = List.filled(10, null);
  }
}
