import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/activity_log_model.dart';
import '../views/activity_log_detail_page.dart';

class ActivityLogTable extends StatelessWidget {
  final List<ActivityLogModel> logs;
  final Function(String) onDelete;
  final Function(ActivityLogModel) onEdit;
  final Function(ActivityLogModel) onView;

  const ActivityLogTable({
    super.key,
    required this.logs,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
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
              Expanded(flex: 1, child: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Text('User ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('IP Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Created At', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: logs.isEmpty
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
              return _buildRow(context, logs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, ActivityLogModel log) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    void navigateToDetails() {
      onView(log);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityLogDetailPage(log: log),
        ),
      );
    }

    return InkWell(
      onTap: navigateToDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text(log.id ?? '—', style: const TextStyle(fontSize: 12, color: AppTheme.textDark), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 1, child: Text(log.userId ?? '—', style: const TextStyle(fontSize: 12, color: AppTheme.textDark), overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 3,
              child: Text(
                log.action,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.ipAddress != null && log.ipAddress!.isNotEmpty ? log.ipAddress! : '—',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.blueGrey),
              ),
            ),
            Expanded(flex: 2, child: Text(dateFormat.format(log.createdAt), style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
            Expanded(flex: 3, child: Text(log.description, style: const TextStyle(fontSize: 12, color: AppTheme.textDark), overflow: TextOverflow.ellipsis)),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionButton(
                    icon: Icons.chevron_right,
                    color: AppTheme.textMuted,
                    onTap: navigateToDetails,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
