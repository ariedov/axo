enum TaskStatus { pending, submitted, verified }

class HabitTask {
  const HabitTask({
    required this.id,
    required this.title,
    required this.points,
    required this.icon,
    this.status = TaskStatus.pending,
    this.todayOnly = false,
    this.optional = false,
  });

  final String id;
  final String title;
  final int points;
  final String icon;
  final TaskStatus status;
  final bool todayOnly;
  final bool optional;

  bool get isPending => status == TaskStatus.pending;
  bool get isSubmitted => status == TaskStatus.submitted;
  bool get isVerified => status == TaskStatus.verified;
  bool get isMandatory => !optional && !todayOnly;

  HabitTask copyWith({
    String? title,
    int? points,
    String? icon,
    TaskStatus? status,
    bool? todayOnly,
    bool? optional,
  }) {
    return HabitTask(
      id: id,
      title: title ?? this.title,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      todayOnly: todayOnly ?? this.todayOnly,
      optional: optional ?? this.optional,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'points': points,
    'icon': icon,
    'status': status.name,
    'todayOnly': todayOnly,
    'optional': optional,
  };

  factory HabitTask.fromJson(Map<String, dynamic> json) {
    return HabitTask(
      id: json['id'] as String,
      title: json['title'] as String,
      points: json['points'] as int,
      icon: json['icon'] as String? ?? json['emoji'] as String? ?? 'star',
      status: TaskStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      todayOnly: json['todayOnly'] == true,
      optional: json['optional'] == true,
    );
  }
}

class SpellingWord {
  const SpellingWord({
    required this.word,
    required this.hint,
    required this.emoji,
  });

  final String word;
  final String hint;
  final String emoji;

  factory SpellingWord.fromJson(Map<String, dynamic> json) {
    return SpellingWord(
      word: json['word'] as String,
      hint: json['hint'] as String,
      emoji: json['emoji'] as String,
    );
  }
}

class TranslationPair {
  const TranslationPair({
    required this.en,
    required this.uk,
    required this.emoji,
  });

  final String en;
  final String uk;
  final String emoji;

  factory TranslationPair.fromJson(Map<String, dynamic> json) {
    return TranslationPair(
      en: json['en'] as String,
      uk: json['uk'] as String,
      emoji: json['emoji'] as String,
    );
  }
}

class RewardGoal {
  const RewardGoal({
    required this.id,
    required this.title,
    required this.cost,
    required this.icon,
    this.completedOn,
  });

  final String id;
  final String title;
  final int cost;
  final String icon;
  final String? completedOn;

  bool get isCompleted => completedOn != null;

  bool canAfford(int points) => !isCompleted && points >= cost;

  double progress(int points) {
    if (cost <= 0) return 1;
    final value = points / cost;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  RewardGoal copyWith({
    String? title,
    int? cost,
    String? icon,
    String? completedOn,
  }) {
    return RewardGoal(
      id: id,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      icon: icon ?? this.icon,
      completedOn: completedOn ?? this.completedOn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cost': cost,
    'icon': icon,
    if (completedOn != null) 'completedOn': completedOn,
  };

  factory RewardGoal.fromJson(Map<String, dynamic> json) {
    return RewardGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      cost: json['cost'] as int,
      icon: json['icon'] as String? ?? 'star',
      completedOn: json['completedOn'] as String?,
    );
  }
}

class DayProgress {
  const DayProgress({
    required this.day,
    required this.completed,
    required this.total,
  });

  final String day;
  final int completed;
  final int total;

  bool get isFull => total > 0 && completed >= total;
  bool get isPartial => completed > 0 && completed < total;

  factory DayProgress.fromTasks(String day, List<HabitTask> tasks) {
    final counted = [
      for (final task in tasks)
        if (task.isMandatory) task,
    ];
    return DayProgress(
      day: day,
      completed: counted.where((task) => task.isVerified).length,
      total: counted.length,
    );
  }

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'total': total,
  };

  factory DayProgress.fromJson(String day, Map<String, dynamic> json) {
    return DayProgress(
      day: day,
      completed: json['completed'] as int,
      total: json['total'] as int,
    );
  }
}
