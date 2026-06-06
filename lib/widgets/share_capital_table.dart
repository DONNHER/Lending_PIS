import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/share_capital_model.dart';

class ShareCapitalTable extends StatelessWidget {
  final List<ShareCapitalModel> shareCapitals;
  final Function(String) onDelete;
  final Function(ShareCapitalModel) onEdit;
  final Function(ShareCapitalModel) onView;

  const ShareCapitalTable({
    super.key,
    required this.shareCapitals,
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
              Expanded(flex: 2, child: Text('Fund ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 3, child: Text('Source/Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Total Capital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Created At', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: shareCapitals.isEmpty 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No records found', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            : ListView.separated(
                itemCount: shareCapitals.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => onView(shareCapitals[index]),
                    child: _buildRow(shareCapitals[index]),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildRow(ShareCapitalModel capital) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          // Fund ID
          Expanded(flex: 2, child: Text(capital.fundId, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          
          // Source/Member
          Expanded(
            flex: 3,
            child: Text(
              capital.source,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),

          // Total Capital
          Expanded(
            flex: 2,
            child: Text(
              '₱${currencyFormat.format(capital.amount)}', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
          ),

          // Created At
          Expanded(
            flex: 2,
            child: Text(
              dateFormat.format(capital.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(icon: Icons.chevron_right, color: AppTheme.textMuted, onTap: () => onView(capital)),
              ],
            ),
          ),
        ],
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
