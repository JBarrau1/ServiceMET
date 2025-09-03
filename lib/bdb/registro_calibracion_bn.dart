class RegistroCalibracion {

  final String empresa;
  final String planta;
  final String depPlanta;
  final String personal;
  final String sticker;
  //pesas patron
  final String equipo;
  final String certificado;
  final String enteCalibrador;
  final String estado;
  final int cantidad;
  //informacion de la balanza
  final String codMetrica;
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
  //entorno de la balanza
  final String horaInicio;
  final String tiempoEstab;
  final String tOpeBalanza;
  final String vibracion;
  final String polvo;
  final String temp;
  final String humedad;
  final String mesada;
  final String iluminacion;
  final String limpFoza;
  final String estadoDrenaje;
  final String limpGeneral;
  final String golpesTerminal;
  final String nivelacion;
  final String limpRecepto;
  final String golpesReceptor;
  final String encendido;
  //datos del servicio
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

  RegistroCalibracion({

    required this.empresa,
    required this.planta,
    required this.depPlanta,
    required this.personal,
    required this.sticker,
    //pesas patron
    required this.equipo,
    required this.certificado,
    required this.enteCalibrador,
    required this.estado,
    required this.cantidad,
    //informacion de la balanza
    required this.codMetrica,
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
    //entorno de la balanza
    required this.horaInicio,
    required this.tiempoEstab,
    required this.tOpeBalanza,
    required this.vibracion,
    required this.polvo,
    required this.temp,
    required this.humedad,
    required this.mesada,
    required this.iluminacion,
    required this.limpFoza,
    required this.estadoDrenaje,
    required this.limpGeneral,
    required this.golpesTerminal,
    required this.nivelacion,
    required this.limpRecepto,
    required this.golpesReceptor,
    required this.encendido,
    //datos del servicio
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
  });
}