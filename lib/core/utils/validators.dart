import 'helpers.dart';

class Validators {
  static String? requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
  static String? email(String? v) =>
      v != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
          ? null
          : 'Correo no válido';
  static String? money(String? v) => (Helpers.centimos(v ?? '') ?? 0) > 0
      ? null
      : 'Ingresa un importe positivo con hasta 2 decimales';
}
