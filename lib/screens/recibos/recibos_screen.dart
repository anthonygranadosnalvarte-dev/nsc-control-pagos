import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recibo_provider.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/app_shell.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/premium_ui.dart';

class RecibosScreen extends StatelessWidget {
  const RecibosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final receipts = context.watch<ReciboProvider>().recibos.reversed.toList();
    return AppShell(
        title: 'Recibos',
        route: AppRoutes.recibos,
        body: receipts.isEmpty
            ? const Center(
                child: Text('Los recibos se crean al registrar un pago.'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: receipts
                    .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PremiumCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text('${r.numero} · ${r.alumno}'),
                            subtitle: Text(
                                '${Helpers.fecha(r.fecha)} · ${Helpers.soles(r.montoCentimos)}'),
                            onTap: () => Navigator.pushNamed(
                                context, '/detalle-recibo',
                                arguments: r.id),
                          ),
                        )))
                    .toList()));
  }
}
