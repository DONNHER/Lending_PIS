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
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? stackTrace;

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
    this.oldValues,
    this.newValues,
    this.stackTrace,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    String name = 'Guest';
    if (json['user'] != null) {
      if (json['user'] is Map) {
        final firstName = json['user']['firstname'] ?? '';
        final lastName = json['user']['lastname'] ?? '';
        name = '$firstName $lastName'.trim();
        if (name.isEmpty) name = json['user']['name'] ?? 'User';
      } else {
        name = json['user'].toString();
      }
    } else if (json['user_name'] != null && json['user_name'].toString().isNotEmpty) {
      name = json['user_name'];
    } else if (json['action'] != null && 
               (json['action'].toString().contains('Register') || 
                json['action'].toString().contains('Login'))) {
      // If it's an auth action with no user yet, it's a Guest
      name = 'Guest';
    } else {
      name = 'System';
    }

    // Process details/description
    String details = json['details'] ?? json['description'] ?? 'No details';
    if (details == 'No details' && json['action'] != null) {
      details = 'Action: ${json['action']}';
    }

    return ActivityLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: name,
      action: json['action'] ?? 'N/A',
      details: details,
      type: (json['log_type'] ?? json['type'] ?? 'info').toString().toLowerCase(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      ipAddress: json['ip_address']?.toString(),
      deviceInfo: json['device_info']?.toString(),
      oldValues: json['old_values'] is Map<String, dynamic> ? json['old_values'] : null,
      newValues: json['new_values'] is Map<String, dynamic> ? json['new_values'] : null,
      stackTrace: json['stack_trace']?.toString(),
    );
  }
}
