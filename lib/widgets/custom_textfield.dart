import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  const CustomTextfield(
      {super.key,
      required this.label,
      required this.controller,
      this.obscure = false,
      this.validator,
      this.keyboardType});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder())));
}
