class ReciboModel {
  final String id;
  final String pagoId;
  final String numero;
  final String fecha;
  final String alumno;
  final String familia;
  final String concepto;
  final int montoCentimos;
  final String metodo;
  final String operador;
  const ReciboModel(
      {required this.id,
      required this.pagoId,
      required this.numero,
      required this.fecha,
      required this.alumno,
      required this.familia,
      required this.concepto,
      required this.montoCentimos,
      required this.metodo,
      required this.operador});
  factory ReciboModel.fromJson(Map<String, dynamic> j) => ReciboModel(
      id: j['id'] as String,
      pagoId: j['pagoId'] as String,
      numero: j['numero'] as String,
      fecha: j['fecha'] as String,
      alumno: j['alumno'] as String,
      familia: j['familia'] as String,
      concepto: j['concepto'] as String,
      montoCentimos: j['montoCentimos'] as int,
      metodo: j['metodo'] as String,
      operador: j['operador'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'pagoId': pagoId,
        'numero': numero,
        'fecha': fecha,
        'alumno': alumno,
        'familia': familia,
        'concepto': concepto,
        'montoCentimos': montoCentimos,
        'metodo': metodo,
        'operador': operador
      };
}
