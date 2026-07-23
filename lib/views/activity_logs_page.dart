import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/activity_log_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/activity_log_table.dart';
import '../widgets/page_turner.dart';
import '../widgets/import_export_buttons.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogViewModel>().fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
            'Activity Logs',
            style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        actions: [
          Consumer<ActivityLogViewModel>(
            builder: (context, viewModel, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
              onPressed: viewModel.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ActivityLogViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // 🚀 Thin Loading Indicator right below the App Bar header
              if (viewModel.isLoading)
                const LinearProgressIndicator(
                  color: Color(0xFFC06C4D),
                  backgroundColor: Color(0xFFFDF8F5),
                  minHeight: 3,
                )
              else
                const SizedBox(height: 3),

              _buildActionBar(viewModel),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: ActivityLogTable(
                            logs: viewModel.logs,
                            isLoading: viewModel.isLoading,
                          ),
                        ),
                        PageTurner(
                          currentPage: viewModel.currentPage,
                          totalPages: viewModel.lastPage,
                          totalRows: viewModel.totalRows,
                          rowsPerPage: viewModel.rowsPerPage,
                          onPageChanged: viewModel.setPage,
                          onRowsPerPageChanged: (val) {
                            if (val != null) viewModel.setRowsPerPage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionBar(ActivityLogViewModel viewModel) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 48), // Adjust for horizontal padding
              child: Row(
                children: [
                  // Constrained search field container
                  SizedBox(
                    width: 300,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        onChanged: viewModel.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search user, action, or details...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFC06C4D)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    label: 'Type',
                    value: viewModel.typeFilter,
                    items: ['All', 'Info', 'Warning', 'Error', 'Success', 'Auth', 'Transaction', 'Access'],
                    onChanged: (val) {
                      if (val != null) viewModel.setTypeFilter(val);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    label: 'Sort By',
                    value: viewModel.sortOrder,
                    items: ['Newest', 'Oldest'],
                    onChanged: (val) {
                      if (val != null) viewModel.setSortOrder(val);
                    },
                  ),
                  const SizedBox(width: 32),
                  const SizedBox(width: 16),
                  ImportExportButtons(
                    type: 'activity-logs',
                    onRefresh: viewModel.refresh,
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            items: items.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}