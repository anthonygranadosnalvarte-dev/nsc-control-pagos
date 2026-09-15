import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const CustomButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.busy = false});
  @override
  Widget build(BuildContext context) => FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label));
}
