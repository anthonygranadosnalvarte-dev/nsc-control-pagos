import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../services/catalogo_service.dart';
import '../../services/pago_service.dart';
import '../../services/nsc_pago_api_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/premium_ui.dart';

class RegistrarPagoScreen extends StatefulWidget {
  const RegistrarPagoScreen({super.key});

  @override
  State<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends State<RegistrarPagoScreen> {
  final form = GlobalKey<FormState>();
  final search = TextEditingController();
  final reference = TextEditingController();
  String? familyId;
  String method = 'Efectivo';
  bool busy = false;
  String status = '';
  String? error;
  Map<String, dynamic>? remoteReceipt;
  String? remoteReceiptError;
  final selectedDebts = <String>{};

  @override
  void dispose() {
    search.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> submit(List<Map<String, dynamic>> debts) async {
    if (selectedDebts.isEmpty) {
      setState(() => error = 'Selecciona al menos una obligación pendiente.');
      return;
    }
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      status = 'Procesando pago...';
    });
    try {
      final paymentService = context.read<PagoService>();
      String? lastPaymentId;
      final chosen = debts
          .where((debt) => selectedDebts.contains(debt['id'] as String))
          .toList();
      final idOperacionFamiliar =
          chosen.length > 1 ? _familyOperationId() : null;
      if (idOperacionFamiliar != null) {
        final catalog = context.read<CatalogoService>();
        final students = {
          for (final student in catalog.list('alumnos')) student['id']: student
        };
        final familyDetails = chosen.map((debt) {
          final student = students[debt['alumnoId']];
          final amount = paymentService.saldo(debt['id'] as String);
          return <String, dynamic>{
            'idAlumno': debt['alumnoId'],
            'alumno': student?['nombres'] ?? '',
            'categoria': 'PENSION',
            'concepto': debt['concepto'],
            'periodo': debt['vencimiento'],
            'montoTotal': (debt['montoCentimos'] as int) / 100,
            'montoPagado': amount / 100,
          };
        }).toList();
        if (mounted) setState(() => status = 'Registrando pago familiar...');
        final registered =
            await context.read<NscPagoApiService>().registrarPagoFamiliar(
                  idFamilia: familyId!,
                  idOperacion: idOperacionFamiliar,
                  monto: familyDetails.fold<int>(
                      0,
                      (sum, item) =>
                          sum + ((item['montoPagado'] as num) * 100).round()),
                  detalles: familyDetails,
                );
        lastPaymentId = registered['idOperacion'] as String;
      } else {
        for (var i = 0; i < chosen.length; i++) {
          final debt = chosen[i];
          if (mounted) {
            setState(() => status = i == 0
                ? 'Procesando pago...'
                : 'Registrando ${i + 1} de ${chosen.length} obligaciones...');
          }
          lastPaymentId = await paymentService.registrar(
            deudaId: debt['id'] as String,
            monto: paymentService.saldo(debt['id'] as String),
            metodo: method,
            referencia:
                method == 'Efectivo' ? '' : '${reference.text.trim()}-${i + 1}',
            solicitudId: idOperacionFamiliar == null
                ? Helpers.id()
                : '$idOperacionFamiliar-$i',
          );
        }
      }
      if (!mounted || lastPaymentId == null) return;
      setState(() => status = 'Generando recibo digital...');
      try {
        final apiResult = await context.read<NscPagoApiService>().generarRecibo(
            idOperacion: idOperacionFamiliar == null ? lastPaymentId : null,
            idOperacionFamiliar: idOperacionFamiliar);
        if (!mounted) return;
        setState(() {
          busy = false;
          status = '';
          remoteReceipt = apiResult;
          remoteReceiptError = null;
        });
      } catch (receiptError) {
        if (!mounted) return;
        setState(() {
          busy = false;
          status = '';
          remoteReceiptError =
              receiptError.toString().replaceFirst('Bad state: ', '');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          status = '';
          error = e.toString().replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  String _familyOperationId() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'OP-FAM-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogoService>();
    final payments = context.read<PagoService>();
    final families = catalog.list('familias');
    final students = catalog.list('alumnos');
    final allDebts = catalog
        .list('deudas')
        .where((debt) => payments.saldo(debt['id'] as String) > 0)
        .toList();
    final visibleFamilies = families
        .where((family) =>
            '${family['id']} ${family['nombre']} ${family['apoderado']}'
                .toLowerCase()
                .contains(search.text.toLowerCase()))
        .toList();
    final family = familyId == null
        ? null
        : families.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['id'] == familyId,
            orElse: () => <String, dynamic>{});
    final familyStudents =
        students.where((student) => student['familiaId'] == familyId).toList();
    final familyDebts = allDebts
        .where((debt) =>
            familyStudents.any((student) => student['id'] == debt['alumnoId']))
        .toList();
    final total = familyDebts
        .where((debt) => selectedDebts.contains(debt['id']))
        .fold<int>(
            0, (sum, debt) => sum + payments.saldo(debt['id'] as String));

    if (remoteReceipt != null || remoteReceiptError != null) {
      return AppShell(
        title: 'Recibo digital',
        route: AppRoutes.registrarPago,
        body: _RemoteReceiptResult(
          receipt: remoteReceipt,
          error: remoteReceiptError,
          onRetry: () {
            setState(() {
              remoteReceipt = null;
              remoteReceiptError = null;
            });
          },
        ),
      );
    }

    return AppShell(
      title: 'Registrar pago familiar',
      route: AppRoutes.registrarPago,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < 780) {
                      return Column(children: [
                        _FamilySection(
                            controller: search,
                            families: visibleFamilies,
                            selected: family,
                            onSearch: () => setState(() {}),
                            onSelect: (value) => setState(() {
                                  familyId = value;
                                  selectedDebts.clear();
                                })),
                        const SizedBox(height: 18),
                        _DebtsSection(
                            family: family,
                            students: familyStudents,
                            debts: familyDebts,
                            selected: selectedDebts,
                            payments: payments,
                            onToggle: (id) => setState(() {
                                  selectedDebts.contains(id)
                                      ? selectedDebts.remove(id)
                                      : selectedDebts.add(id);
                                })),
                        const SizedBox(height: 18),
                        _SummarySection(
                            students: familyStudents,
                            debts: familyDebts,
                            selected: selectedDebts,
                            total: total,
                            payments: payments),
                        const SizedBox(height: 18),
                        _PaymentSection(
                            method: method,
                            reference: reference,
                            busy: busy,
                            onMethod: (value) => setState(() => method = value),
                            onSubmit: () => submit(familyDebts)),
                      ]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 6,
                            child: Column(children: [
                              _FamilySection(
                                  controller: search,
                                  families: visibleFamilies,
                                  selected: family,
                                  onSearch: () => setState(() {}),
                                  onSelect: (value) => setState(() {
                                        familyId = value;
                                        selectedDebts.clear();
                                      })),
                              const SizedBox(height: 18),
                              _DebtsSection(
                                  family: family,
                                  students: familyStudents,
                                  debts: familyDebts,
                                  selected: selectedDebts,
                                  payments: payments,
                                  onToggle: (id) => setState(() {
                                        selectedDebts.contains(id)
                                            ? selectedDebts.remove(id)
                                            : selectedDebts.add(id);
                                      })),
                            ])),
                        const SizedBox(width: 18),
                        Expanded(
                            flex: 4,
                            child: Column(children: [
                              _SummarySection(
                                  students: familyStudents,
                                  debts: familyDebts,
                                  selected: selectedDebts,
                                  total: total,
                                  payments: payments),
                              const SizedBox(height: 18),
                              _PaymentSection(
                                  method: method,
                                  reference: reference,
                                  busy: busy,
                                  onMethod: (value) =>
                                      setState(() => method = value),
                                  onSubmit: () => submit(familyDebts)),
                            ])),
                      ],
                    );
                  }),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    _Notice(message: error!, danger: true),
                  ],
                  if (busy) ...[
                    const SizedBox(height: 14),
                    _Notice(message: status, danger: false),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrar pago familiar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
              'Gestiona pensiones y pagos de varios alumnos en un solo recibo.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted)),
        ],
      );
}

class _FamilySection extends StatelessWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> families;
  final Map<String, dynamic>? selected;
  final VoidCallback onSearch;
  final ValueChanged<String> onSelect;
  const _FamilySection(
      {required this.controller,
      required this.families,
      required this.selected,
      required this.onSearch,
      required this.onSelect});

  @override
  Widget build(BuildContext context) => PremiumCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel(
              icon: Icons.search_rounded, title: 'Buscar familia'),
          const SizedBox(height: 14),
          TextField(
              controller: controller,
              onChanged: (_) => onSearch(),
              decoration: const InputDecoration(
                  hintText: 'Nombre o código familiar',
                  prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 10),
          if (selected != null && selected!.isNotEmpty)
            _FamilyTile(family: selected!, selected: true, onTap: () {}),
          if (selected == null || selected!.isEmpty)
            ...families.take(5).map((family) => _FamilyTile(
                family: family,
                selected: false,
                onTap: () => onSelect(family['id'] as String))),
          if (families.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No encontramos familias.'))),
        ]),
      );
}

class _FamilyTile extends StatelessWidget {
  final Map<String, dynamic> family;
  final bool selected;
  final VoidCallback onTap;
  const _FamilyTile(
      {required this.family, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        color: selected
            ? AppColors.primary.withValues(alpha: .08)
            : const Color(0xFFF8F9FC),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: selected
                    ? AppColors.primary.withValues(alpha: .35)
                    : Colors.transparent)),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .12),
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.groups_2_outlined)),
          title: Text(family['nombre'] as String,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
              '${family['id']} · ${family['apoderado']} · ${family['telefono']}'),
          trailing: selected
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : const Icon(Icons.chevron_right),
        ),
      );
}

class _DebtsSection extends StatelessWidget {
  final Map<String, dynamic>? family;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> debts;
  final Set<String> selected;
  final PagoService payments;
  final ValueChanged<String> onToggle;
  const _DebtsSection(
      {required this.family,
      required this.students,
      required this.debts,
      required this.selected,
      required this.payments,
      required this.onToggle});

  @override
  Widget build(BuildContext context) => PremiumCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Alumnos y obligaciones pendientes'),
          const SizedBox(height: 12),
          if (family == null)
            const _EmptyState(
                icon: Icons.family_restroom_outlined,
                text: 'Selecciona una familia para ver sus obligaciones.')
          else if (debts.isEmpty)
            const _EmptyState(
                icon: Icons.check_circle_outline,
                text: 'Esta familia no tiene obligaciones pendientes.')
          else
            ...students.map((student) {
              final studentDebts = debts
                  .where((debt) => debt['alumnoId'] == student['id'])
                  .toList();
              if (studentDebts.isEmpty) return const SizedBox.shrink();
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE9EEFF),
                          foregroundColor: AppColors.primary,
                          child: Icon(Icons.person_outline)),
                      title: Text(student['nombres'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle:
                          Text('${student['grado']} ${student['seccion']}'),
                    ),
                    ...studentDebts.map((debt) {
                      final id = debt['id'] as String;
                      final isSelected = selected.contains(id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => onToggle(id),
                        contentPadding: const EdgeInsets.only(left: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: Text(debt['concepto'] as String),
                        subtitle: Text(
                            'Vence ${Helpers.fecha(debt['vencimiento'] as String)}'),
                        secondary: Text(Helpers.soles(payments.saldo(id)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ]);
            }),
        ]),
      );
}

class _SummarySection extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> debts;
  final Set<String> selected;
  final int total;
  final PagoService payments;
  const _SummarySection(
      {required this.students,
      required this.debts,
      required this.selected,
      required this.total,
      required this.payments});

  @override
  Widget build(BuildContext context) {
    final selectedStudents = debts
        .where((debt) => selected.contains(debt['id']))
        .map((debt) => debt['alumnoId'])
        .toSet()
        .length;
    return PremiumCard(
      color: AppColors.navy,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RESUMEN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4)),
        const SizedBox(height: 18),
        _SummaryLine(
            label: 'Alumnos seleccionados', value: '$selectedStudents'),
        _SummaryLine(label: 'Conceptos', value: '${selected.length}'),
        const Divider(color: Colors.white24, height: 28),
        const Text('TOTAL A PAGAR',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(Helpers.soles(total),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: Colors.white70))),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _PaymentSection extends StatelessWidget {
  final String method;
  final TextEditingController reference;
  final bool busy;
  final ValueChanged<String> onMethod;
  final VoidCallback onSubmit;
  const _PaymentSection(
      {required this.method,
      required this.reference,
      required this.busy,
      required this.onMethod,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    const methods = {
      'Efectivo': Icons.payments_outlined,
      'Yape': Icons.phone_android_outlined,
      'Plin': Icons.phone_android_outlined,
      'Transferencia': Icons.account_balance_outlined,
      'Tarjeta': Icons.credit_card_outlined,
    };
    return PremiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel(
            icon: Icons.credit_card_outlined, title: 'Método de pago'),
        const SizedBox(height: 14),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methods.entries
                .map((entry) => ChoiceChip(
                    selected: method == entry.key,
                    avatar: Icon(entry.value, size: 17),
                    label: Text(entry.key),
                    onSelected: busy ? null : (_) => onMethod(entry.key)))
                .toList()),
        const SizedBox(height: 18),
        if (method != 'Efectivo')
          CustomTextfield(
              label: 'Número de operación',
              controller: reference,
              validator: Validators.requiredField),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.receipt_long_outlined),
              label: Text(busy ? 'Procesando...' : 'GENERAR RECIBO')),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 9),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
      ]);
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: AppColors.muted, size: 32),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
        ]),
      );
}

class _Notice extends StatelessWidget {
  final String message;
  final bool danger;
  const _Notice({required this.message, required this.danger});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: (danger ? AppColors.danger : AppColors.primary)
                .withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14)),
        child: Text(message,
            style: TextStyle(
                color: danger ? AppColors.danger : AppColors.primary,
                fontWeight: FontWeight.w700)),
      );
}

class _RemoteReceiptResult extends StatelessWidget {
  final Map<String, dynamic>? receipt;
  final String? error;
  final VoidCallback onRetry;

  const _RemoteReceiptResult(
      {required this.receipt, required this.error, required this.onRetry});

  Future<void> _open(BuildContext context, String url) async {
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF del recibo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = receipt == null;
    final number = receipt?['numeroRecibo']?.toString() ?? '';
    final pdf = receipt?['pdf']?.toString() ?? '';
    final total = receipt?['total'];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: PremiumCard(
            child: Column(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor:
                    (failed ? AppColors.warning : AppColors.success)
                        .withValues(alpha: .12),
                foregroundColor: failed ? AppColors.warning : AppColors.success,
                child: Icon(
                    failed ? Icons.receipt_long_outlined : Icons.check_rounded,
                    size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                  failed
                      ? 'Pago registrado correctamente'
                      : 'Pago registrado correctamente',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                failed
                    ? 'Pero no se pudo generar el recibo digital. Puede intentarlo nuevamente.'
                    : 'Recibo profesional generado y guardado en Google Drive.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              if (!failed) ...[
                const SizedBox(height: 24),
                _ResultLine(label: 'Recibo generado', value: number),
                _ResultLine(
                    label: 'Total',
                    value: total is num
                        ? 'S/ ${total.toStringAsFixed(2)}'
                        : total?.toString() ?? '—'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: () => _open(context, pdf),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ver recibo PDF')),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: () => _open(context, pdf),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Compartir')),
                ),
              ] else ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Intentar nuevamente')),
                ),
                const SizedBox(height: 12),
                Text(error ?? 'Error desconocido',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;
  const _ResultLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w800)),
        ]),
      );
}
