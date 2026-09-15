import 'package:flutter_test/flutter_test.dart';
import 'package:nsc_control_escolar/services/local_store.dart';
import 'package:nsc_control_escolar/services/auth_service.dart';
import 'package:nsc_control_escolar/services/pago_service.dart';
import 'package:nsc_control_escolar/services/recibo_service.dart';
import 'package:nsc_control_escolar/services/catalogo_service.dart';
import 'package:nsc_control_escolar/core/utils/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStore store;
  late AuthService auth;
  late PagoService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
    await store.load();
    auth = AuthService(store);
    await auth.seed();
    await auth.login('administrador@nsc.local', 'NscDemo2026!');
    service = PagoService(store, auth);
  });
  Future<String> pay(int amount, String key) => service.registrar(
      deudaId: 'deuda-demo',
      monto: amount,
      metodo: 'Efectivo',
      referencia: '',
      solicitudId: key);
  test('Importes exactos: acepta coma y rechaza más de dos decimales', () {
    expect(Helpers.centimos('135,50'), 13550);
    expect(Helpers.centimos('0.01'), 1);
    expect(Helpers.centimos('1.005'), isNull);
    expect(Helpers.centimos('-2'), isNull);
  });
  test('Pago parcial genera un solo recibo y una repetición no duplica',
      () async {
    final first = await pay(5000, 'request-1');
    final second = await pay(5000, 'request-1');
    expect(second, first);
    expect(service.saldo('deuda-demo'), 15000);
    expect(store.rows('pagos'), hasLength(1));
    expect(store.rows('recibos'), hasLength(1));
    expect(store.rows('recibos').single['numero'], 'NSC-000001');
  });
  test('Una misma solicitud con otros datos se rechaza', () async {
    await pay(5000, 'same');
    await expectLater(pay(6000, 'same'), throwsStateError);
    expect(service.saldo('deuda-demo'), 15000);
  });
  test('Rechaza sobrepago y no deja recibo huérfano', () async {
    await expectLater(pay(20001, 'over'), throwsStateError);
    expect(store.rows('pagos'), isEmpty);
    expect(store.rows('recibos'), isEmpty);
    expect(service.saldo('deuda-demo'), 20000);
  });
  test('Anulación restaura saldo y conserva recibo marcado', () async {
    final id = await pay(20000, 'full');
    expect(service.saldo('deuda-demo'), 0);
    await service.anular(id, 'Registro de prueba incorrecto');
    expect(service.saldo('deuda-demo'), 20000);
    final receipts = ReciboService(store, auth);
    expect(receipts.anulado(receipts.list().single.id), isTrue);
  });
  test('Secretaría registra pero no administra usuarios ni anula pagos',
      () async {
    auth.logout();
    await auth.login('secretaria@nsc.local', 'NscDemo2026!');
    final id = await pay(1000, 'secretaria');
    await expectLater(service.anular(id, 'No autorizado'), throwsStateError);
    await expectLater(
        CatalogoService(store, auth)
            .save('familias', {'nombre': 'Otra', 'apoderado': 'Prueba'}),
        throwsStateError);
  });
  test('Padre ve únicamente su familia y no puede registrar pagos', () async {
    await pay(1000, 'visible');
    await store.transaction((db) {
      (db['alumnos'] as List).add({
        'id': 'otro',
        'familiaId': 'otra',
        'nombres': 'Otro alumno',
        'grado': '2',
        'seccion': 'A'
      });
      (db['deudas'] as List).add({
        'id': 'otra-deuda',
        'alumnoId': 'otro',
        'concepto': 'Otro',
        'montoCentimos': 100,
        'vencimiento': '2026-01-01'
      });
    });
    auth.logout();
    await auth.login('padre@nsc.local', 'NscDemo2026!');
    expect(CatalogoService(store, auth).list('alumnos'), hasLength(1));
    expect(() => service.saldo('otra-deuda'), throwsStateError);
    await expectLater(pay(1000, 'forbidden'), throwsStateError);
    expect(ReciboService(store, auth).list(), hasLength(1));
  });
  test('Datos sobreviven a una nueva instancia del almacenamiento', () async {
    await pay(5000, 'persist');
    final reopened = LocalStore(await SharedPreferences.getInstance());
    await reopened.load();
    expect(reopened.rows('pagos'), hasLength(1));
    expect(reopened.rows('recibos'), hasLength(1));
  });
  test('Fallo dentro de transacción no modifica el estado', () async {
    await expectLater(store.transaction<void>((db) {
      (db['pagos'] as List).add({'id': 'bad'});
      throw StateError('fallo');
    }), throwsStateError);
    expect(store.rows('pagos'), isEmpty);
  });
  test('No se puede editar una deuda con pagos ni transferir el alumno',
      () async {
    await pay(100, 'locked');
    final d = store.rows('deudas').single;
    await expectLater(
        CatalogoService(store, auth)
            .save('deudas', {...d, 'montoCentimos': 30000}),
        throwsStateError);
  });
}
