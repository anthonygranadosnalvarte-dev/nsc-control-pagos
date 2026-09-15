import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pago_provider.dart';
import '../../services/recibo_service.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/app_shell.dart';
import '../../core/constants/app_routes.dart';

class HistorialPagosScreen extends StatelessWidget {
  const HistorialPagosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pagos = context.watch<PagoProvider>().pagos.reversed.toList();
    final receipts = context.read<ReciboService>().list();
    return AppShell(
        title: 'Historial de pagos',
        route: AppRoutes.historialPagos,
        body: pagos.isEmpty
            ? const Center(child: Text('Todavía no hay pagos.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: pagos.map((p) {
                  final r = receipts.firstWhere((r) => r.pagoId == p.id);
                  return Card(
                      child: ListTile(
                          leading: Icon(
                              p.anulado ? Icons.cancel : Icons.check_circle,
                              color: p.anulado ? Colors.red : Colors.green),
                          title: Text(
                              '${r.alumno} · ${Helpers.soles(p.montoCentimos)}'),
                          subtitle: Text(
                              '${r.numero} · ${Helpers.fecha(p.fecha)} · ${p.metodo}\n${p.anulado ? 'ANULADO: ${p.motivoAnulacion}' : r.concepto}'),
                          isThreeLine: true,
                          onTap: () => Navigator.pushNamed(
                              context, '/detalle-recibo',
                              arguments: r.id)));
                }).toList()));
  }
}
