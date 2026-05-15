class ActivityLog {
  final String logId;
  final String actionType;
  final String subjectUserId;
  final String subjectUserName;
  final String ipAddress;
  final String processedBy;
  final String fullDescription;
  final DateTime createdAt;
  final List<String> affectedSystems;

  ActivityLog({
    required this.logId,
    required this.actionType,
    required this.subjectUserId,
    required this.subjectUserName,
    required this.ipAddress,
    required this.processedBy,
    required this.fullDescription,
    required this.createdAt,
    required this.affectedSystems,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      logId: map['log_id'] ?? '',
      actionType: map['action_type'] ?? '',
      subjectUserId: map['subject_user_id'] ?? '',
      subjectUserName: map['subject_user_name'] ?? '',
      ipAddress: map['ip_address'] ?? '',
      processedBy: map['processed_by'] ?? '',
      fullDescription: map['full_description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      affectedSystems: List<String>.from(map['affected_systems'] ?? []),
    );
  }
}