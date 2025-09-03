class CalibrationData {
  final String codMetrica;
  final String secaValue;
  final Map<String, dynamic> balanzaData;
  final Map<String, dynamic> lastServiceData;

  CalibrationData({
    required this.codMetrica,
    required this.secaValue,
    required this.balanzaData,
    required this.lastServiceData,
  });
}