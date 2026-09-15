class FamiliaModel {
  final String id;
  final String nombre;
  final String apoderado;
  final String documento;
  final String telefono;
  const FamiliaModel(
      {required this.id,
      required this.nombre,
      required this.apoderado,
      required this.documento,
      required this.telefono});
  factory FamiliaModel.fromJson(Map<String, dynamic> j) => FamiliaModel(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      apoderado: j['apoderado'] as String,
      documento: j['documento'] as String,
      telefono: j['telefono'] as String);
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apoderado': apoderado,
        'documento': documento,
        'telefono': telefono
      };
}
