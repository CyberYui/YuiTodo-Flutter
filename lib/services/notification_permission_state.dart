import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationPermissionState extends ChangeNotifier {
  bool? _granted;
  
  bool? get granted => _granted;
  
  void setGranted(bool granted) {
    _granted = granted;
    notifyListeners();
  }
  
  void reset() {
    _granted = null;
    notifyListeners();
  }
}
