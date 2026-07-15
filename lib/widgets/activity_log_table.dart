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
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');
    final typeColor = _getTypeColor(log.type);
    
    IconData getTitleIcon(String type) {
      final t = type.toLowerCase();
      if (t == 'access') return Icons.visibility_rounded;
      if (t == 'error') return Icons.error_outline_rounded;
      if (t == 'transaction') return Icons.swap_horiz_rounded;
      if (t == 'auth') return Icons.security_rounded;
      return Icons.history_rounded;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header / Close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),

                  // Icon & Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(getTitleIcon(log.type), size: 40, color: typeColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    log.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: typeColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      log.action,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 24),
                        _detailRow('User', log.userName),
                        _detailRow('Date', dateFormat.format(log.createdAt)),
                        _detailRow('Time', timeFormat.format(log.createdAt)),
                        if (log.ipAddress != null && log.ipAddress != 'null') 
                          _detailRow('IP Address', log.ipAddress!),
                        if (log.deviceInfo != null && log.deviceInfo != 'null')
                          _detailRow('Device Info', log.deviceInfo!),
                        
                        const Divider(height: 32, color: Color(0xFFF3F4F6)),
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text(log.details, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textDark)),
                        
                        if (log.oldValues != null || log.newValues != null) ...[
                          const SizedBox(height: 24),
                          const Text('DATA CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          _buildChangesSection(log),
                        ],

                        if (log.stackTrace != null && log.stackTrace!.isNotEmpty && log.stackTrace != 'null') ...[
                          const SizedBox(height: 24),
                          const Text('STACK TRACE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          _buildStackTraceSection(log.stackTrace!),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Info Box
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'This is a verified system log entry for audit and security monitoring purposes.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC06C4D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackTraceSection(String stackTrace) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        stackTrace,
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildChangesSection(ActivityLog log) {
    final oldData = log.oldValues ?? {};
    final newData = log.newValues ?? {};
    
    // Get unique keys from both maps
    final allKeys = {...oldData.keys, ...newData.keys}.toList();
    
    if (allKeys.isEmpty) {
      return const Text('No identifiable field changes.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontStyle: FontStyle.italic));
    }

    return Column(
      children: allKeys.map((key) {
        final oldValue = oldData[key]?.toString() ?? '(empty)';
        final newValue = newData[key]?.toString() ?? '(empty)';
        
        // Skip if values are identical
        if (oldValue == newValue) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC06C4D), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text(oldValue, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textMuted),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text(newValue, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
    if (t == 'transaction' || t == 'crud') return const Color(0xFFC06C4D);
    if (t == 'access') return Colors.indigo;
    return Colors.blue;
  }
}
