import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String selectedRoute;
  final bool embedded;

  const AppDrawer({
    super.key,
    this.selectedRoute = AppRoutes.home,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.usuario!;
    final content = Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _Header(user: user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text('GESTIÓN FINANCIERA',
                        style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                  ),
                  _item(context, 'Panel principal', Icons.dashboard_outlined,
                      AppRoutes.home),
                  if (user.rol == 'administrador')
                    _item(context, 'Usuarios', Icons.manage_accounts_outlined,
                        AppRoutes.usuarios),
                  if (user.rol == 'administrador' || user.rol == 'padre')
                    _item(
                        context,
                        user.rol == 'padre' ? 'Mis hijos' : 'Familias',
                        Icons.family_restroom_outlined,
                        AppRoutes.familias),
                  if (user.rol == 'administrador' || user.rol == 'padre')
                    _item(
                        context,
                        user.rol == 'padre' ? 'Mis alumnos' : 'Alumnos',
                        Icons.school_outlined,
                        AppRoutes.alumnos),
                  _item(context, user.rol == 'padre' ? 'Mis deudas' : 'Deudas',
                      Icons.account_balance_wallet_outlined, AppRoutes.deudas),
                  if (user.rol != 'padre')
                    _item(context, 'Registrar pago', Icons.add_card_outlined,
                        AppRoutes.registrarPago),
                  _item(
                      context,
                      user.rol == 'padre' ? 'Mis pagos' : 'Historial',
                      Icons.history,
                      AppRoutes.historialPagos),
                  _item(
                      context,
                      user.rol == 'padre' ? 'Mis recibos' : 'Recibos',
                      Icons.receipt_long_outlined,
                      AppRoutes.recibos),
                  if (user.rol == 'administrador') ...[
                    _item(context, 'Reportes', Icons.bar_chart_outlined,
                        AppRoutes.reportes),
                    _item(context, 'Auditoría', Icons.policy_outlined,
                        AppRoutes.auditoria),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Edición local de evaluación\nSesiones de 30 minutos',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
    return embedded ? content : Drawer(child: content);
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final active = route == selectedRoute;
    return ListTile(
      selected: active,
      selectedTileColor: const Color(0xFFE8F0FF),
      selectedColor: const Color(0xFF1557B0),
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (active) {
          if (!embedded) Navigator.pop(context);
          return;
        }
        if (!embedded) Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: const Color(0xFF123B73),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_nsc.png',
            width: 46,
            height: 54,
            fit: BoxFit.contain,
            semanticLabel: 'Escudo de Nuestra Señora del Carmen',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NSC Control Pagos',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(user.nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(user.rol,
                    style: const TextStyle(color: Color(0xFFDCE9FB))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
