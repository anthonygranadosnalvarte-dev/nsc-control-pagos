import '../models/familia_model.dart';
import '../models/alumno_model.dart';
import '../models/deuda_model.dart';
import '../core/utils/helpers.dart';
import 'auth_service.dart';
import 'local_store.dart';

class CatalogoService {
  final LocalStore store;
  final AuthService auth;
  CatalogoService(this.store, this.auth);
  List<Map<String, dynamic>> list(String table) {
    final u = auth.require();
    if (table == 'auditoria') {
      auth.require(['administrador']);
      return store.rows(table);
    }
    if (!['familias', 'alumnos', 'deudas'].contains(table))
      throw StateError('Tabla no permitida');
    final rows = store.rows(table);
    if (u.rol != 'padre') return rows;
    if (table == 'familias')
      return rows.where((r) => r['id'] == u.familiaId).toList();
    if (table == 'alumnos')
      return rows.where((r) => r['familiaId'] == u.familiaId).toList();
    return rows
        .where((r) => auth.canReadStudent(r['alumnoId'] as String))
        .toList();
  }

  Future<void> save(String table, Map<String, dynamic> input) async {
    final u = auth.require(['administrador']);
    if (!['familias', 'alumnos', 'deudas'].contains(table))
      throw StateError('Tabla no permitida');
    final row = Map<String, dynamic>.from(input);
    row['id'] ??= Helpers.id();
    final fields = switch (table) {
      'familias' => ['nombre', 'apoderado'],
      'alumnos' => ['nombres', 'familiaId', 'grado', 'seccion'],
      _ => ['alumnoId', 'concepto', 'vencimiento'],
    };
    for (final f in fields) {
      if ((row[f]?.toString().trim() ?? '').isEmpty)
        throw StateError('Completa $f');
    }
    if (table == 'deudas') {
      final date = row['vencimiento'].toString();
      final parsed = DateTime.tryParse(date);
      if (parsed == null || parsed.toIso8601String().substring(0, 10) != date)
        throw StateError('Fecha no válida (AAAA-MM-DD)');
      if (row['montoCentimos'] is! int || (row['montoCentimos'] as int) <= 0)
        throw StateError('Importe no válido');
    }
    await store.transaction((db) {
      if (table == 'alumnos' &&
          !(db['familias'] as List).any((f) => f['id'] == row['familiaId']))
        throw StateError('La familia no existe');
      if (table == 'deudas' &&
          !(db['alumnos'] as List).any((a) => a['id'] == row['alumnoId']))
        throw StateError('El alumno no existe');
      final normalized = switch (table) {
        'familias' => FamiliaModel.fromJson(row).toJson(),
        'alumnos' => AlumnoModel.fromJson(row).toJson(),
        _ => DeudaModel.fromJson(row).toJson(),
      };
      final list = db[table] as List;
      final index = list.indexWhere((r) => r['id'] == row['id']);
      if (table == 'alumnos' &&
          index >= 0 &&
          list[index]['familiaId'] != row['familiaId'] &&
          (db['pagos'] as List).any((p) => p['alumnoId'] == row['id'])) {
        throw StateError(
            'No se puede cambiar de familia a un alumno con pagos');
      }
      if (table == 'deudas' &&
          index >= 0 &&
          (db['pagos'] as List).any((p) => p['deudaId'] == row['id'])) {
        throw StateError(
            'No se puede editar una deuda que ya tiene movimientos');
      }
      if (index < 0) {
        list.add(normalized);
      } else {
        list[index] = normalized;
      }
      AuthService.log(
          db, u.id, index < 0 ? 'CREAR' : 'EDITAR', '$table: ${row['id']}');
    });
  }
}
