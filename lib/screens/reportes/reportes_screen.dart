import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../models/pago_model.dart';
import '../../services/catalogo_service.dart';
import '../../services/local_store.dart';
import '../../services/pago_service.dart';
import '../../services/recibo_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/premium_ui.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTimeRange? range;

  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final paymentService = context.read<PagoService>();
    final catalog = context.read<CatalogoService>();
    final payments = paymentService.list();
    final now = DateTime.now();
    final active = payments.where((payment) {
      if (payment.anulado) return false;
      final date = DateTime.parse(payment.fecha).toLocal();
      return range == null ||
          (!date.isBefore(range!.start) &&
              date.isBefore(range!.end.add(const Duration(days: 1))));
    }).toList();
    final income = active.fold<int>(0, (sum, p) => sum + p.montoCentimos);
    final previousIncome = _previousPeriodIncome(payments, now);
    final debts = catalog.list('deudas');
    final overdue = debts.where((debt) {
      final dueDate = DateTime.parse(debt['vencimiento'] as String);
      return dueDate.isBefore(DateTime(now.year, now.month, now.day)) &&
          paymentService.saldo(debt['id'] as String) > 0;
    }).toList();
    final overdueTotal = overdue.fold<int>(
        0, (sum, debt) => sum + paymentService.saldo(debt['id'] as String));
    final students = {
      for (final student in catalog.list('alumnos'))
        student['id']: student['nombres']
    };
    final receipts = context.read<ReciboService>().list();
    final audit =
        context.read<LocalStore>().rows('auditoria').reversed.toList();
    final users = {
      for (final user in context.read<LocalStore>().rows('usuarios'))
        user['id']: user['nombre']
    };
    final Map<String, dynamic> receiptsByPayment = {
      for (final receipt in receipts) receipt.pagoId: receipt
    };

    return AppShell(
      title: 'Centro financiero',
      route: AppRoutes.reportes,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    range: range,
                    onPick: _pickRange,
                    onClear: () => setState(() => range = null),
                    onRegister: () =>
                        Navigator.pushNamed(context, AppRoutes.registrarPago),
                    onExport: () => _exportReport(active),
                    onReceipt: () =>
                        Navigator.pushNamed(context, AppRoutes.recibos),
                    onReminders: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                            content: Text(
                                'Recordatorios listos para enviar a las familias pendientes'))),
                  ),
                  const SizedBox(height: 24),
                  _Metrics(
                    income: income,
                    previousIncome: previousIncome,
                    payments: active.length,
                    overdue: overdueTotal,
                    families: catalog.list('familias').length,
                    receipts: receipts.length,
                  ),
                  const SizedBox(height: 20),
                  _MonthlyIncomeChart(payments: active, now: now),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final methods = _PaymentMethods(payments: active);
                      final debt = _OverdueCard(
                          debts: overdue,
                          students: students,
                          service: paymentService,
                          total: overdueTotal);
                      if (constraints.maxWidth < 760) {
                        return Column(children: [
                          methods,
                          const SizedBox(height: 16),
                          debt,
                        ]);
                      }
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: methods),
                            const SizedBox(width: 16),
                            Expanded(child: debt),
                          ]);
                    },
                  ),
                  const SizedBox(height: 20),
                  _RecentActivity(
                      rows: audit,
                      users: users,
                      payments: payments,
                      receiptsByPayment: receiptsByPayment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _previousPeriodIncome(List<PagoModel> payments, DateTime now) {
    if (range != null) {
      final duration = range!.end.difference(range!.start).inDays + 1;
      final previousEnd =
          DateTime(range!.start.year, range!.start.month, range!.start.day - 1);
      final previousStart = previousEnd.subtract(Duration(days: duration - 1));
      return payments.where((p) {
        if (p.anulado) return false;
        final date = DateTime.parse(p.fecha).toLocal();
        return !date.isBefore(previousStart) && !date.isAfter(previousEnd);
      }).fold<int>(0, (sum, p) => sum + p.montoCentimos);
    }
    final previousMonth = DateTime(now.year, now.month - 1);
    return payments.where((p) {
      if (p.anulado) return false;
      final date = DateTime.parse(p.fecha).toLocal();
      return date.year == previousMonth.year &&
          date.month == previousMonth.month;
    }).fold<int>(0, (sum, p) => sum + p.montoCentimos);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: range);
    if (selected != null && mounted) setState(() => range = selected);
  }

  void _exportReport(List<PagoModel> payments) {
    final lines = <String>[
      'Fecha,Importe,Medio de pago,Referencia',
      ...payments.map((p) =>
          '${Helpers.fecha(p.fecha)},${Helpers.soles(p.montoCentimos)},${p.metodo},${p.referencia}'),
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reporte copiado al portapapeles en formato CSV')));
  }
}

class _Header extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback onRegister;
  final VoidCallback onExport;
  final VoidCallback onReceipt;
  final VoidCallback onReminders;

  const _Header(
      {required this.range,
      required this.onPick,
      required this.onClear,
      required this.onRegister,
      required this.onExport,
      required this.onReceipt,
      required this.onReminders});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Centro financiero',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                  'Panel ejecutivo de pagos, ingresos y seguimiento de familias.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.muted)),
            ],
          );
          final filters = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(range == null
                        ? 'Este período'
                        : '${Helpers.fecha(range!.start.toIso8601String())} - ${Helpers.fecha(range!.end.toIso8601String())}')),
                if (range != null)
                  IconButton(
                      tooltip: 'Quitar filtro',
                      onPressed: onClear,
                      icon: const Icon(Icons.close)),
              ]);
          final actions = Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Registrar pago')),
            OutlinedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exportar reporte')),
            OutlinedButton.icon(
                onPressed: onReceipt,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Generar recibo')),
            OutlinedButton.icon(
                onPressed: onReminders,
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Enviar recordatorios')),
          ]);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                constraints.maxWidth < 760
                    ? title
                    : Row(children: [Expanded(child: title), filters]),
                if (constraints.maxWidth < 760) ...[
                  const SizedBox(height: 12),
                  filters,
                ],
                const SizedBox(height: 14),
                actions,
              ]);
        },
      );
}

class _Metrics extends StatelessWidget {
  final int income;
  final int previousIncome;
  final int payments;
  final int overdue;
  final int families;
  final int receipts;

  const _Metrics(
      {required this.income,
      required this.previousIncome,
      required this.payments,
      required this.overdue,
      required this.families,
      required this.receipts});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 5
              : constraints.maxWidth >= 560
                  ? 3
                  : 2;
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 5 ? 1.35 : 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _IncomeMetric(current: income, previous: previousIncome),
              PremiumMetric(
                  label: 'Pagos registrados',
                  value: '$payments',
                  icon: Icons.payments_outlined,
                  accent: AppColors.primary),
              PremiumMetric(
                  label: 'Morosidad pendiente',
                  value: Helpers.soles(overdue),
                  icon: Icons.warning_amber_rounded,
                  accent: AppColors.danger),
              PremiumMetric(
                  label: 'Familias activas',
                  value: '$families',
                  icon: Icons.groups_2_outlined,
                  accent: AppColors.navy),
              PremiumMetric(
                  label: 'Recibos emitidos',
                  value: '$receipts',
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFF8B5CF6)),
            ],
          );
        },
      );
}

class _IncomeMetric extends StatelessWidget {
  final int current;
  final int previous;
  const _IncomeMetric({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final growth = previous == 0
        ? (current > 0 ? 100.0 : 0.0)
        : ((current - previous) / previous) * 100;
    final positive = growth >= 0;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.success.withValues(alpha: .12),
              foregroundColor: AppColors.success,
              child: const Icon(Icons.trending_up_rounded, size: 20)),
          const Spacer(),
          Icon(
              positive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 17,
              color: positive ? AppColors.success : AppColors.danger),
        ]),
        const SizedBox(height: 12),
        Text('Ingresos del periodo',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(Helpers.soles(current),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            '${positive ? '↑' : '↓'} ${growth.abs().toStringAsFixed(0)}% respecto al periodo anterior',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: positive ? AppColors.success : AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MonthlyIncomeChart extends StatelessWidget {
  final List<PagoModel> payments;
  final DateTime now;
  const _MonthlyIncomeChart({required this.payments, required this.now});

  @override
  Widget build(BuildContext context) {
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - 5 + index);
      return DateTime(date.year, date.month);
    });
    final values = months.map((month) {
      return payments.where((p) {
        final date = DateTime.parse(p.fecha).toLocal();
        return date.year == month.year && date.month == month.month;
      }).fold<int>(0, (sum, p) => sum + p.montoCentimos);
    }).toList();
    final maxValue =
        values.fold<int>(0, (max, value) => value > max ? value : max);
    return PremiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ingresos mensuales',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Evolución de cobranza con pagos vigentes.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 18),
        if (maxValue == 0)
          const SizedBox(
              height: 190,
              child: Center(
                  child: Text('Sin movimientos registrados en este periodo',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600))))
        else ...[
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
                painter: _ChartPainter(values: values, maxValue: maxValue)),
          ),
          const SizedBox(height: 4),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: months
                  .map((month) => Text(_monthLabel(month),
                      style: Theme.of(context).textTheme.labelSmall))
                  .toList()),
        ],
      ]),
    );
  }

  String _monthLabel(DateTime date) => const [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ][date.month - 1];
}

class _ChartPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  const _ChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE9ECF3)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 12 + (size.height - 28) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = <Offset>[];
    final step =
        values.length == 1 ? size.width : size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final ratio = maxValue == 0 ? 0.0 : values[i] / maxValue;
      points
          .add(Offset(step * i, size.height - 20 - ratio * (size.height - 42)));
    }
    if (points.isEmpty) return;
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final area = Path()..moveTo(points.first.dx, size.height - 20);
    area.lineTo(points.first.dx, points.first.dy);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      area.lineTo(points[i].dx, points[i].dy);
    }
    area
      ..lineTo(points.last.dx, size.height - 20)
      ..close();
    canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0x40635BFF), Color(0x00635BFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(Offset.zero & size));
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.primary;
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}

class _PaymentMethods extends StatelessWidget {
  final List<PagoModel> payments;
  const _PaymentMethods({required this.payments});

  @override
  Widget build(BuildContext context) {
    const methods = ['Efectivo', 'Transferencia', 'Yape', 'Plin', 'Tarjeta'];
    final total = payments.fold<int>(0, (sum, p) => sum + p.montoCentimos);
    return PremiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Medios de pago',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Distribución de ingresos cobrados',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 18),
        for (final method in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _MethodRow(
                method: method,
                amount: payments
                    .where((p) => p.metodo == method)
                    .fold<int>(0, (sum, p) => sum + p.montoCentimos),
                total: total),
          ),
      ]),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final String method;
  final int amount;
  final int total;
  const _MethodRow(
      {required this.method, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : amount / total;
    return Column(children: [
      Row(children: [
        Expanded(child: Text(method)),
        Text(Helpers.soles(amount),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        SizedBox(
            width: 42,
            child: Text('${(ratio * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDEFF5),
            color: AppColors.primary),
      ),
    ]);
  }
}

class _OverdueCard extends StatelessWidget {
  final List<Map<String, dynamic>> debts;
  final Map<dynamic, dynamic> students;
  final PagoService service;
  final int total;
  const _OverdueCard(
      {required this.debts,
      required this.students,
      required this.service,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final families = debts.map((d) => d['alumnoId']).toSet().length;
    return PremiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Morosidad pendiente',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800))),
          Text(Helpers.soles(total),
              style: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('$families familias pendientes · ${debts.length} obligaciones',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _DebtSummary(
                  label: 'Familias pendientes', value: '$families')),
          const SizedBox(width: 12),
          Expanded(
              child: _DebtSummary(
                  label: 'Monto total', value: Helpers.soles(total))),
        ]),
        const SizedBox(height: 12),
        if (debts.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child:
                  Center(child: Text('Todo al día. No hay deudas vencidas.')))
        else
          ...debts.take(5).map((debt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE8EA),
                    foregroundColor: AppColors.danger,
                    child: Icon(Icons.schedule_outlined)),
                title: Text('${students[debt['alumnoId']]}'),
                subtitle: Text(
                    '${debt['concepto']} · Venció ${Helpers.fecha(debt['vencimiento'] as String)}'),
                trailing: Text(
                    Helpers.soles(service.saldo(debt['id'] as String)),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
      ]),
    );
  }
}

class _DebtSummary extends StatelessWidget {
  final String label;
  final String value;
  const _DebtSummary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _RecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Map<dynamic, dynamic> users;
  final List<PagoModel> payments;
  final Map<String, dynamic> receiptsByPayment;
  const _RecentActivity(
      {required this.rows,
      required this.users,
      required this.payments,
      required this.receiptsByPayment});

  @override
  Widget build(BuildContext context) => PremiumCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Actividad reciente',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Últimos movimientos registrados en el sistema.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aún no hay actividad registrada.'))
          else
            ...rows.take(5).map((row) => _activityTile(context, row)),
        ]),
      );

  Widget _activityTile(BuildContext context, Map<String, dynamic> row) {
    final action = row['accion'] as String;
    PagoModel? payment;
    for (final candidate in payments) {
      if ((row['detalle'] as String).contains(candidate.id)) {
        payment = candidate;
        break;
      }
    }
    final user = users[row['usuarioId']] ?? row['usuarioId'];
    final title = action == 'PAGO' ? 'REGISTRO DE PAGO' : action;
    final detail = payment == null
        ? row['detalle'] as String
        : '${payment.metodo} · ${Helpers.soles(payment.montoCentimos)}'
            '${receiptsByPayment[payment.id] == null ? '' : ' · Recibo emitido'}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: .10),
          foregroundColor: AppColors.primary,
          child: Icon(_icon(action))),
      title: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      subtitle:
          Text('$user · $detail', maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(Helpers.fecha(row['fecha'] as String),
          style: Theme.of(context).textTheme.labelSmall),
    );
  }

  IconData _icon(String action) {
    if (action.contains('PAGO')) return Icons.payments_outlined;
    if (action.contains('LOGIN')) return Icons.login_outlined;
    if (action.contains('ANULAR')) return Icons.undo_outlined;
    return Icons.history_outlined;
  }
}
