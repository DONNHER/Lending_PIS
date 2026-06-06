enum NotificationCategory {
  transaction,
  announcement,
  security;

  static NotificationCategory fromString(String? value) {
    if (value == null) return NotificationCategory.transaction;
    return NotificationCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => NotificationCategory.transaction,
    );
  }
}

class NotificationModel {
  final String id;
  final String shareholderId;
  final String? comakerId; // Added for co-maker relevant notifications
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isUnread;
  final NotificationCategory category;
  final String? type; // loan_request, payment_receipt, etc.
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.shareholderId,
    this.comakerId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isUnread = true,
    required this.category,
    this.type,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['user_id']?.toString() ?? '',
      comakerId: json['comaker_id']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      isUnread: json['is_unread'] as bool? ?? true,
      category: NotificationCategory.fromString(json['category']?.toString()),
      type: json['type']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'shareholder_id': shareholderId,
    'comaker_id': comakerId,
    'title': title,
    'content': content,
    'is_unread': isUnread,
    'category': category.name,
    'type': type,
    'metadata': metadata,
  };
}
