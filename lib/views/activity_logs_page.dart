import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/activity_log_repository.dart';
import '../viewmodels/activity_log_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/activity_log_table.dart';

class ActivityLogsPage extends StatefulWidget {
  final String? shareholderId;
  final String? userId;

  const ActivityLogsPage({
    super.key,
    this.shareholderId,
    this.userId,
  });

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  late ActivityLogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ActivityLogViewModel(
      context.read<ActivityLogRepository>(),
      initialUserId: widget.userId,
    );
    
    // Trigger data load after the first frame to avoid "rebuild during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (widget.shareholderId != null && widget.shareholderId!.isNotEmpty) {
      await _viewModel.fetchRequestsByShareholder(widget.shareholderId!);
    } else {
      await _viewModel.fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
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
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
              onPressed: _loadData,
              tooltip: 'Refresh Logs',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _ActivityLogsBody(onRefresh: _loadData),
      ),
    );
  }
}

class _ActivityLogsBody extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _ActivityLogsBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityLogViewModel>(
      builder: (context, viewModel, _) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: const Color(0xFFC06C4D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, viewModel),
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ActivityLogTable(
                            logs: viewModel.logs,
                            onDelete: (id) => viewModel.deleteLog(id),
                            onEdit: (req) {},
                            onView: (req) {},
                          ),
                          if (viewModel.isLoading)
                            Positioned.fill(
                              child: Container(
                                color: Colors.white.withOpacity(0.6),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PageTurner(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    totalRows: viewModel.totalRows,
                    rowsPerPage: viewModel.rowsPerPage,
                    onPageChanged: viewModel.setPage,
                    onRowsPerPageChanged: (val) {
                      if (val != null) viewModel.setRowsPerPage(val);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ActivityLogViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (viewModel.filteredShareholderId != null)
                  InputChip(
                    label: const Text('Filtered Profile'),
                    onDeleted: () => viewModel.clearShareholderFilter(),
                    deleteIconColor: Colors.white,
                    backgroundColor: const Color(0xFFC06C4D),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                _buildFilterButton(
                  context: context,
                  label: viewModel.selectedDateFilter == 'All' ? 'Filter by Date' : viewModel.selectedDateFilter,
                  viewModel: viewModel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required ActivityLogViewModel viewModel,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF32211A),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFFC06C4D)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onPressed: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFC06C4D),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF32211A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          viewModel.setDateRange(picked.start, picked.end);
        }
      },
    );
  }
}
