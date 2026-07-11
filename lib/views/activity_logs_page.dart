import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/activity_log_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/activity_log_table.dart';
import '../widgets/page_turner.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<ActivityLogViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
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
                          color: Colors.black.withOpacity(0.02),
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
                            isLoading: viewModel.isLoading && viewModel.logs.isEmpty,
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Text(
            'Activity Logs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const Spacer(),
          IconButton(
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}
