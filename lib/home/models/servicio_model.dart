class ServicioSeca {
  final String seca;
  final int cantidadBalanzas;
  final List<Map<String, dynamic>> balanzas;

  ServicioSeca({
    required this.seca,
    required this.cantidadBalanzas,
    required this.balanzas,
  });
}

class ServicioOtst {
  final String otst;
  final int cantidadServicios;
  final List<Map<String, dynamic>> servicios;

  ServicioOtst({
    required this.otst,
    required this.cantidadServicios,
    required this.servicios,
  });
}
