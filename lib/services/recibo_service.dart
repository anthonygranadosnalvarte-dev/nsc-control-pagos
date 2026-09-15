import '../models/recibo_model.dart';
import 'local_store.dart';
import 'auth_service.dart';

class ReciboService {
  final LocalStore store;
  final AuthService auth;
  ReciboService(this.store, this.auth);
  List<ReciboModel> list() {
    auth.require();
    final allowed = store
        .rows('pagos')
        .where((p) => auth.canReadStudent(p['alumnoId'] as String))
        .map((p) => p['id'])
        .toSet();
    return store
        .rows('recibos')
        .where((r) => allowed.contains(r['pagoId']))
        .map(ReciboModel.fromJson)
        .toList();
  }

  ReciboModel get(String id) => list().firstWhere((r) => r.id == id);
  bool anulado(String id) {
    final r = get(id);
    return store.rows('pagos').firstWhere((p) => p['id'] == r.pagoId)['anulado']
        as bool;
  }
}
