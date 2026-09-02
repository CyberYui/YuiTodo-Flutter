import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Undo item for snackbar actions
class UndoItem {
  final String message;
  final VoidCallback onUndo;
  final Timer timer;

  UndoItem({
    required this.message,
    required this.onUndo,
  }) : timer = Timer(const Duration(seconds: 5), () {});

  void cancel() => timer.cancel();
  bool get isValid => timer.isActive;
}

/// Undo manager provider
final undoProvider = StateNotifierProvider<UndoNotifier, UndoItem?>((ref) {
  return UndoNotifier();
});

class UndoNotifier extends StateNotifier<UndoItem?> {
  UndoNotifier() : super(null);

  void show(String message, VoidCallback onUndo) {
    state?.cancel();
    state = UndoItem(message: message, onUndo: onUndo);
  }

  void clear() {
    state?.cancel();
    state = null;
  }
}

/// Extension to show undo snackbar
extension UndoSnackBar on BuildContext {
  void showUndoSnackBar(String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '撤销',
          onPressed: onUndo,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
