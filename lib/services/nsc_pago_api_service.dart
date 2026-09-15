import 'dart:convert';

import 'package:http/http.dart' as http;

class NscPagoApiService {
  static const endpoint =
      'https://script.google.com/macros/s/AKfycbyYo-21IsznCN7SPQr2-ntoJE_EsdOP3CgVlFpGWPGsWgsUWQt-xcABGwp2ATiuP4zxnQ/exec';

  final http.Client client;
  NscPagoApiService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> registrarPagoFamiliar({
    required String idFamilia,
    required String idOperacion,
    required int monto,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final result = await _post({
      'accion': 'registrarPagoFamiliarV5',
      'idFamilia': idFamilia,
      'idOperacion': idOperacion,
      'monto': monto / 100,
      'detalles': detalles,
    });
    final returnedOperation = result['idOperacion'];
    if (returnedOperation is! String || returnedOperation.trim().isEmpty) {
      throw StateError('El servidor no devolvió el ID de operación familiar.');
    }
    return result;
  }

  Future<Map<String, dynamic>> generarRecibo({
    String? idOperacion,
    String? idOperacionFamiliar,
  }) async {
    final familyOperation = idOperacionFamiliar?.trim();
    final individualOperation = idOperacion?.trim();
    if ((familyOperation == null || familyOperation.isEmpty) &&
        (individualOperation == null || individualOperation.isEmpty)) {
      throw StateError('Falta el identificador de operación.');
    }
    final payload = <String, dynamic>{
      'accion': 'generarReciboV5',
      'idOperacion': familyOperation?.isNotEmpty == true
          ? familyOperation
          : individualOperation,
    };
    return _post(payload, requirePdf: true);
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> payload,
      {bool requirePdf = false}) async {
    final response = await client.post(
      Uri.parse(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'El servidor de recibos respondió con HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw StateError('La respuesta del servidor de recibos no es válida.');
    }
    final result = Map<String, dynamic>.from(decoded);
    if (result['ok'] != true) {
      throw StateError((result['error'] ??
              result['message'] ??
              'No se pudo generar el recibo.')
          .toString());
    }
    if (requirePdf) {
      final pdfUrl = _readUrl(result['pdf']) ?? _readUrl(result['url']);
      if (pdfUrl == null) {
        throw StateError('El servidor no devolvió la URL del PDF del recibo.');
      }
      result['pdf'] = pdfUrl;
    }
    return result;
  }

  String? _readUrl(Object? value) {
    if (value is! String) return null;
    final url = value.trim();
    return url.isEmpty ? null : url;
  }
}
