import 'dart:math';

class Helpers {
  static String id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff)}';
  static String soles(int centimos) =>
      'S/ ${(centimos / 100).toStringAsFixed(2)}';
  static String fecha(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static int? centimos(String text) {
    final s = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(s)) return null;
    final p = s.split('.');
    return int.parse(p[0]) * 100 +
        (p.length == 2 ? int.parse(p[1].padRight(2, '0')) : 0);
  }
}
