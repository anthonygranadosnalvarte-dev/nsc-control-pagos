import 'package:url_launcher/url_launcher.dart';
import '../models/recibo_model.dart';
import '../core/utils/helpers.dart';

class WhatsappService {
  Future<void> compartirResumen(ReciboModel r, bool anulado) async {
    final text =
        'NSC - Recibo interno ${r.numero}${anulado ? ' ANULADO' : ''}\nAlumno: ${r.alumno}\nConcepto: ${r.concepto}\nImporte: ${Helpers.soles(r.montoCentimos)}\nFecha: ${Helpers.fecha(r.fecha)}\nEdición local de evaluación.';
    final url = Uri.https('wa.me', '/', {'text': text});
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      throw StateError('No se pudo abrir WhatsApp');
  }
}
