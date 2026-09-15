import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/catalogo_service.dart';
import '../services/local_store.dart';
import '../services/auth_service.dart';
import '../services/pago_service.dart';
import '../core/utils/helpers.dart';
import 'app_shell.dart';
import '../core/constants/app_routes.dart';
import 'form_dialog.dart';
import 'premium_ui.dart';

class CatalogoView extends StatefulWidget {
  final String table, title;
  const CatalogoView({super.key, required this.table, required this.title});
  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  String query = '';
  Future<void> edit([Map<String, dynamic>? row]) async {
    final service = context.read<CatalogoService>();
    final families = {
      for (final f in service.list('familias'))
        f['id'] as String: f['nombre'] as String
    };
    final students = {
      for (final a in service.list('alumnos'))
        a['id'] as String: a['nombres'] as String
    };
    final fields = switch (widget.table) {
      'familias' => [
          const FieldSpec('nombre', 'Nombre de familia'),
          const FieldSpec('apoderado', 'Apoderado'),
          const FieldSpec('documento', 'Documento', optional: true),
          const FieldSpec('telefono', 'Teléfono', optional: true)
        ],
      'alumnos' => [
          const FieldSpec('nombres', 'Nombres y apellidos'),
          FieldSpec('familiaId', 'Familia', options: families),
          const FieldSpec('grado', 'Grado'),
          const FieldSpec('seccion', 'Sección')
        ],
      _ => [
          FieldSpec('alumnoId', 'Alumno', options: students),
          const FieldSpec('concepto', 'Concepto / período'),
          const FieldSpec('importe', 'Importe en soles', money: true),
          const FieldSpec('vencimiento', 'Vencimiento (AAAA-MM-DD)')
        ],
    };
    await editForm(context,
        title: row == null ? 'Nuevo registro' : 'Editar registro',
        fields: fields,
        initial: {
          ...?row,
          if (row?['montoCentimos'] != null)
            'importe': ((row!['montoCentimos'] as int) / 100).toStringAsFixed(2)
        }, save: (values) async {
      final data = <String, dynamic>{
        ...values,
        if (row != null) 'id': row['id']
      };
      if (widget.table == 'deudas') {
        data['montoCentimos'] =
            Helpers.centimos(data.remove('importe') as String)!;
      }
      await service.save(widget.table, data);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final service = context.read<CatalogoService>();
    final admin = context.read<AuthService>().usuario?.rol == 'administrador';
    final rows = service
        .list(widget.table)
        .where((r) =>
            r.values.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();
    final students = {
      for (final a in service.list('alumnos')) a['id']: a['nombres']
    };
    final families = {
      for (final f in service.list('familias')) f['id']: f['nombre']
    };
    final route = switch (widget.table) {
      'familias' => AppRoutes.familias,
      'alumnos' => AppRoutes.alumnos,
      _ => AppRoutes.deudas,
    };
    return AppShell(
        title: widget.title,
        route: route,
        floatingActionButton: admin
            ? FloatingActionButton.extended(
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'))
            : null,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextField(
                  decoration: const InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14))),
                      hintText: 'Buscar por nombre, documento o concepto'),
                  onChanged: (v) => setState(() => query = v))),
          Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No hay registros.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        final title =
                            (row['nombre'] ?? row['nombres'] ?? row['concepto'])
                                .toString();
                        final subtitle = switch (widget.table) {
                          'familias' =>
                            '${row['apoderado']} · ${row['telefono']}',
                          'alumnos' =>
                            '${row['grado']} ${row['seccion']} · ${families[row['familiaId']] ?? ''}',
                          _ =>
                            '${students[row['alumnoId']]}\nVence: ${Helpers.fecha(row['vencimiento'] as String)} · Saldo: ${Helpers.soles(context.read<PagoService>().saldo(row['id'] as String))}',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 5),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(widget.table == 'familias'
                                      ? Icons.groups_2_outlined
                                      : widget.table == 'deudas'
                                          ? Icons
                                              .account_balance_wallet_outlined
                                          : Icons.person_outline),
                                ),
                                title: Text(title),
                                subtitle: Text(subtitle),
                                isThreeLine: widget.table == 'deudas',
                                trailing: admin
                                    ? IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => edit(row))
                                    : null),
                          ),
                        );
                      }))
        ]));
  }
}
