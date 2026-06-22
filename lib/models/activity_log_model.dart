class ActivityLogModel {
  final String? id;
  final String? userId;        // Maps to user_id (Auth)
  final String? shareholderId; // Maps to shareholder_id (Profile)
  final String action;
  final String? ipAddress;
  final DateTime createdAt;
  final String description;

  ActivityLogModel({
    this.id,
    this.userId,
    this.shareholderId,
    required this.action,
    this.ipAddress,
    required this.createdAt,
    required this.description,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['created_at'] != null) {
      String dateStr = json['created_at'].toString();
      // Ensure the parser knows it's UTC if the 'Z' or offset is missing
      if (!dateStr.contains('Z') && !dateStr.contains('+')) {
        // Laravel default timestamp is Y-m-d H:i:s, we need to treat it as UTC
        if (dateStr.length == 19) {
          dateStr = dateStr.replaceAll(' ', 'T') + 'Z';
        } else if (!dateStr.contains('T')) {
          dateStr += 'Z';
        }
      }
      parsedDate = DateTime.parse(dateStr).toLocal();
    } else {
      parsedDate = DateTime.now();
    }

    return ActivityLogModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      shareholderId: json['shareholder_id']?.toString(),
      action: json['action']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      createdAt: parsedDate,
      description: json['description'] ?? json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'action': action,
      'description': description,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (_isValidUuid(userId)) map['user_id'] = userId;
    if (_isValidUuid(shareholderId)) map['shareholder_id'] = shareholderId;
    
    return map;
  }

  static bool _isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(id);
  }
}
