/// Recurrence rule model
class RecurrenceRule {
  final int? id;
  final int taskId;
  final String type;
  final int interval;
  final String? daysOfWeek;
  final int? dayOfMonth;
  final int? monthOfYear;
  final int? endDate;
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
    this.endDate,
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
      'end_date': endDate,
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
      endDate: map['end_date'] as int?,
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
    int? endDate,
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
      endDate: endDate ?? this.endDate,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
