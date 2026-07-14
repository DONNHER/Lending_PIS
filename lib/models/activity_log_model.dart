class ActivityLog {
  final String id;
  final String? userId;
  final String userName;
  final String action;
  final String details;
  final String type;
  final DateTime createdAt;
  final String? ipAddress;
  final String? deviceInfo;

  ActivityLog({
    required this.id,
    this.userId,
    required this.userName,
    required this.action,
    required this.details,
    required this.type,
    required this.createdAt,
    this.ipAddress,
    this.deviceInfo,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    String name = 'System';
    if (json['user'] != null) {
      if (json['user'] is Map) {
        final firstName = json['user']['firstname'] ?? '';
        final lastName = json['user']['lastname'] ?? '';
        name = '$firstName $lastName'.trim();
        if (name.isEmpty) name = json['user']['name'] ?? 'User';
      } else {
        name = json['user'].toString();
      }
    } else if (json['user_name'] != null) {
      name = json['user_name'];
    }

    return ActivityLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: name,
      action: json['action'] ?? 'N/A',
      details: json['details'] ?? 'No details',
      type: (json['type'] ?? 'info').toString().toLowerCase(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      ipAddress: json['ip_address']?.toString(),
      deviceInfo: json['device_info']?.toString(),
    );
  }
}
