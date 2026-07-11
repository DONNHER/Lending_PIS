import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shareholder_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/shareholder_table.dart';
import '../widgets/page_turner.dart';
import 'shareholder_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareholderViewModel>().fetchShareholders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<ShareholderViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // Search and Action Bar
              _buildActionBar(viewModel),

              // Table Content
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
                          child: ShareholderTable(
                            shareholders: viewModel.shareholders,
                            isLoading: viewModel.isLoading && viewModel.shareholders.isEmpty,
                            onView: (shareholder) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShareholderDetailPage(shareholderId: shareholder.id),
                                ),
                              );
                            },
                          ),
                        ),
                        // Pagination
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

  Widget _buildActionBar(ShareholderViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Shareholders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const Spacer(),
              // Search Field
              SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFC06C4D)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  onChanged: viewModel.setSearch,
                ),
              ),
              const SizedBox(width: 12),
              // Refresh Button
              IconButton(
                onPressed: viewModel.refresh,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFilterDropdown(
                label: 'Sort By',
                value: viewModel.sortOrder,
                items: ['Name (A-Z)', 'Name (Z-A)', 'Highest Capital', 'Highest Score'],
                onChanged: (val) {
                  if (val != null) viewModel.setSortOrder(val);
                },
              ),
            ],
          ),
        ],
      ),
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
