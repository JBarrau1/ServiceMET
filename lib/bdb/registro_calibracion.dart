class RegistroCalibracion {
  final String cliente;
  final String razonSocial;
  final String planta;
  final String depPlanta;
  final String codPlanta;
  final String personal;
  final String seca;
  final String nReca;
  final String sticker;
  final String equipo;
  final String certificado;
  final String enteCalibrador;
  final String estado;
  final int cantidad;
  final String codMetrica;
  final String estadoBalanza;
  final String codInt;
  final String tipoEquipo;
  final String marca;
  final String modelo;
  final String serie;
  final String unidades;
  final String ubicacion;
  final double pmax1;
  final double d1;
  final double e1;
  final double dec1;
  final double pmax2;
  final double d2;
  final double e2;
  final double dec2;
  final double pmax3;
  final double d3;
  final double e3;
  final double dec3;
  final double fecha_servicio;
  final String horaInicio;
  final String tiempoEstab;
  final String tOpeBalanza;
  final String vibracion;
  final String vibracion_foto;
  final String vibracion_comentario;
  final String polvo;
  final String polvo_foto;
  final String polvo_comentario;
  final String temp;
  final String temp_foto;
  final String temp_comentario;
  final String humedad;
  final String humedad_foto;
  final String humedad_comentario;
  final String mesada;
  final String mesada_foto;
  final String mesada_comentario;
  final String iluminacion;
  final String iluminacion_foto;
  final String iluminacion_comentario;
  final String limpFoza;
  final String LimpFoza_foto;
  final String LimpFoza_comentario;
  final String estadoDrenaje;
  final String estadoDrenaje_foto;
  final String estadoDrenaje_comentario;
  final String limpGeneral;
  final String limpGeneral_foto;
  final String limpGeneral_comentario;
  final String golpesTerminal;
  final String golpesTerminal_foto;
  final String golpesTerminal_comentario;
  final String nivelacion;
  final String nivelacion_foto;
  final String nivelacion_comentario;
  final String limpRecepto;
  final String limpRecepto_foto;
  final String limpRecepto_comentario;
  final String golpesReceptor;
  final String golpesReceptor_foto;
  final String golpesReceptor_comentario;
  final String encendido;
  final String encendido_foto;
  final String encendido_comentario;
  final List<double> precarga;
  final List<double> p_indicador;
  final String ajuste;
  final String tipo;
  final String cargasPesas;
  final String hora;
  final String hri;
  final String ti;
  final String patmi;
  final String tipoPlataforma;
  final String puntosInd;
  final String carga;
  final List<double> pocision;
  final List<double> indicacion_pe;
  final List<double> retorno;
  final List<double> repetibilidad;
  final String metodo;
  final String metodoCarga;
  final List<double> lin;
  final List<double> ind;
  final String horaFin;
  final String hriFin;
  final String tiFin;
  final String patmiFin;
  final String mantSoporte;
  final String ventaPesas;
  final String reemplazo;
  final String observaciones;
  final String emp;
  final String indicar;
  final String factor;
  final String reglaAceptacion;
  final String fechaServicio;
  final String comentario_general;

  RegistroCalibracion({
    required this.cliente,
    required this.razonSocial,
    required this.planta,
    required this.depPlanta,
    required this.codPlanta,
    required this.personal,
    required this.seca,
    required this.nReca,
    required this.sticker,
    required this.equipo,
    required this.certificado,
    required this.enteCalibrador,
    required this.estado,
    required this.cantidad,
    required this.codMetrica,
    required this.estadoBalanza,
    required this.codInt,
    required this.tipoEquipo,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.unidades,
    required this.ubicacion,
    required this.pmax1,
    required this.d1,
    required this.e1,
    required this.dec1,
    required this.pmax2,
    required this.d2,
    required this.e2,
    required this.dec2,
    required this.pmax3,
    required this.d3,
    required this.e3,
    required this.dec3,
    required this.fecha_servicio,
    required this.horaInicio,
    required this.tiempoEstab,
    required this.tOpeBalanza,
    required this.vibracion,
    required this.vibracion_foto,
    required this.vibracion_comentario,
    required this.polvo,
    required this.polvo_foto,
    required this.polvo_comentario,
    required this.temp,
    required this.temp_foto,
    required this.temp_comentario,
    required this.humedad,
    required this.humedad_foto,
    required this.humedad_comentario,
    required this.mesada,
    required this.mesada_foto,
    required this.mesada_comentario,
    required this.iluminacion,
    required this.iluminacion_foto,
    required this.iluminacion_comentario,
    required this.limpFoza,
    required this.LimpFoza_foto,
    required this.LimpFoza_comentario,
    required this.estadoDrenaje,
    required this.estadoDrenaje_foto,
    required this.estadoDrenaje_comentario,

    required this.limpGeneral,
    required this.limpGeneral_foto,
    required this.limpGeneral_comentario,
    required this.golpesTerminal,
    required this.golpesTerminal_foto,
    required this.golpesTerminal_comentario,
    required this.nivelacion,
    required this.nivelacion_foto,
    required this.nivelacion_comentario,
    required this.limpRecepto,
    required this.limpRecepto_foto,
    required this.limpRecepto_comentario,
    required this.golpesReceptor,
    required this.golpesReceptor_foto,
    required this.golpesReceptor_comentario,
    required this.encendido,
    required this.encendido_foto,
    required this.encendido_comentario,
    required this.precarga,
    required this.p_indicador,
    required this.ajuste,
    required this.tipo,
    required this.cargasPesas,
    required this.hora,
    required this.hri,
    required this.ti,
    required this.patmi,
    required this.tipoPlataforma,
    required this.puntosInd,
    required this.carga,
    required this.pocision,
    required this.indicacion_pe,
    required this.retorno,
    required this.repetibilidad,
    required this.metodo,
    required this.metodoCarga,
    required this.lin,
    required this.ind,
    required this.horaFin,
    required this.hriFin,
    required this.tiFin,
    required this.patmiFin,
    required this.mantSoporte,
    required this.ventaPesas,
    required this.reemplazo,
    required this.observaciones,
    required this.emp,
    required this.indicar,
    required this.factor,
    required this.reglaAceptacion,
    required this.fechaServicio,
    required this.comentario_general
  });
}