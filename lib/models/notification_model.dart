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
  final String? comakerId;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isUnread;
  final NotificationCategory category;
  final String? type;
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

  NotificationModel copyWith({
    String? id,
    String? shareholderId,
    String? comakerId,
    String? title,
    String? content,
    DateTime? createdAt,
    bool? isUnread,
    NotificationCategory? category,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      shareholderId: shareholderId ?? this.shareholderId,
      comakerId: comakerId ?? this.comakerId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      category: category ?? this.category,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

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
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shareholder_id': shareholderId,
    'comaker_id': comakerId,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_unread': isUnread,
    'category': category.name,
    'type': type,
    'metadata': metadata,
  };
}
