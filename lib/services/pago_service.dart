import '../core/utils/helpers.dart';
import '../models/pago_model.dart';
import 'local_store.dart';
import 'auth_service.dart';

class PagoService {
  final LocalStore store;
  final AuthService auth;
  PagoService(this.store, this.auth);
  List<PagoModel> list() {
    auth.require();
    return store
        .rows('pagos')
        .where((p) => auth.canReadStudent(p['alumnoId'] as String))
        .map(PagoModel.fromJson)
        .toList();
  }

  int saldo(String deudaId) {
    final d = store.rows('deudas').firstWhere((d) => d['id'] == deudaId);
    if (!auth.canReadStudent(d['alumnoId'] as String))
      throw StateError('Sin acceso');
    return balance(d, store.rows('pagos'));
  }

  static int balance(Map<String, dynamic> deuda, Iterable<dynamic> pagos) =>
      (deuda['montoCentimos'] as int) -
      pagos
          .where((p) => p['deudaId'] == deuda['id'] && p['anulado'] == false)
          .fold<int>(0, (s, p) => s + (p['montoCentimos'] as int));
  Future<String> registrar(
      {required String deudaId,
      required int monto,
      required String metodo,
      required String referencia,
      required String solicitudId}) async {
    final u = auth.require(['administrador', 'secretaria']);
    if (solicitudId.trim().isEmpty)
      throw StateError('Falta el identificador de solicitud');
    if (monto <= 0) throw StateError('El importe debe ser mayor que cero');
    if (!['Efectivo', 'Transferencia', 'Yape', 'Plin', 'Tarjeta']
        .contains(metodo)) throw StateError('Método no válido');
    if (metodo != 'Efectivo' && referencia.trim().isEmpty)
      throw StateError('Ingresa el número de operación');
    return store.transaction((db) {
      final payments = db['pagos'] as List;
      final existing = payments.where((p) => p['solicitudId'] == solicitudId);
      if (existing.isNotEmpty) {
        final old = existing.first;
        if (old['deudaId'] != deudaId ||
            old['montoCentimos'] != monto ||
            old['metodo'] != metodo ||
            old['referencia'] != referencia.trim()) {
          throw StateError('La solicitud ya existe con otros datos');
        }
        return old['id'] as String;
      }
      final d = Map<String, dynamic>.from(
          (db['deudas'] as List).firstWhere((d) => d['id'] == deudaId) as Map);
      if (monto > balance(d, payments))
        throw StateError('El importe supera el saldo pendiente');
      if (metodo != 'Efectivo' &&
          payments.any((p) =>
              p['metodo'] == metodo &&
              p['referencia'] == referencia.trim() &&
              p['anulado'] == false)) {
        throw StateError('Esa operación ya fue registrada');
      }
      final a =
          (db['alumnos'] as List).firstWhere((a) => a['id'] == d['alumnoId']);
      final f =
          (db['familias'] as List).firstWhere((f) => f['id'] == a['familiaId']);
      final id = Helpers.id();
      final now = DateTime.now().toIso8601String();
      payments.add(PagoModel(
              id: id,
              deudaId: deudaId,
              alumnoId: a['id'] as String,
              montoCentimos: monto,
              fecha: now,
              metodo: metodo,
              referencia: referencia.trim(),
              usuarioId: u.id,
              solicitudId: solicitudId,
              anulado: false,
              motivoAnulacion: '')
          .toJson());
      final number = (db['secuencia'] as int) + 1;
      db['secuencia'] = number;
      (db['recibos'] as List).add({
        'id': Helpers.id(),
        'pagoId': id,
        'numero': 'NSC-${number.toString().padLeft(6, '0')}',
        'fecha': now,
        'alumno': a['nombres'],
        'familia': f['nombre'],
        'concepto': d['concepto'],
        'montoCentimos': monto,
        'metodo': metodo,
        'operador': u.nombre
      });
      AuthService.log(db, u.id, 'PAGO', 'Pago $id por ${Helpers.soles(monto)}');
      return id;
    });
  }

  Future<void> anular(String id, String motivo) async {
    final u = auth.require(['administrador']);
    if (motivo.trim().length < 5)
      throw StateError('Indica el motivo (mínimo 5 caracteres)');
    await store.transaction((db) {
      final p = (db['pagos'] as List).firstWhere((p) => p['id'] == id);
      if (p['anulado'] == true) throw StateError('El pago ya está anulado');
      p['anulado'] = true;
      p['motivoAnulacion'] = motivo.trim();
      AuthService.log(db, u.id, 'ANULAR PAGO', '$id: ${motivo.trim()}');
    });
  }
}
