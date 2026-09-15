class AuditoriaModel {
  final String id;
  final String usuarioId;
  final String accion;
  final String detalle;
  final String fecha;
  const AuditoriaModel(
      {required this.id,
      required this.usuarioId,
      required this.accion,
      required this.detalle,
      required this.fecha});
  factory AuditoriaModel.fromJson(Map<String, dynamic> j) => AuditoriaModel(
      id: j['id'] as String,
      usuarioId: j['usuarioId'] as String,
      accion: j['accion'] as String,
      detalle: j['detalle'] as String,
      fecha: j['fecha'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'usuarioId': usuarioId,
        'accion': accion,
        'detalle': detalle,
        'fecha': fecha
      };
}
