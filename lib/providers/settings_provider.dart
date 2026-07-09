import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  double _fontSizeFactor = 1.1;

  double get fontSizeFactor => _fontSizeFactor;

  void setFontSizeFactor(double value) {
    _fontSizeFactor = value;
    notifyListeners();
  }

  void increaseFontSize() {
    if (_fontSizeFactor < 2.0) {
      _fontSizeFactor += 0.1;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSizeFactor > 0.8) {
      _fontSizeFactor -= 0.1;
      notifyListeners();
    }
  }
}
