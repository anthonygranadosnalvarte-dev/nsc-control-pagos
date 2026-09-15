class DeudaModel {
  final String id;
  final String alumnoId;
  final String concepto;
  final int montoCentimos;
  final String vencimiento;
  const DeudaModel(
      {required this.id,
      required this.alumnoId,
      required this.concepto,
      required this.montoCentimos,
      required this.vencimiento});
  factory DeudaModel.fromJson(Map<String, dynamic> j) => DeudaModel(
      id: j['id'] as String,
      alumnoId: j['alumnoId'] as String,
      concepto: j['concepto'] as String,
      montoCentimos: j['montoCentimos'] as int,
      vencimiento: j['vencimiento'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'alumnoId': alumnoId,
        'concepto': concepto,
        'montoCentimos': montoCentimos,
        'vencimiento': vencimiento
      };
}
