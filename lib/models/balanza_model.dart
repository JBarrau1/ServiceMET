// lib/models/balanza_model.dart
// ignore_for_file: non_constant_identifier_names

class Balanza {
  final String cod_metrica;
  final String n_celdas;
  final String unidad;
  final String cap_max1;
  final double d1;
  final double e1;
  final double dec1;
  final String cap_max2;
  final double d2;
  final double e2;
  final double dec2;
  final String cap_max3;
  final double d3;
  final double e3;
  final double dec3;
  double exc;

  Balanza({
    required this.cod_metrica,
    required this.n_celdas,
    required this.unidad,
    required this.cap_max1,
    required this.d1,
    required this.e1,
    required this.dec1,
    required this.cap_max2,
    required this.d2,
    required this.e2,
    required this.dec2,
    required this.cap_max3,
    required this.d3,
    required this.e3,
    required this.dec3,
    required this.exc,
  });

  Null get tipo_equipo => null;
  Null get cod_interno => null;
  Null get marca => null;
  Null get modelo => null;
  Null get serie => null;
  Null get unidades => null;
  Null get ubicacion => null;
}
