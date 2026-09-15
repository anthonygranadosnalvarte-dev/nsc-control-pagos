import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/constants/app_routes.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/usuarios/usuarios_screen.dart';
import '../screens/familias/familias_screen.dart';
import '../screens/alumnos/alumnos_screen.dart';
import '../screens/deudas/deudas_screen.dart';
import '../screens/pagos/registrar_pago_screen.dart';
import '../screens/pagos/historial_pagos_screen.dart';
import '../screens/recibos/recibos_screen.dart';
import '../screens/recibos/detalle_recibo_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/auditoria/auditoria_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) => MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final role = context.read<AuthService>().usuario?.rol;
        final allowed = switch (settings.name) {
          AppRoutes.usuarios ||
          AppRoutes.reportes ||
          AppRoutes.auditoria =>
            role == 'administrador',
          AppRoutes.registrarPago =>
            role == 'administrador' || role == 'secretaria',
          AppRoutes.familias ||
          AppRoutes.alumnos =>
            role == 'administrador' || role == 'padre',
          _ => role != null,
        };
        if (!allowed)
          return Scaffold(
              appBar: AppBar(title: const Text('Acceso restringido')),
              body: const Center(
                  child: Text('Tu perfil no tiene acceso a este módulo.')));
        return switch (settings.name) {
          AppRoutes.home => const HomeScreen(),
          AppRoutes.usuarios => const UsuariosScreen(),
          AppRoutes.familias => const FamiliasScreen(),
          AppRoutes.alumnos => const AlumnosScreen(),
          AppRoutes.deudas => const DeudasScreen(),
          AppRoutes.registrarPago => const RegistrarPagoScreen(),
          AppRoutes.historialPagos => const HistorialPagosScreen(),
          AppRoutes.recibos => const RecibosScreen(),
          AppRoutes.detalleRecibo => settings.arguments is String
              ? DetalleReciboScreen(reciboId: settings.arguments as String)
              : const Scaffold(
                  body: Center(child: Text('Selecciona un recibo.'))),
          AppRoutes.reportes => const ReportesScreen(),
          AppRoutes.auditoria => const AuditoriaScreen(),
          _ =>
            const Scaffold(body: Center(child: Text('Página no encontrada'))),
        };
      });
}
