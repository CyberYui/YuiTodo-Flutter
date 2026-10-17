/// Recurrence rule model
class RecurrenceRule {
  final int? id;
  final int taskId;
  final String type;
  final int interval;
  final String? daysOfWeek;
  final int? dayOfMonth;
  final int? monthOfYear;

  /// End condition: 'none' | 'date' | 'count'
  final String endType;
  final int? endDate;
  final int? endCount;

  /// Monthly sub-mode: 'day' | 'last' | 'week' | 'week_last'
  final String monthMode;

  /// Which weekday occurrence within a month (1..5) for monthMode == 'week'.
  final int? weekIndex;

  /// Skip Saturday/Sunday occurrences.
  final int skipWeekends;

  /// Only Monday..Friday.
  final int workdayOnly;

  final int isPaused;
  final int createdAt;

  RecurrenceRule({
    this.id,
    required this.taskId,
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.monthOfYear,
    this.endType = 'none',
    this.endDate,
    this.endCount,
    this.monthMode = 'day',
    this.weekIndex,
    this.skipWeekends = 0,
    this.workdayOnly = 0,
    this.isPaused = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'type': type,
      'interval': interval,
      'days_of_week': daysOfWeek,
      'day_of_month': dayOfMonth,
      'month_of_year': monthOfYear,
      'end_type': endType,
      'end_date': endDate,
      'end_count': endCount,
      'month_mode': monthMode,
      'week_index': weekIndex,
      'skip_weekends': skipWeekends,
      'workday_only': workdayOnly,
      'is_paused': isPaused,
      'created_at': createdAt,
    };
  }

  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      type: map['type'] as String,
      interval: map['interval'] as int? ?? 1,
      daysOfWeek: map['days_of_week'] as String?,
      dayOfMonth: map['day_of_month'] as int?,
      monthOfYear: map['month_of_year'] as int?,
      endType: (map['end_type'] as String?) ?? 'none',
      endDate: map['end_date'] as int?,
      endCount: map['end_count'] as int?,
      monthMode: (map['month_mode'] as String?) ?? 'day',
      weekIndex: map['week_index'] as int?,
      skipWeekends: map['skip_weekends'] as int? ?? 0,
      workdayOnly: map['workday_only'] as int? ?? 0,
      isPaused: map['is_paused'] as int? ?? 0,
      createdAt: map['created_at'] as int,
    );
  }

  RecurrenceRule copyWith({
    int? id,
    int? taskId,
    String? type,
    int? interval,
    String? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    String? endType,
    int? endDate,
    int? endCount,
    String? monthMode,
    int? weekIndex,
    int? skipWeekends,
    int? workdayOnly,
    int? isPaused,
    int? createdAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      endType: endType ?? this.endType,
      endDate: endDate ?? this.endDate,
      endCount: endCount ?? this.endCount,
      monthMode: monthMode ?? this.monthMode,
      weekIndex: weekIndex ?? this.weekIndex,
      skipWeekends: skipWeekends ?? this.skipWeekends,
      workdayOnly: workdayOnly ?? this.workdayOnly,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
