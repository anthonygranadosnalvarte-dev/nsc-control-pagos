import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/local_store.dart';
import 'services/auth_service.dart';
import 'services/usuario_service.dart';
import 'services/catalogo_service.dart';
import 'services/pago_service.dart';
import 'services/recibo_service.dart';
import 'services/pdf_service.dart';
import 'services/whatsapp_service.dart';
import 'services/nsc_pago_api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/pago_provider.dart';
import 'providers/recibo_provider.dart';
import 'screens/auth/login_screen.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.load();
    final auth = AuthService(store);
    await auth.seed();
    runApp(NscApp(store: store, auth: auth));
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                        'No se pudo abrir el almacenamiento local. No se borraron datos.\n$e'))))));
  }
}

class NscApp extends StatelessWidget {
  final LocalStore store;
  final AuthService auth;
  const NscApp({super.key, required this.store, required this.auth});
  @override
  Widget build(BuildContext context) => MultiProvider(providers: [
        ChangeNotifierProvider<LocalStore>.value(value: store),
        Provider<AuthService>.value(value: auth),
        ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
        Provider(create: (_) => UsuarioService(store, auth)),
        Provider(create: (_) => CatalogoService(store, auth)),
        Provider(create: (_) => PagoService(store, auth)),
        Provider(create: (_) => ReciboService(store, auth)),
        Provider(create: (_) => PdfService()),
        Provider(create: (_) => WhatsappService()),
        Provider(create: (_) => NscPagoApiService()),
        ChangeNotifierProvider(
            create: (context) => PagoProvider(context.read<PagoService>())),
        ChangeNotifierProvider(
            create: (context) => ReciboProvider(context.read<ReciboService>())),
      ], child: const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().usuario;
    return MaterialApp(
        key: ValueKey(user?.id ?? 'login'),
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: user == null ? const LoginScreen() : null,
        onGenerateRoute: user == null ? null : AppRouter.generate);
  }
}
