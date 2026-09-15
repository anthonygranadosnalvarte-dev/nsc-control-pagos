class AlumnoModel {
  final String id;
  final String familiaId;
  final String nombres;
  final String grado;
  final String seccion;
  const AlumnoModel(
      {required this.id,
      required this.familiaId,
      required this.nombres,
      required this.grado,
      required this.seccion});
  factory AlumnoModel.fromJson(Map<String, dynamic> j) => AlumnoModel(
      id: j['id'] as String,
      familiaId: j['familiaId'] as String,
      nombres: j['nombres'] as String,
      grado: j['grado'] as String,
      seccion: j['seccion'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'familiaId': familiaId,
        'nombres': nombres,
        'grado': grado,
        'seccion': seccion
      };
}
