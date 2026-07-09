import 'package:flutter/foundation.dart';

class DashboardProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;
  bool get isDigitizerTabSelected => _selectedIndex == 4;
  bool get isProfileTabSelected => _selectedIndex == 5;

  void selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    _selectedIndex = index;
    notifyListeners();
  }

  void reset() {
    if (_selectedIndex == 0) {
      return;
    }

    _selectedIndex = 0;
    notifyListeners();
  }
}
