import 'package:flutter/foundation.dart';
import '../services/pago_service.dart';
import '../models/pago_model.dart';

class PagoProvider extends ChangeNotifier {
  final PagoService service;
  PagoProvider(this.service) {
    service.store.addListener(notifyListeners);
  }
  List<PagoModel> get pagos => service.list();
  @override
  void dispose() {
    service.store.removeListener(notifyListeners);
    super.dispose();
  }
}
