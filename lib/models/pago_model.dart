class PagoModel {
  final String id;
  final String deudaId;
  final String alumnoId;
  final int montoCentimos;
  final String fecha;
  final String metodo;
  final String referencia;
  final String usuarioId;
  final String solicitudId;
  final bool anulado;
  final String motivoAnulacion;
  const PagoModel(
      {required this.id,
      required this.deudaId,
      required this.alumnoId,
      required this.montoCentimos,
      required this.fecha,
      required this.metodo,
      required this.referencia,
      required this.usuarioId,
      required this.solicitudId,
      required this.anulado,
      required this.motivoAnulacion});
  factory PagoModel.fromJson(Map<String, dynamic> j) => PagoModel(
      id: j['id'] as String,
      deudaId: j['deudaId'] as String,
      alumnoId: j['alumnoId'] as String,
      montoCentimos: j['montoCentimos'] as int,
      fecha: j['fecha'] as String,
      metodo: j['metodo'] as String,
      referencia: j['referencia'] as String,
      usuarioId: j['usuarioId'] as String,
      solicitudId: j['solicitudId'] as String,
      anulado: j['anulado'] as bool,
      motivoAnulacion: j['motivoAnulacion'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'deudaId': deudaId,
        'alumnoId': alumnoId,
        'montoCentimos': montoCentimos,
        'fecha': fecha,
        'metodo': metodo,
        'referencia': referencia,
        'usuarioId': usuarioId,
        'solicitudId': solicitudId,
        'anulado': anulado,
        'motivoAnulacion': motivoAnulacion
      };
}
