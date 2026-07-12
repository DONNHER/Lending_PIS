import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class RateHistoryTable extends StatelessWidget {
  final List<dynamic> history;
  final bool isLoading;

  const RateHistoryTable({
    super.key,
    required this.history,
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
              Expanded(flex: 2, child: Text('Old Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('New Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 4, child: Text('Reason for Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Date Applied', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D)))
            : history.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No rate history found', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : ListView.separated(
                  itemCount: history.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, index) {
                    final item = history[index];
                    return InkWell(
                      onTap: () {},
                      hoverColor: const Color(0xFFC06C4D).withOpacity(0.05),
                      child: _buildRow(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(dynamic item) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    DateTime createdAt;
    try {
      createdAt = item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    final oldRate = double.tryParse(item['old_rate']?.toString() ?? '0') ?? 0.0;
    final newRate = double.tryParse(item['new_rate']?.toString() ?? '0') ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2, 
            child: Text(
              '${(oldRate * 100).toStringAsFixed(1)}%', 
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, decoration: TextDecoration.lineThrough)
            )
          ),
          Expanded(
            flex: 2, 
            child: Text(
              '${(newRate * 100).toStringAsFixed(1)}%', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC06C4D))
            )
          ),
          Expanded(
            flex: 4, 
            child: Text(
              item['reason']?.toString() ?? 'No reason provided',
              style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          ),
          Expanded(
            flex: 3, 
            child: Text(
              dateFormat.format(createdAt), 
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)
            )
          ),
        ],
      ),
    );
  }
}
