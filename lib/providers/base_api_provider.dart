import 'package:flutter/foundation.dart';

abstract class BaseApiProvider extends ChangeNotifier {
  String? _error;

  String? get error => _error;

  @protected
  void clearError({bool notify = false}) {
    _error = null;
    if (notify) {
      notifyListeners();
    }
  }

  @protected
  void setError(String? message, {bool notify = true}) {
    _error = message;
    if (notify) {
      notifyListeners();
    }
  }
}
