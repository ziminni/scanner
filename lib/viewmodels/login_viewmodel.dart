import '../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._app);

  final AppController _app;

  bool obscurePassword = true;

  String? get authError => _app.authError;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setBusy(true);
    try {
      await _app.login(email, password);
    } finally {
      setBusy(false);
    }
  }
}
