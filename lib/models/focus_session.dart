/// Focus session modes and statuses (mirrors Todoery's model).
class FocusMode {
  static const timer = 0; // countdown
  static const stopwatch = 1; // count up
}

class FocusStatus {
  static const focusing = 0;
  static const endedEarly = 1;
  static const onTime = 2;
  static const interrupted = 3;
}

/// A focus session record.
class FocusSession {
  final int? id;
  final int? taskId;
  final int mode;
  final int status;
  final int startTime;
  final int? endTime;
  final int targetDuration; // seconds
  final int actualDuration; // seconds
  final int pauseCount;
  final int restCount;
  final int restDuration; // seconds
  final String? focusName;
  final int createdAt;

  FocusSession({
    this.id,
    this.taskId,
    this.mode = FocusMode.timer,
    this.status = FocusStatus.focusing,
    required this.startTime,
    this.endTime,
    required this.targetDuration,
    this.actualDuration = 0,
    this.pauseCount = 0,
    this.restCount = 0,
    this.restDuration = 0,
    this.focusName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'mode': mode,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'target_duration': targetDuration,
      'actual_duration': actualDuration,
      'pause_count': pauseCount,
      'rest_count': restCount,
      'rest_duration': restDuration,
      'focus_name': focusName,
      'created_at': createdAt,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      taskId: map['task_id'] as int?,
      mode: (map['mode'] as int?) ?? FocusMode.timer,
      status: (map['status'] as int?) ?? FocusStatus.focusing,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      targetDuration: (map['target_duration'] as int?) ?? 0,
      actualDuration: (map['actual_duration'] as int?) ?? 0,
      pauseCount: (map['pause_count'] as int?) ?? 0,
      restCount: (map['rest_count'] as int?) ?? 0,
      restDuration: (map['rest_duration'] as int?) ?? 0,
      focusName: map['focus_name'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  FocusSession copyWith({
    int? id,
    int? taskId,
    int? mode,
    int? status,
    int? startTime,
    int? endTime,
    int? targetDuration,
    int? actualDuration,
    int? pauseCount,
    int? restCount,
    int? restDuration,
    String? focusName,
    int? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetDuration: targetDuration ?? this.targetDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      pauseCount: pauseCount ?? this.pauseCount,
      restCount: restCount ?? this.restCount,
      restDuration: restDuration ?? this.restDuration,
      focusName: focusName ?? this.focusName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
