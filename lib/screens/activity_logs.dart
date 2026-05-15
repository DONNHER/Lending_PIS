import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/logs_viewmodel.dart';
import 'package:intl/intl.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFF5E6DA);
  static const Color borderLine = Color(0xFFE6DED8);
  static const Color darkBrown = Color(0xFF3A2318);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogsViewModel>().loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActivityLogsViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final double horizontalPadding = isSmallScreen ? 12.0 : 24.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: isSmallScreen
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton("Date"),
                          const SizedBox(width: 8),
                          _buildExportButton(true, viewModel),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        _buildFilterButton("Date"),
                        const Spacer(),
                        _buildExportButton(false, viewModel),
                      ],
                    ),
            ),
            Expanded(
              child: _buildBody(viewModel, horizontalPadding, isSmallScreen),
            ),
            _buildFooter(horizontalPadding, isSmallScreen, viewModel),
          ],
        );
      },
    );
  }

  Widget _buildBody(ActivityLogsViewModel viewModel, double hPadding, bool isSmall) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: terracotta));
    }

    if (viewModel.activities.isEmpty) {
      return const Center(child: Text("No activity logs found."));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLine),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: isSmall ? 16 : 24,
              headingRowHeight: 56,
              headingRowColor: WidgetStateProperty.all(terracotta),
              columns: const [
                DataColumn(label: Text('Type', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Description', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
              ],
              rows: viewModel.activities.map((activity) => _buildLogRow(activity)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildLogRow(LendingActivity activity) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) return accentPeach;
        return Colors.white;
      }),
      cells: [
        DataCell(_buildTypeIcon(activity.type)),
        DataCell(Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(dateFormat.format(activity.timestamp))),
        DataCell(Text(activity.description)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.info_outline, size: 18, color: Colors.blue), onPressed: () {}),
          ],
        )),
      ],
    );
  }

  Widget _buildTypeIcon(ActivityType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ActivityType.loan:
        icon = Icons.monetization_on_outlined;
        color = terracotta;
        break;
      case ActivityType.payment:
        icon = Icons.payments_outlined;
        color = Colors.green;
        break;
      case ActivityType.shareholder:
        icon = Icons.person_add_outlined;
        color = Colors.blue;
        break;
      default:
        icon = Icons.settings_suggest_outlined;
        color = Colors.grey;
    }
    return Icon(icon, size: 18, color: color);
  }

  Widget _buildFooter(double hPadding, bool isSmall, ActivityLogsViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSmall)
            Text("Showing ${viewModel.activities.length} results", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(
            children: [
              const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              _buildPageNumber("1", true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: darkBrown),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(String n, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? darkBrown : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(n, style: TextStyle(color: isActive ? Colors.white : darkBrown, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildFilterButton(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: borderLine), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const Icon(Icons.keyboard_arrow_down, size: 16)
    ]),
  );

  Widget _buildExportButton(bool isSmall, ActivityLogsViewModel viewModel) => OutlinedButton.icon(
    onPressed: () => viewModel.loadActivities(), 
    icon: const Icon(Icons.refresh_rounded, size: 18, color: darkBrown), 
    label: Text(isSmall ? "Sync" : "Refresh Logs", style: const TextStyle(color: darkBrown, fontSize: 13)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: borderLine),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16),
    ),
  );
}
