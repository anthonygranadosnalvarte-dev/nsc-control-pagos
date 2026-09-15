import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/local_store.dart';
import '../../services/catalogo_service.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/app_shell.dart';
import '../../core/constants/app_routes.dart';

class AuditoriaScreen extends StatelessWidget {
  const AuditoriaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final rows =
        context.read<CatalogoService>().list('auditoria').reversed.toList();
    return AppShell(
        title: 'Auditoría',
        route: AppRoutes.auditoria,
        body: ListView(
            padding: const EdgeInsets.all(16),
            children: rows
                .map((r) => Card(
                    child: ListTile(
                        title: Text('${r['accion']} · ${r['usuarioId']}'),
                        subtitle: Text(
                            '${Helpers.fecha(r['fecha'] as String)} ${DateTime.parse(r['fecha'] as String).toLocal().toString().substring(11, 19)}\n${r['detalle']}'),
                        isThreeLine: true)))
                .toList()));
  }
}
