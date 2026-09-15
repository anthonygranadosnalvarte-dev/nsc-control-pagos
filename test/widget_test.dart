import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsc_control_escolar/main.dart';
import 'package:nsc_control_escolar/services/auth_service.dart';
import 'package:nsc_control_escolar/services/local_store.dart';

void main() {
  testWidgets('Inicio muestra login y no expone panel sin sesión',
      (tester) async {
    final store = LocalStore(null);
    final auth = AuthService(store);
    await tester.pumpWidget(NscApp(store: store, auth: auth));
    expect(find.text('NSC\nControl Escolar'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrar pago'), findsNothing);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Campo obligatorio'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
