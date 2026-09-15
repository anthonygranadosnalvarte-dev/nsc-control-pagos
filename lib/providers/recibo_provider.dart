import 'package:flutter/foundation.dart';
import '../services/recibo_service.dart';
import '../models/recibo_model.dart';

class ReciboProvider extends ChangeNotifier {
  final ReciboService service;
  ReciboProvider(this.service) {
    service.store.addListener(notifyListeners);
  }
  List<ReciboModel> get recibos => service.list();
  @override
  void dispose() {
    service.store.removeListener(notifyListeners);
    super.dispose();
  }
}
