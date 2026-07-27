/// Memory data model.
///
/// Represents a piece of user context that the AI has extracted
/// from conversations or the user has manually added.
///
/// Categories:
/// - situation: 生活状况 (工作、学习、家庭等)
/// - preference: 个人偏好 (喜欢的事、回避的事)
/// - concern: 当前担忧
/// - pattern: 反复出现的模式
/// - event: 发生的事件
/// - coping: 应对方式 (什么能帮助放松)
class MemoryModel {
  /// Unique ID from the backend (UUID string).
  final String id;
  final String category;
  final String content;
  final bool approved;
  final DateTime createdAt;

  const MemoryModel({
    required this.id,
    required this.category,
    required this.content,
    required this.approved,
    required this.createdAt,
  });

  /// Human-readable label for the category in Chinese.
  String get categoryLabel {
    switch (category) {
      case 'situation':
        return '生活状况';
      case 'preference':
        return '个人偏好';
      case 'concern':
        return '当前担忧';
      case 'pattern':
        return '行为模式';
      case 'event':
        return '发生事件';
      case 'coping':
        return '应对方式';
      default:
        return '其他';
    }
  }

  /// Short description for the category.
  static const Map<String, String> categoryDescriptions = {
    'situation': '工作、学习、家庭等生活状况',
    'preference': '喜欢或回避的事',
    'concern': '正在担心的事情',
    'pattern': '反复出现的想法或行为',
    'event': '生活中发生的事',
    'coping': '什么能帮助你放松',
  };

  /// All valid categories.
  static const List<String> allCategories = [
    'situation',
    'preference',
    'concern',
    'pattern',
    'event',
    'coping',
  ];

  MemoryModel copyWith({
    String? id,
    String? category,
    String? content,
    bool? approved,
    DateTime? createdAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      category: category ?? this.category,
      content: content ?? this.content,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'content': content,
        'approved': approved,
        'created_at': createdAt.toIso8601String(),
      };

  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel(
        id: json['id']?.toString() ?? '',
        category: json['category'] as String? ?? 'other',
        content: json['content'] as String? ?? '',
        approved: json['approved'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

/// Response from the memory list endpoint.
class MemoryListResponse {
  final List<MemoryModel> memories;
  final int total;
  final int approvedCount;
  final int pendingCount;

  const MemoryListResponse({
    this.memories = const [],
    this.total = 0,
    this.approvedCount = 0,
    this.pendingCount = 0,
  });

  factory MemoryListResponse.fromJson(Map<String, dynamic> json) {
    final List raw = json['memories'] as List? ?? [];
    return MemoryListResponse(
      memories: raw
          .map((m) => MemoryModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      approvedCount: json['approved_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
    );
  }
}
