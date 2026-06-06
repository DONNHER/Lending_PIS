import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/activity_log_model.dart';

class ActivityLogDetailPage extends StatelessWidget {
  final ActivityLogModel log;

  const ActivityLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity Log Details',
          style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 2,
                child: _buildMainDetailCard(context, log, dateFormat, timeFormat),
              ),
              const SizedBox(width: 24),
              // Right Column
              Expanded(
                flex: 1,
                child: _buildTelemetryCard(log, dateFormat, timeFormat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDetailCard(
      BuildContext context,
      ActivityLogModel log,
      DateFormat dateFormat,
      DateFormat timeFormat,
      ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Operational Action',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.action.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF32211A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF388E3C)),
                    SizedBox(width: 6),
                    Text(
                      'Recorded',
                      style: TextStyle(color: Color(0xFF388E3C), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40, color: Color(0xFFE5E7EB)),
          const Text(
            'Event Description',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Text(
              log.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textDark,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Activity Entry Identifier Row ID', log.id ?? '—'),
          _buildInfoRow('Associated Shareholder / Account User ID', log.userId ?? '—'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(ActivityLogModel log, DateFormat dateFormat, DateFormat timeFormat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF32211A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Telemetry Signature',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 28),
          _metaItem('IP Address', log.ipAddress != null && log.ipAddress!.isNotEmpty ? log.ipAddress! : '—', isIp: true),
          _metaItem('Date Recorded', dateFormat.format(log.createdAt)),
          _metaItem('Time Recorded', timeFormat.format(log.createdAt)),
          const Divider(color: Colors.white24, height: 32),
          const Text('Source', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.security, size: 16, color: Color(0xFFC06C4D)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified Entry',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, {bool isIp = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: isIp ? 'monospace' : null,
              letterSpacing: isIp ? 0.8 : null,
            ),
          ),
        ],
      ),
    );
  }
}
