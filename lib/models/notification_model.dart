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
}
