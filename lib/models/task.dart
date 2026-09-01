/// Task model
class Task {
  final int? id;
  final String title;
  final String note;
  final String status;
  final int? startTime;
  final int? endTime;
  final int? deadline;
  final int? startDate;
  final String color;
  final String? icon;
  final int? recurrenceId;
  final bool isStarred;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  // Relations (not stored in task table)
  final List<TaskStep> steps;
  final List<Tag> tags;

  Task({
    this.id,
    required this.title,
    this.note = '',
    this.status = 'pending',
    this.startTime,
    this.endTime,
    this.deadline,
    this.startDate,
    this.color = '#3B82F6',
    this.icon,
    this.recurrenceId,
    this.isStarred = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.steps = const [],
    this.tags = const [],
  });

  Task copyWith({
    int? id,
    String? title,
    String? note,
    String? status,
    int? startTime,
    int? endTime,
    int? deadline,
    int? startDate,
    String? color,
    String? icon,
    int? recurrenceId,
    bool? isStarred,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    List<TaskStep>? steps,
    List<Tag>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deadline: deadline ?? this.deadline,
      startDate: startDate ?? this.startDate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      isStarred: isStarred ?? this.isStarred,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'deadline': deadline,
      'start_date': startDate,
      'color': color,
      'icon': icon,
      'recurrence_id': recurrenceId,
      'is_starred': isStarred ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: (map['note'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      startTime: map['start_time'] as int?,
      endTime: map['end_time'] as int?,
      deadline: map['deadline'] as int?,
      startDate: map['start_date'] as int?,
      color: (map['color'] as String?) ?? '#3B82F6',
      icon: map['icon'] as String?,
      recurrenceId: map['recurrence_id'] as int?,
      isStarred: (map['is_starred'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deletedAt: map['deleted_at'] as int?,
    );
  }
}

/// TaskStep model
class TaskStep {
  final int? id;
  final int taskId;
  final String title;
  final int sortOrder;
  final String status;

  TaskStep({
    this.id,
    required this.taskId,
    required this.title,
    this.sortOrder = 0,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'sort_order': sortOrder,
      'status': status,
    };
  }

  factory TaskStep.fromMap(Map<String, dynamic> map) {
    return TaskStep(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      status: (map['status'] as String?) ?? 'pending',
    );
  }
}

/// Tag model
class Tag {
  final int? id;
  final String name;
  final String color;
  final int createdAt;

  Tag({
    this.id,
    required this.name,
    this.color = '#6B7280',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: (map['color'] as String?) ?? '#6B7280',
      createdAt: map['created_at'] as int,
    );
  }
}
