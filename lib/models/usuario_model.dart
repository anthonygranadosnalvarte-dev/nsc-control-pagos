class UsuarioModel {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String familiaId;
  final String passwordHash;
  final String salt;
  final bool activo;
  const UsuarioModel(
      {required this.id,
      required this.nombre,
      required this.email,
      required this.rol,
      required this.familiaId,
      required this.passwordHash,
      required this.salt,
      required this.activo});
  factory UsuarioModel.fromJson(Map<String, dynamic> j) => UsuarioModel(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      email: j['email'] as String,
      rol: j['rol'] as String,
      familiaId: j['familiaId'] as String,
      passwordHash: j['passwordHash'] as String,
      salt: j['salt'] as String,
      activo: j['activo'] as bool);
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'familiaId': familiaId,
        'passwordHash': passwordHash,
        'salt': salt,
        'activo': activo
      };
}
