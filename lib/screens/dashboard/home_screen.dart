import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../models/pago_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/catalogo_service.dart';
import '../../services/local_store.dart';
import '../../services/pago_service.dart';
import '../../widgets/app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final user = context.watch<AuthProvider>().usuario!;
    final paymentsService = context.read<PagoService>();
    final catalog = context.read<CatalogoService>();
    final payments = paymentsService.list();
    final debts = catalog.list('deudas');
    final today = DateTime.now();
    final todayPayments = payments
        .where((p) => _sameDay(DateTime.parse(p.fecha).toLocal(), today))
        .toList();
    final validToday = todayPayments.where((p) => !p.anulado).toList();
    final income = validToday.fold<int>(0, (sum, p) => sum + p.montoCentimos);
    final pending = debts.fold<int>(
        0, (sum, debt) => sum + paymentsService.saldo(debt['id'] as String));
    final recent = [...payments]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return AppShell(
      title: 'Panel principal',
      route: AppRoutes.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Welcome(user: user, date: today),
                const SizedBox(height: 24),
                _SummaryGrid(
                  payments: validToday.length,
                  income: user.rol == 'padre' ? null : income,
                  pending: pending,
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Últimos pagos',
                  action: recent.isEmpty
                      ? null
                      : () => Navigator.pushNamed(
                          context, AppRoutes.historialPagos),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: recent.isEmpty
                      ? _EmptyState(
                          role: user.rol,
                          onAction: user.rol == 'padre'
                              ? null
                              : () => Navigator.pushNamed(
                                  context, AppRoutes.registrarPago),
                        )
                      : _RecentPayments(
                          payments: recent.take(5).toList(),
                          catalog: catalog,
                        ),
                ),
                const SizedBox(height: 28),
                const _SectionTitle(title: 'Accesos rápidos'),
                const SizedBox(height: 10),
                _QuickAccess(role: user.rol),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Welcome extends StatelessWidget {
  final dynamic user;
  final DateTime date;
  const _Welcome({required this.user, required this.date});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF123B73), fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Usuario: ${user.nombre}',
              style: const TextStyle(
                  color: Color(0xFF334155), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Rol: ${_roleLabel(user.rol)} · ${_weekday(date.weekday)}, '
            '${date.day} de ${_month(date.month)} de ${date.year}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      );

  String _roleLabel(String role) => switch (role) {
        'administrador' => 'Administrador',
        'secretaria' => 'Secretaría',
        'padre' => 'Padre',
        _ => role,
      };
}

String _weekday(int value) => const [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ][value - 1];

String _month(int value) => const [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ][value - 1];

class _SummaryGrid extends StatelessWidget {
  final int payments;
  final int? income;
  final int pending;
  const _SummaryGrid(
      {required this.payments, required this.income, required this.pending});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 4.2 : 3.4,
            children: [
              _MetricCard('Pagos de hoy', '$payments', Icons.payments_outlined,
                  const Color(0xFF1557B0)),
              if (income != null)
                _MetricCard('Ingresos de hoy', Helpers.soles(income!),
                    Icons.trending_up, const Color(0xFF16794A)),
              _MetricCard(
                  'Saldo pendiente',
                  Helpers.soles(pending),
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF9A5A00)),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF123B73))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? action;
  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Ver historial')),
        ],
      );
}

class _RecentPayments extends StatelessWidget {
  final List<PagoModel> payments;
  final CatalogoService catalog;
  const _RecentPayments({required this.payments, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final students = {
      for (final row in catalog.list('alumnos'))
        row['id'] as String: row['nombres']
    };
    return Card(
      child: Column(
        children: payments
            .map((payment) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: payment.anulado
                        ? const Color(0xFFFFE8E6)
                        : const Color(0xFFE8F0FF),
                    child: Icon(
                      payment.anulado ? Icons.block : Icons.check,
                      color: payment.anulado
                          ? const Color(0xFFB3261E)
                          : const Color(0xFF1557B0),
                    ),
                  ),
                  title: Text(students[payment.alumnoId] ?? 'Alumno'),
                  subtitle: Text(
                      '${Helpers.fecha(payment.fecha)} · ${payment.anulado ? 'ANULADO' : 'Vigente'}'),
                  trailing: Text(Helpers.soles(payment.montoCentimos),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ))
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String role;
  final VoidCallback? onAction;
  const _EmptyState({required this.role, required this.onAction});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 40, color: Color(0xFF64748B)),
              const SizedBox(height: 8),
              const Text('No hay movimientos registrados todavía.'),
              if (onAction != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_card),
                  label: const Text('Registrar pago'),
                ),
              ],
            ],
          ),
        ),
      );
}

class _QuickAccess extends StatelessWidget {
  final String role;
  const _QuickAccess({required this.role});

  @override
  Widget build(BuildContext context) {
    final entries = <({String title, IconData icon, String route})>[
      if (role != 'padre')
        (
          title: 'Registrar pago',
          icon: Icons.add_card_outlined,
          route: AppRoutes.registrarPago
        ),
      (
        title: role == 'padre' ? 'Mis deudas' : 'Deudas',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.deudas
      ),
      (
        title: role == 'padre' ? 'Mis recibos' : 'Recibos',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.recibos
      ),
      (
        title: role == 'padre' ? 'Mis pagos' : 'Historial',
        icon: Icons.history,
        route: AppRoutes.historialPagos
      ),
      if (role == 'administrador')
        (
          title: 'Reportes',
          icon: Icons.bar_chart_outlined,
          route: AppRoutes.reportes
        ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries
          .map((entry) => SizedBox(
                width: 210,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, entry.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(entry.icon, color: const Color(0xFF1557B0)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.title)),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
