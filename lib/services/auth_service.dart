import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../models/usuario_model.dart';
import '../models/auditoria_model.dart';
import '../core/utils/helpers.dart';
import 'local_store.dart';

class AuthService {
  final LocalStore store;
  UsuarioModel? _usuario;
  DateTime? _expires;
  AuthService(this.store);
  UsuarioModel? get usuario {
    if (_usuario == null ||
        _expires == null ||
        DateTime.now().isAfter(_expires!)) return null;
    final rows = store
        .rows('usuarios')
        .where((u) => u['id'] == _usuario!.id && u['activo'] == true);
    return rows.isEmpty ? null : UsuarioModel.fromJson(rows.first);
  }

  static Future<Map<String, String>> credentials(String password) async {
    final salt =
        base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    return {'salt': salt, 'passwordHash': await hash(password, salt)};
  }

  static Future<String> hash(String password, String salt) async {
    final key =
        await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256)
            .deriveKey(
                secretKey: SecretKey(utf8.encode(password)),
                nonce: base64Decode(salt));
    return base64Encode(await key.extractBytes());
  }

  Future<void> seed() async {
    if (store.rows('usuarios').isNotEmpty) return;
    final c = await credentials('NscDemo2026!');
    await store.transaction((db) {
      for (final role in ['administrador', 'secretaria', 'padre']) {
        (db['usuarios'] as List).add(UsuarioModel(
                id: role,
                nombre: role == 'padre' ? 'Apoderado de ejemplo' : role,
                email: '$role@nsc.local',
                rol: role,
                familiaId: role == 'padre' ? 'familia-demo' : '',
                passwordHash: c['passwordHash']!,
                salt: c['salt']!,
                activo: true)
            .toJson());
      }
      (db['familias'] as List).add({
        'id': 'familia-demo',
        'nombre': 'Familia de ejemplo',
        'apoderado': 'Apoderado de ejemplo',
        'documento': '',
        'telefono': ''
      });
      (db['alumnos'] as List).add({
        'id': 'alumno-demo',
        'familiaId': 'familia-demo',
        'nombres': 'Estudiante de ejemplo',
        'grado': '1.º primaria',
        'seccion': 'A'
      });
      (db['deudas'] as List).add({
        'id': 'deuda-demo',
        'alumnoId': 'alumno-demo',
        'concepto': 'Mensualidad de ejemplo',
        'montoCentimos': 20000,
        'vencimiento': DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String()
            .substring(0, 10)
      });
    });
  }

  Future<void> login(String email, String password) async {
    final users = store.rows('usuarios').where(
        (u) => u['email'] == email.trim().toLowerCase() && u['activo'] == true);
    if (users.isEmpty) throw StateError('Correo o contraseña incorrectos');
    final u = UsuarioModel.fromJson(users.first);
    final candidate = await hash(password, u.salt);
    var difference = candidate.length ^ u.passwordHash.length;
    for (var i = 0; i < candidate.length && i < u.passwordHash.length; i++) {
      difference |= candidate.codeUnitAt(i) ^ u.passwordHash.codeUnitAt(i);
    }
    if (difference != 0) throw StateError('Correo o contraseña incorrectos');
    await store
        .transaction((db) => log(db, u.id, 'LOGIN', 'Inicio de sesión local'));
    _usuario = u;
    _expires = DateTime.now().add(const Duration(minutes: 30));
  }

  void logout() {
    _usuario = null;
    _expires = null;
  }

  UsuarioModel require(
      [List<String> roles = const ['administrador', 'secretaria', 'padre']]) {
    final u = usuario;
    if (u == null)
      throw StateError('La sesión finalizó. Vuelve a iniciar sesión.');
    if (!roles.contains(u.rol))
      throw StateError('No tienes permiso para esta operación');
    return u;
  }

  bool canReadStudent(String studentId) {
    final u = require();
    return u.rol != 'padre' ||
        store
            .rows('alumnos')
            .any((a) => a['id'] == studentId && a['familiaId'] == u.familiaId);
  }

  static void log(
      Map<String, dynamic> db, String user, String action, String detail) {
    (db['auditoria'] as List).add(AuditoriaModel(
            id: Helpers.id(),
            usuarioId: user,
            accion: action,
            detalle: detail,
            fecha: DateTime.now().toIso8601String())
        .toJson());
  }
}
