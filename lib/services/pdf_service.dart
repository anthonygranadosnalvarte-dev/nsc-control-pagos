import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recibo_model.dart';
import '../core/utils/helpers.dart';

class PdfService {
  Future<Uint8List> generar(ReciboModel r, {required bool anulado}) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NSC CONTROL ESCOLAR',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('RECIBO INTERNO ${r.numero}'),
                  pw.Text(
                      'EDICION LOCAL DE EVALUACION - NO ES COMPROBANTE TRIBUTARIO',
                      style: const pw.TextStyle(fontSize: 9)),
                  if (anulado)
                    pw.Text('ANULADO',
                        style: pw.TextStyle(
                            fontSize: 28,
                            color: PdfColors.red,
                            fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.Text('Fecha: ${Helpers.fecha(r.fecha)}'),
                  pw.SizedBox(height: 12),
                  pw.Text('Alumno: ${r.alumno}'),
                  pw.Text('Familia: ${r.familia}'),
                  pw.SizedBox(height: 20),
                  pw.Text('Concepto: ${r.concepto}'),
                  pw.Text('Medio de pago: ${r.metodo}'),
                  pw.SizedBox(height: 20),
                  pw.Text('Importe: ${Helpers.soles(r.montoCentimos)}',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Registrado por: ${r.operador}'),
                  pw.Text('Pago: ${r.pagoId}',
                      style: const pw.TextStyle(fontSize: 9)),
                ])));
    return doc.save();
  }
}
