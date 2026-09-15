import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../services/recibo_service.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/pago_service.dart';
import '../../services/auth_service.dart';
import '../../services/local_store.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/app_shell.dart';
import '../../core/constants/app_routes.dart';

class DetalleReciboScreen extends StatelessWidget {
  final String reciboId;
  const DetalleReciboScreen({super.key, required this.reciboId});
  Future<void> action(BuildContext context, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocalStore>();
    final service = context.read<ReciboService>();
    final r = service.get(reciboId);
    final cancelled = service.anulado(reciboId);
    return AppShell(
        title: r.numero,
        route: AppRoutes.recibos,
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Text('${r.alumno} · ${Helpers.soles(r.montoCentimos)}',
                    style: Theme.of(context).textTheme.titleLarge),
                if (cancelled)
                  const Text('ANULADO',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Compartir PDF'),
                          onPressed: () => action(context, () async {
                                final bytes = await context
                                    .read<PdfService>()
                                    .generar(r,
                                        anulado: service.anulado(reciboId));
                                await Printing.sharePdf(
                                    bytes: bytes, filename: '${r.numero}.pdf');
                              })),
                      OutlinedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('Resumen por WhatsApp'),
                          onPressed: () => action(
                              context,
                              () => context
                                  .read<WhatsappService>()
                                  .compartirResumen(
                                      r, service.anulado(reciboId)))),
                      if (!cancelled &&
                          context.read<AuthService>().usuario?.rol ==
                              'administrador')
                        TextButton(
                            onPressed: () async {
                              final payments = context.read<PagoService>();
                              await editForm(context,
                                  title: 'Anular pago y restituir saldo',
                                  fields: const [
                                    FieldSpec('motivo', 'Motivo de anulación')
                                  ],
                                  save: (v) =>
                                      payments.anular(r.pagoId, v['motivo']!));
                            },
                            child: const Text('Anular pago')),
                    ]),
                const Text(
                    'WhatsApp abre un resumen de texto. Para adjuntar el archivo utiliza Compartir PDF. En la vista PDF puedes imprimir o guardar según tu plataforma.',
                    textAlign: TextAlign.center),
              ])),
          Expanded(
              child: PdfPreview(
                  key: ValueKey('$reciboId-$cancelled'),
                  build: (_) => context.read<PdfService>().generar(
                      service.get(reciboId),
                      anulado: service.anulado(reciboId)),
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  pdfFileName: '${r.numero}.pdf')),
        ]));
  }
}
