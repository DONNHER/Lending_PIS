import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/activity_log_model.dart';

class ActivityLogTable extends StatelessWidget {
  final List<ActivityLog> logs;
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
                      onTap: () => _showLogDetails(context, log),
                      hoverColor: const Color(0xFFC06C4D).withValues(alpha: 0.05),
                      child: _buildRow(log),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(ActivityLog log) {
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(log.userName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text(log.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Expanded(flex: 4, child: Text(log.details, style: const TextStyle(fontSize: 11, color: AppTheme.textDark), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(log.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.type.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _getTypeColor(log.type)),
                ),
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(dateFormat.format(log.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  void _showLogDetails(BuildContext context, ActivityLog log) {
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm:ss');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: _getTypeColor(log.type)),
            const SizedBox(width: 12),
            const Text('Log Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('User', log.userName),
            _detailItem('Action', log.action),
            _detailItem('Type', log.type.toUpperCase(), color: _getTypeColor(log.type)),
            _detailItem('Date', dateFormat.format(log.createdAt)),
            const Divider(height: 32),
            const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Text(log.details, style: const TextStyle(fontSize: 14, height: 1.5)),
            
            if (log.ipAddress != null || log.deviceInfo != null) ...[
              const Divider(height: 32),
              const Text('Technical Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              if (log.ipAddress != null) _detailItem('IP Address', log.ipAddress!),
              if (log.deviceInfo != null) _detailItem('Device Info', log.deviceInfo!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    final t = type.toLowerCase();
    if (t == 'error' || t == 'critical') return Colors.red;
    if (t == 'warning') return Colors.orange;
    if (t == 'success') return Colors.green;
    if (t == 'auth' || t == 'authentication') return Colors.purple;
    return Colors.blue;
  }
}
