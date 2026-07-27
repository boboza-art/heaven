/// Mood data model.
///
/// Represents a single mood log entry.
/// Mood level: 1 (worst) to 5 (best), matching the DB schema.
class MoodModel {
  /// Unique ID from the backend (UUID string). Null for locally-created entries.
  final String? id;
  final int moodLevel;
  final String? note;
  final DateTime createdAt;

  const MoodModel({
    this.id,
    required this.moodLevel,
    this.note,
    required this.createdAt,
  });

  /// Create a mood entry now.
  factory MoodModel.now({required int moodLevel, String? note}) {
    return MoodModel(
      moodLevel: moodLevel,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  /// Mood level label in Chinese.
  String get label {
    switch (moodLevel) {
      case 1:
        return '很不好';
      case 2:
        return '不太好';
      case 3:
        return '一般';
      case 4:
        return '不错';
      case 5:
        return '很好';
      default:
        return '';
    }
  }

  /// Emoji for the mood level.
  String get emoji {
    switch (moodLevel) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '';
    }
  }

  /// Whether a note was provided with this mood entry.
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  MoodModel copyWith({
    String? id,
    int? moodLevel,
    String? note,
    DateTime? createdAt,
  }) {
    return MoodModel(
      id: id ?? this.id,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'mood_level': moodLevel,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory MoodModel.fromJson(Map<String, dynamic> json) => MoodModel(
        id: json['id']?.toString(),
        moodLevel: json['mood_level'] as int,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
