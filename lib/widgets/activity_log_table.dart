import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class ActivityLogTable extends StatelessWidget {
  final List<dynamic> logs;
  final bool isLoading;

  const ActivityLogTable({
    super.key,
    required this.logs,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFC06C4D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 4, child: Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D)))
            : logs.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No activity logs found', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : ListView.separated(
                  itemCount: logs.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return InkWell(
                      onTap: () {}, // Optional: Add detail view later
                      hoverColor: const Color(0xFFC06C4D).withOpacity(0.05),
                      child: _buildRow(log),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(dynamic log) {
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    
    DateTime createdAt;
    try {
      createdAt = log['created_at'] != null ? DateTime.parse(log['created_at']) : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    final userName = log['user'] != null 
        ? '${log['user']['firstname']} ${log['user']['lastname']}' 
        : 'System';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(userName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text(log['action'] ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Expanded(flex: 4, child: Text(log['details'] ?? 'No details', style: const TextStyle(fontSize: 11, color: AppTheme.textDark), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(log['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (log['type'] ?? 'INFO').toString().toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _getTypeColor(log['type'])),
                ),
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(dateFormat.format(createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  Color _getTypeColor(dynamic type) {
    final t = type.toString().toLowerCase();
    if (t == 'error' || t == 'critical') return Colors.red;
    if (t == 'warning') return Colors.orange;
    if (t == 'success') return Colors.green;
    return Colors.blue;
  }
}
