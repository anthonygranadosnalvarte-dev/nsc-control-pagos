import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/usuario_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService service;
  Timer? _timer;
  AuthProvider(this.service);
  UsuarioModel? get usuario => service.usuario;
  Future<void> login(String email, String password) async {
    await service.login(email, password);
    _timer?.cancel();
    _timer = Timer(const Duration(minutes: 30), logout);
    notifyListeners();
  }

  void logout() {
    _timer?.cancel();
    service.logout();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
