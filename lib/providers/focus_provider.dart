import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../repositories/task_repository.dart';

/// Recent focus sessions (for the records list).
final focusSessionsProvider = FutureProvider<List<FocusSession>>((ref) async {
  return ref.watch(taskRepositoryProvider).getFocusSessions();
});

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusRuntime>((ref) {
  return FocusNotifier(ref.watch(taskRepositoryProvider));
});

/// Immutable snapshot of the focus runtime, recomputed every tick.
class FocusRuntime {
  final FocusSession? session;
  final bool paused;
  final DateTime? pausedAt;
  final Duration pausedTotal;
  final bool resting;
  final DateTime? restStartedAt;
  final int restCount;
  final Duration restTotal;
  final DateTime now;

  const FocusRuntime({
    this.session,
    this.paused = false,
    this.pausedAt,
    this.pausedTotal = Duration.zero,
    this.resting = false,
    this.restStartedAt,
    this.restCount = 0,
    this.restTotal = Duration.zero,
    required this.now,
  });

  factory FocusRuntime.empty() => FocusRuntime(now: DateTime.now());

  bool get hasSession => session != null;
  bool get isFocusing =>
      session != null && session!.status == FocusStatus.focusing;
  bool get isFinished =>
      session != null && session!.status != FocusStatus.focusing;
  bool get isPaused => paused;
  bool get isResting => resting;
  bool get isRunning => isFocusing && !paused;

  int get mode => session?.mode ?? FocusMode.timer;
  int get targetSeconds => session?.targetDuration ?? 0;
  int get sessionId => session?.id ?? 0;
  int? get taskId => session?.taskId;
  String? get focusName => session?.focusName;
  int get status => session?.status ?? FocusStatus.focusing;

  Duration get elapsed {
    final s = session;
    if (s == null) return Duration.zero;
    final end = paused && pausedAt != null ? pausedAt! : now;
    final raw = end.difference(DateTime.fromMillisecondsSinceEpoch(s.startTime));
    final e = raw - pausedTotal;
    return e.isNegative ? Duration.zero : e;
  }

  int get remainingSeconds {
    if (mode != FocusMode.timer) return 0;
    final r = targetSeconds - elapsed.inSeconds;
    return r < 0 ? 0 : r;
  }

  double get progress {
    if (mode == FocusMode.timer) {
      if (targetSeconds <= 0) return 0;
      return (elapsed.inSeconds / targetSeconds).clamp(0.0, 1.0);
    }
    // Stopwatch ring fills once per hour.
    return ((elapsed.inSeconds % 3600) / 3600).clamp(0.0, 1.0);
  }
}

class FocusNotifier extends StateNotifier<FocusRuntime> {
  final TaskRepository _repo;

  FocusSession? _session;
  Timer? _ticker;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  bool _resting = false;
  DateTime? _restStartedAt;
  int _restCount = 0;
  Duration _restTotal = Duration.zero;

  FocusNotifier(this._repo) : super(FocusRuntime.empty()) {
    _loadActive();
  }

  FocusRuntime _snapshot() {
    return FocusRuntime(
      session: _session,
      paused: _pausedAt != null,
      pausedAt: _pausedAt,
      pausedTotal: _pausedTotal,
      resting: _resting,
      restStartedAt: _restStartedAt,
      restCount: _restCount,
      restTotal: _restTotal,
      now: DateTime.now(),
    );
  }

  Future<void> _loadActive() async {
    final active = await _repo.getActiveFocusSession();
    if (active == null) return;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(active.startTime));
    if (age.inHours >= 12) {
      await _repo.updateFocusSession(active.copyWith(
        status: FocusStatus.interrupted,
        endTime: DateTime.now().millisecondsSinceEpoch,
        actualDuration: age.inSeconds,
      ));
      return;
    }
    _session = active;
    _startTicker();
    state = _snapshot();
  }

  Future<void> start({
    required int mode,
    required int targetSeconds,
    int? taskId,
    String? focusName,
  }) async {
    if (_session != null) return;
    final now = DateTime.now();
    final session = FocusSession(
      taskId: taskId,
      mode: mode,
      status: FocusStatus.focusing,
      startTime: now.millisecondsSinceEpoch,
      targetDuration: targetSeconds,
      focusName: focusName,
      createdAt: now.millisecondsSinceEpoch,
    );
    final id = await _repo.createFocusSession(session);
    _session = session.copyWith(id: id);
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _resting = false;
    _restStartedAt = null;
    _restCount = 0;
    _restTotal = Duration.zero;
    _startTicker();
    state = _snapshot();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _snapshot();
      if (state.mode == FocusMode.timer &&
          state.isFocusing &&
          state.remainingSeconds <= 0) {
        _finish(FocusStatus.onTime);
      }
    });
  }

  Future<void> pause() async {
    final s = _session;
    if (s == null || _pausedAt != null || !state.isFocusing) return;
    _pausedAt = DateTime.now();
    final updated = s.copyWith(pauseCount: s.pauseCount + 1);
    _session = updated;
    await _repo.updateFocusSession(updated);
    state = _snapshot();
  }

  Future<void> resume() async {
    if (_pausedAt == null || _resting) return;
    _pausedTotal += DateTime.now().difference(_pausedAt!);
    _pausedAt = null;
    state = _snapshot();
  }

  Future<void> _finish(int status) async {
    final s = _session;
    if (s == null || !state.isFocusing) return;
    _ticker?.cancel();
    final now = DateTime.now();
    final elapsed = state.elapsed;
    final updated = s.copyWith(
      status: status,
      endTime: now.millisecondsSinceEpoch,
      actualDuration: elapsed.inSeconds,
      restCount: _restCount,
      restDuration: _restTotal.inSeconds,
    );
    _session = updated;
    await _repo.updateFocusSession(updated);
    state = _snapshot();
  }

  Future<void> endEarly() => _finish(FocusStatus.endedEarly);

  Future<void> startRest() async {
    if (!state.isFinished && !state.isFocusing) return;
    _resting = true;
    _restStartedAt = DateTime.now();
    if (_pausedAt == null) _pausedAt = DateTime.now();
    state = _snapshot();
  }

  Future<void> endRest() async {
    if (!_resting) return;
    final start = _restStartedAt;
    final now = DateTime.now();
    if (start != null) {
      final d = now.difference(start);
      _restTotal += d;
      _restCount += 1;
      final id = _session?.id;
      if (id != null) {
        await _repo.addFocusRestSegment(
          id,
          start.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          d.inSeconds,
        );
      }
    }
    _resting = false;
    _restStartedAt = null;
    if (_pausedAt != null) {
      _pausedTotal += now.difference(_pausedAt!);
      _pausedAt = null;
    }
    state = _snapshot();
  }

  /// Clears a finished session so a new one can start.
  void reset() {
    _ticker?.cancel();
    _session = null;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _resting = false;
    _restStartedAt = null;
    _restCount = 0;
    _restTotal = Duration.zero;
    state = FocusRuntime.empty();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
