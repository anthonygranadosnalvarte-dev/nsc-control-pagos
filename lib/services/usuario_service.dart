import '../core/utils/helpers.dart';
import '../core/utils/validators.dart';
import 'local_store.dart';
import 'auth_service.dart';

class UsuarioService {
  final LocalStore store;
  final AuthService auth;
  UsuarioService(this.store, this.auth);
  List<Map<String, dynamic>> list() {
    auth.require(['administrador']);
    return store
        .rows('usuarios')
        .map((u) => {...u}
          ..remove('passwordHash')
          ..remove('salt'))
        .toList();
  }

  Future<void> save(Map<String, dynamic> input, String password) async {
    final actor = auth.require(['administrador']);
    final row = Map<String, dynamic>.from(input);
    row['email'] = row['email'].toString().trim().toLowerCase();
    if (Validators.email(row['email'] as String) != null ||
        row['nombre'].toString().trim().isEmpty)
      throw StateError('Nombre o correo no válido');
    if (!['administrador', 'secretaria', 'padre'].contains(row['rol']))
      throw StateError('Rol no válido');
    if (row['id'] == null && password.isEmpty)
      throw StateError('Ingresa una contraseña');
    if (password.isNotEmpty && password.length < 10)
      throw StateError('Usa una contraseña de al menos 10 caracteres');
    final credentials =
        password.isEmpty ? null : await AuthService.credentials(password);
    auth.require(['administrador']);
    await store.transaction((db) {
      final list = db['usuarios'] as List;
      final index = list.indexWhere((u) => u['id'] == row['id']);
      if (list.any((u) => u['email'] == row['email'] && u['id'] != row['id']))
        throw StateError('Ese correo ya existe');
      if (row['rol'] == 'padre' &&
          !(db['familias'] as List).any((f) => f['id'] == row['familiaId']))
        throw StateError('Selecciona la familia del padre');
      if (row['rol'] != 'padre') row['familiaId'] = '';
      row['id'] ??= Helpers.id();
      if (row['id'] == actor.id &&
          (row['rol'] != 'administrador' || row['activo'] != true))
        throw StateError(
            'No puedes quitarte tu propio acceso de administrador');
      final value = <String, dynamic>{
        if (index >= 0) ...Map<String, dynamic>.from(list[index] as Map),
        ...row,
        if (credentials != null) ...credentials
      };
      if (index >= 0) {
        list[index] = value;
      } else {
        list.add(value);
      }
      AuthService.log(db, actor.id, 'USUARIO',
          '${index < 0 ? 'Crear' : 'Actualizar'} ${row['email']}');
    });
  }
}
