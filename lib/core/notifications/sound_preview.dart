import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'reminder_sounds.dart';

/// Plays short previews for the reminder-sound picker.
///
/// A single native [MediaPlayer] is used; starting a new preview stops the
/// previous one first. Tokens make sure a late completion callback from an
/// older preview cannot clear the state of a newer one.
class SoundPreview extends ChangeNotifier {
  SoundPreview._() {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static final SoundPreview instance = SoundPreview._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.yuitodo/sound_preview');

  String? _playingKey;
  bool _active = false;
  int _token = 0;

  String? get playingKey => _playingKey;

  bool isPlaying(String? key) => _active && _playingKey == key;

  /// Toggle a preview. Tapping the currently playing option stops it.
  Future<void> toggle(String? key) async {
    if (_active && _playingKey == key) {
      await stop();
      return;
    }
    // Stop the previous preview before starting the next one: no mixing.
    await _stopNative();
    _playingKey = key;
    _active = true;
    final token = ++_token;
    final raw = reminderSoundFor(key).rawName;
    notifyListeners();
    try {
      await channel.invokeMethod<bool>('play', {
        'raw': raw,
        'token': token,
      });
    } on PlatformException {
      _clear(token);
    } on MissingPluginException {
      _clear(token);
    }
  }

  Future<void> stop() async {
    _playingKey = null;
    _active = false;
    _token++;
    notifyListeners();
    await _stopNative();
  }

  Future<void> _stopNative() async {
    try {
      await channel.invokeMethod<bool>('stop');
    } on MissingPluginException {
      // Desktop/tests without the native channel.
    } on PlatformException {
      // Preview is best-effort.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onComplete') return;
    final token = call.arguments;
    if (token is int) _clear(token);
  }

  void _clear(int token) {
    if (token != _token) return;
    _playingKey = null;
    _active = false;
    notifyListeners();
  }
}
