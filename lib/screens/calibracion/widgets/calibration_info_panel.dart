import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/balanza_provider.dart';

class CalibrationInfoPanel extends StatelessWidget {
  const CalibrationInfoPanel({super.key});

  Widget _buildDetailContainer(String label, String value, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            value,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white : Colors.black;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Información de la balanza',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (balanza != null) ...[
              _buildDetailContainer('Código Métrica', balanza.cod_metrica, textColor, borderColor),
              _buildDetailContainer('Unidades', balanza.unidad.toString(), textColor, borderColor),
              _buildDetailContainer('pmax1', balanza.cap_max1, textColor, borderColor),
              _buildDetailContainer('d1', balanza.d1.toString(), textColor, borderColor),
              _buildDetailContainer('e1', balanza.e1.toString(), textColor, borderColor),
              _buildDetailContainer('dec1', balanza.dec1.toString(), textColor, borderColor),
              _buildDetailContainer('pmax2', balanza.cap_max2, textColor, borderColor),
              _buildDetailContainer('d2', balanza.d2.toString(), textColor, borderColor),
              _buildDetailContainer('e2', balanza.e2.toString(), textColor, borderColor),
              _buildDetailContainer('dec2', balanza.dec2.toString(), textColor, borderColor),
              _buildDetailContainer('pmax3', balanza.cap_max3, textColor, borderColor),
              _buildDetailContainer('d3', balanza.d3.toString(), textColor, borderColor),
              _buildDetailContainer('e3', balanza.e3.toString(), textColor, borderColor),
              _buildDetailContainer('dec3', balanza.dec3.toString(), textColor, borderColor),
            ],
          ],
        ),
      ),
    );
  }
}