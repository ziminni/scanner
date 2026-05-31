import 'package:flutter/foundation.dart';

class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
