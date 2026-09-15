import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento de evaluación en un solo dispositivo, no contabilidad productiva.
class LocalStore extends ChangeNotifier {
  static const storageKey = 'nsc_local_v1';
  final SharedPreferences? preferences;
  Map<String, dynamic> _data = empty();
  bool _busy = false;
  LocalStore(this.preferences);
  static Map<String, dynamic> empty() => {
        'schema': 1,
        'usuarios': <dynamic>[],
        'familias': <dynamic>[],
        'alumnos': <dynamic>[],
        'deudas': <dynamic>[],
        'pagos': <dynamic>[],
        'recibos': <dynamic>[],
        'auditoria': <dynamic>[],
        'secuencia': 0,
      };
  Future<void> load() async {
    final raw = preferences?.getString(storageKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['schema'] != 1)
      throw StateError('Versión de datos no compatible');
    for (final key in [
      'usuarios',
      'familias',
      'alumnos',
      'deudas',
      'pagos',
      'recibos',
      'auditoria'
    ]) {
      if (decoded[key] is! List)
        throw StateError('Datos locales dañados. No se sobrescribieron.');
    }
    _data = decoded;
  }

  List<Map<String, dynamic>> rows(String table) =>
      List<Map<String, dynamic>>.from((_data[table] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)));
  Future<T> transaction<T>(T Function(Map<String, dynamic>) change) async {
    if (_busy)
      throw StateError('Hay una operación en curso. Intenta de nuevo.');
    _busy = true;
    try {
      final copy = jsonDecode(jsonEncode(_data)) as Map<String, dynamic>;
      final result = change(copy);
      if (preferences != null &&
          !await preferences!.setString(storageKey, jsonEncode(copy))) {
        throw StateError('No se pudo guardar. La operación no fue aplicada.');
      }
      _data = copy;
      notifyListeners();
      return result;
    } finally {
      _busy = false;
    }
  }
}
