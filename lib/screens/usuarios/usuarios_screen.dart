import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/usuario_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/local_store.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/app_shell.dart';
import '../../core/constants/app_routes.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});
  Future<void> edit(BuildContext context, [Map<String, dynamic>? row]) async {
    final service = context.read<UsuarioService>();
    final families = {
      for (final f in context.read<CatalogoService>().list('familias'))
        f['id'] as String: f['nombre'] as String
    };
    await editForm(context,
        title: row == null ? 'Crear usuario' : 'Editar usuario',
        initial: {
          ...?row,
          'activo': row?['activo'] == false ? 'no' : 'si'
        },
        fields: [
          const FieldSpec('nombre', 'Nombre'),
          const FieldSpec('email', 'Correo'),
          const FieldSpec('rol', 'Rol', options: {
            'administrador': 'Administrador',
            'secretaria': 'Secretaría',
            'padre': 'Padre de familia'
          }),
          FieldSpec('familiaId', 'Familia (obligatoria para padres)',
              options: families, optional: true),
          const FieldSpec('activo', 'Estado',
              options: {'si': 'Activo', 'no': 'Inactivo'}),
          FieldSpec(
              'password',
              row == null
                  ? 'Contraseña (mínimo 10 caracteres)'
                  : 'Nueva contraseña (vacío = conservar)',
              obscure: true,
              optional: row != null),
        ], save: (values) async {
      final v = <String, dynamic>{...values, if (row != null) 'id': row['id']};
      final pass = v.remove('password') as String;
      v['activo'] = v['activo'] == 'si';
      await service.save(v, pass);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final users = context.read<UsuarioService>().list();
    return AppShell(
        title: 'Usuarios',
        route: AppRoutes.usuarios,
        floatingActionButton: FloatingActionButton(
            onPressed: () => edit(context), child: const Icon(Icons.add)),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: users
                .map((u) => Card(
                    child: ListTile(
                        title: Text(u['nombre'] as String),
                        subtitle: Text(
                            '${u['email']} · ${u['rol']} · ${u['activo'] == true ? 'Activo' : 'Inactivo'}'),
                        trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => edit(context, u)))))
                .toList()));
  }
}
