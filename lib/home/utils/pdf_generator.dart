import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/servicio_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfGenerator {
  static Future<Uint8List> generateCalibracionPdf(ServicioSeca servicio) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoExtraBold();

    // Cargar logo
    final logoBytes = await rootBundle.load('images/logo_met.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Obtener datos del encabezado (del primer registro)
    final firstRecord =
        servicio.balanzas.isNotEmpty ? servicio.balanzas.first : {};
    final String cliente = firstRecord['cliente']?.toString() ?? '';
    final String razonSocial = firstRecord['razon_social']?.toString() ?? '';
    final String planta = firstRecord['planta']?.toString() ?? '';
    final String dirPlanta = firstRecord['dir_planta']?.toString() ?? '';
    final String tecResponsable = firstRecord['personal']?.toString() ??
        firstRecord['tec_responsable']?.toString() ??
        '';

    // Filtrar y deduplicar registros
    final records = _filterAndDeduplicate(
        servicio.balanzas, 'estado_servicio_bal', 'Balanza Calibrada');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            _buildHeader(
                cliente,
                razonSocial,
                planta,
                dirPlanta,
                tecResponsable,
                'RESUMEN DE CALIBRACIÓN - SECA ${servicio.seca}',
                logo),
            pw.SizedBox(height: 20),
            _buildCalibracionTable(records, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateSoportePdf(ServicioOtst servicio) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoExtraBold();

    // Cargar logo
    final logoBytes = await rootBundle.load('images/logo_met.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Obtener datos del encabezado
    final firstRecord =
        servicio.servicios.isNotEmpty ? servicio.servicios.first : {};
    final String cliente = firstRecord['cliente']?.toString() ?? '';
    final String razonSocial = firstRecord['razon_social']?.toString() ?? '';
    final String planta = firstRecord['planta']?.toString() ?? '';
    final String dirPlanta = firstRecord['dir_planta']?.toString() ?? '';
    final String tecResponsable = firstRecord['personal']?.toString() ??
        firstRecord['tec_responsable']?.toString() ??
        '';

    // Filtrar y deduplicar registros
    final records = _filterAndDeduplicate(
        servicio.servicios, 'estado_servicio', 'Completo');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            _buildHeader(
                cliente,
                razonSocial,
                planta,
                dirPlanta,
                tecResponsable,
                'Resumen de Soporte Técnico - OTST ${servicio.otst}',
                logo),
            pw.SizedBox(height: 20),
            _buildSoporteTable(records, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static List<Map<String, dynamic>> _filterAndDeduplicate(
      List<Map<String, dynamic>> originalList,
      String statusKey,
      String completedStatus) {
    // Mapa para rastrear registros únicos.
    // Clave: Identificador único (cod_metrica > serie > id generado)
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (var record in originalList) {
      // Determinar clave única
      String uniqueKey = record['cod_metrica']?.toString().trim() ?? '';
      if (uniqueKey.isEmpty || uniqueKey == 'null') {
        uniqueKey = record['serie']?.toString().trim() ?? '';
      }
      if (uniqueKey.isEmpty || uniqueKey == 'null') {
        // Si no tiene identificadores, usamos algo del contenido o lo dejamos pasar (aunque dificil de deduplicar)
        // Usamos hashCode como fallback temporal si es necesario, o lo saltamos
        uniqueKey = record.hashCode.toString();
      }

      final currentStatus = record[statusKey]?.toString() ?? '';
      final isCompleted = currentStatus == completedStatus;

      if (uniqueMap.containsKey(uniqueKey)) {
        // Ya existe un registro para este equipo
        final existingRecord = uniqueMap[uniqueKey]!;
        final existingStatus = existingRecord[statusKey]?.toString() ?? '';
        final existingIsCompleted = existingStatus == completedStatus;

        // Si el registro actual está completado y el existente no, lo reemplazamos
        if (isCompleted && !existingIsCompleted) {
          uniqueMap[uniqueKey] = record;
        }
        // Si ambos están completados o ambos incompletos, nos quedamos con el primero (o ultimo, irrelevante)
        // Si el existente esta completado y el actual no, mantenemos el existente
      } else {
        // No existe, agregamos
        uniqueMap[uniqueKey] = record;
      }
    }

    return uniqueMap.values.toList();
  }

  static pw.Widget _buildHeader(
      String cliente,
      String razonSocial,
      String planta,
      String dirPlanta,
      String tecResponsable,
      String title,
      pw.ImageProvider logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              height: 40,
              child: pw.Image(logo),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('Cliente:', cliente),
                  _buildHeaderRow('Razón Social:', razonSocial),
                  _buildHeaderRow('Planta:', planta),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('Dirección Planta:', dirPlanta),
                  _buildHeaderRow('Personal:', tecResponsable),
                ],
              ),
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildHeaderRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text('$label ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
              child:
                  pw.Text(value, maxLines: 1, overflow: pw.TextOverflow.clip)),
        ],
      ),
    );
  }

  static pw.Widget _buildCalibracionTable(
      List<Map<String, dynamic>> records, pw.Font font) {
    final headers = [
      'Marca',
      'Modelo',
      'Serie',
      'Cod. Int.',
      'Cap Max',
      'd',
      'Und',
      'Ubicación',
      'Fecha',
      'Observaciones',
      'Estado'
    ];

    final data = records.map((r) {
      final estado = r['estado_servicio_bal']?.toString() ?? '';
      final isCalibrada = estado == 'Balanza Calibrada';
      final color = isCalibrada
          ? PdfColor.fromInt(0xFFC8E6C9) // Verde suave
          : PdfColor.fromInt(0xFFFFCDD2); // Rojo suave

      return [
        r['marca']?.toString() ?? '',
        r['modelo']?.toString() ?? '',
        r['serie']?.toString() ?? '',
        r['cod_int']?.toString() ?? '',
        r['cap_max1']?.toString() ?? '',
        r['d1']?.toString() ?? '',
        r['unidades']?.toString() ?? '',
        r['ubicacion']?.toString() ?? '',
        r['fecha_servicio']?.toString() ?? '',
        r['observaciones']?.toString() ?? '',
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            estado.isEmpty ? 'Pendiente' : estado,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFF365666)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // Marca
        1: const pw.FixedColumnWidth(50), // Modelo
        2: const pw.FixedColumnWidth(50), // Serie
        3: const pw.FixedColumnWidth(50), // Cod Int
        4: const pw.FixedColumnWidth(40), // Cap
        5: const pw.FixedColumnWidth(30), // d
        6: const pw.FixedColumnWidth(30), // Und
        7: const pw.FlexColumnWidth(2), // Ubicacion (largo)
        8: const pw.FixedColumnWidth(50), // Fecha
        9: const pw.FlexColumnWidth(3), // Observaciones (muy largo)
        10: const pw.FixedColumnWidth(60), // Estado
      },
    );
  }

  static pw.Widget _buildSoporteTable(
      List<Map<String, dynamic>> records, pw.Font font) {
    final headers = [
      'Marca',
      'Modelo',
      'Serie',
      'Cod. Int.',
      'Cap Max',
      'd',
      'Und',
      'Ubicación',
      'Fecha',
      'Observaciones',
      'Estado'
    ];

    final data = records.map((r) {
      final estado = r['estado_servicio']?.toString() ?? '';
      final isCompleto = estado == 'Completo';
      final color = isCompleto
          ? PdfColor.fromInt(0xFFC8E6C9) // Verde suave
          : PdfColor.fromInt(0xFFFFCDD2); // Rojo suave

      return [
        r['marca']?.toString() ?? '',
        r['modelo']?.toString() ?? '',
        r['serie']?.toString() ?? '',
        r['cod_int']?.toString() ?? '',
        r['cap_max1']?.toString() ?? '',
        r['d1']?.toString() ?? '',
        r['unidades']?.toString() ?? '',
        r['ubicacion']?.toString() ?? '',
        r['fecha_servicio']?.toString() ?? '',
        r['observaciones']?.toString() ?? '',
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              estado.isEmpty ? 'Pendiente' : estado,
              style: const pw.TextStyle(fontSize: 8),
            )),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFF365666)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // Marca
        1: const pw.FixedColumnWidth(50), // Modelo
        2: const pw.FixedColumnWidth(50), // Serie
        3: const pw.FixedColumnWidth(50), // Cod Int
        4: const pw.FixedColumnWidth(40), // Cap
        5: const pw.FixedColumnWidth(30), // d
        6: const pw.FixedColumnWidth(30), // Und
        7: const pw.FlexColumnWidth(2), // Ubicacion
        8: const pw.FixedColumnWidth(50), // Fecha
        9: const pw.FlexColumnWidth(3), // Observaciones
        10: const pw.FixedColumnWidth(60), // Estado
      },
    );
  }
}
