import 'package:flutter/material.dart';
import 'custom_textfield.dart';
import 'custom_button.dart';
import '../core/utils/validators.dart';

class FieldSpec {
  final String keyName, label;
  final Map<String, String>? options;
  final bool optional, obscure, money;
  const FieldSpec(this.keyName, this.label,
      {this.options,
      this.optional = false,
      this.obscure = false,
      this.money = false});
}

Future<bool?> editForm(BuildContext context,
        {required String title,
        required List<FieldSpec> fields,
        Map<String, dynamic> initial = const {},
        required Future<void> Function(Map<String, String>) save}) =>
    showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FormDialog(
            title: title, fields: fields, initial: initial, save: save));

class _FormDialog extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, String>) save;
  const _FormDialog(
      {required this.title,
      required this.fields,
      required this.initial,
      required this.save});
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    controllers = {
      for (final f in widget.fields)
        f.keyName: TextEditingController(
            text: widget.initial[f.keyName]?.toString() ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!key.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.save(
          {for (final e in controllers.entries) e.key: e.value.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString().replaceFirst('Bad state: ', '');
          busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                  child: Form(
                      key: key,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final f in widget.fields)
                          if (f.options != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: DropdownButtonFormField<String>(
                                    value: f.options!.containsKey(controllers[f.keyName]!.text)
                                        ? controllers[f.keyName]!.text
                                        : null,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                        labelText: f.label,
                                        border: const OutlineInputBorder()),
                                    items: f.options!.entries
                                        .map((e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: busy
                                        ? null
                                        : (v) => controllers[f.keyName]!.text =
                                            v ?? '',
                                    validator: f.optional
                                        ? null
                                        : Validators.requiredField))
                          else
                            CustomTextfield(
                                label: f.label,
                                controller: controllers[f.keyName]!,
                                obscure: f.obscure,
                                keyboardType: f.money ? const TextInputType.numberWithOptions(decimal: true) : null,
                                validator: f.money ? Validators.money : (f.optional ? null : Validators.requiredField)),
                        if (error != null)
                          Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                      ])))),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            CustomButton(label: 'Guardar', onPressed: submit, busy: busy)
          ]);
}
