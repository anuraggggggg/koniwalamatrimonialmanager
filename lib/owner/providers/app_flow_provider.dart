import 'package:flutter/foundation.dart';

class AppFlowProvider extends ChangeNotifier {
  bool _hasCompletedSplash = false;
  bool _isAuthenticated = false;

  bool get hasCompletedSplash => _hasCompletedSplash;
  bool get isAuthenticated => _isAuthenticated;

  void completeSplash() {
    if (_hasCompletedSplash) {
      return;
    }

    _hasCompletedSplash = true;
    notifyListeners();
  }

  void login() {
    if (!_hasCompletedSplash) {
      _hasCompletedSplash = true;
    }

    if (_isAuthenticated) {
      return;
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    if (!_isAuthenticated) {
      return;
    }

    _isAuthenticated = false;
    notifyListeners();
  }
}
