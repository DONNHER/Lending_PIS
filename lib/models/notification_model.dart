enum NotificationCategory { general, transaction, system }

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isUnread;
  final String? type;
  final NotificationCategory category;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isUnread = true,
    this.type,
    this.category = NotificationCategory.general,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isUnread: json['is_unread'] ?? true,
      type: json['type'],
      category: _parseCategory(json['category']),
      metadata: json['metadata'],
    );
  }

  static NotificationCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'transaction':
        return NotificationCategory.transaction;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.general;
    }
  }
  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    bool? isUnread,
    String? type,
    NotificationCategory? category,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      type: type ?? this.type,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }
}
