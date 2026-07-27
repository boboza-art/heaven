/// Exercise data model.
///
/// Represents a self-help exercise available to the user.
class ExerciseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int durationSeconds;

  const ExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationSeconds,
  });

  /// Duration display text (e.g. "3 分钟").
  String get durationText {
    final minutes = durationSeconds ~/ 60;
    if (minutes > 0) return '$minutes 分钟';
    return '$durationSeconds 秒';
  }

  /// Category labels in Chinese.
  static String categoryLabel(String category) {
    switch (category) {
      case 'breathing':
        return '呼吸';
      case 'grounding':
        return '稳定';
      case 'gratitude':
        return '感恩';
      case 'body_scan':
        return '身体';
      default:
        return '其他';
    }
  }

  /// Pre-built exercises for MVP / offline fallback.
  static List<ExerciseModel> get defaults => const [
        ExerciseModel(
          id: 'breathing-478',
          title: '4-7-8 呼吸法',
          description: '用简单的呼吸节奏，让身体和思绪慢慢平静下来',
          category: 'breathing',
          durationSeconds: 180, // 3 rounds of 4-7-8 ~= 3 min
        ),
        ExerciseModel(
          id: 'grounding-54321',
          title: '5-4-3-2-1 感官练习',
          description: '用你的五种感官，回到此时此刻',
          category: 'grounding',
          durationSeconds: 120,
        ),
        ExerciseModel(
          id: 'gratitude-journal',
          title: '三件好事',
          description: '回忆今天三件让你感到温暖的小事',
          category: 'gratitude',
          durationSeconds: 180,
        ),
        ExerciseModel(
          id: 'body-scan-brief',
          title: '快速身体扫描',
          description: '从头到脚，温柔地注意身体的感受',
          category: 'body_scan',
          durationSeconds: 240,
        ),
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'duration_seconds': durationSeconds,
      };

  /// Parse from backend JSON.
  /// Backend uses `duration_minutes`, local model uses `duration_seconds`.
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final durationSeconds = json['duration_seconds'] != null
        ? json['duration_seconds'] as int
        : (json['duration_minutes'] as int? ?? 0) * 60;
    return ExerciseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      durationSeconds: durationSeconds,
    );
  }
}
