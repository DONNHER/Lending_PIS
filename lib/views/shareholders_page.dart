import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/shareholder_repository.dart';
import '../viewmodels/shareholder_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/shareholder_table.dart';
import 'add_shareholder_page.dart';
import 'shareholder_detail_page.dart';

class ShareholdersPage extends StatelessWidget {
  const ShareholdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShareholderViewModel(context.read<ShareholderRepository>()),
      child: const _ShareholdersBody(),
    );
  }
}

class _ShareholdersBody extends StatelessWidget {
  const _ShareholdersBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareholderViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, viewModel),
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                        children: [
                          ShareholderTable(
                            shareholders: viewModel.shareholders,
                            onView: (shareholder) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShareholderDetailPage(shareholderId: shareholder.id),
                                ),
                              ).then((_) => viewModel.fetchShareholders());
                            },
                          ),
                          if (viewModel.isLoading)
                            Container(
                              color: Colors.white.withOpacity(0.6),
                              child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                PageTurner(
                  currentPage: viewModel.currentPage,
                  totalPages: viewModel.totalPages,
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
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ShareholderViewModel viewModel) {
    final bool isByNameActive = viewModel.sortBy == 'Name';
    final bool isByCapitalActive = viewModel.sortBy == 'Amount';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFilterButton(
                label: 'By Name',
                isActive: isByNameActive,
                onPressed: () => viewModel.setSortBy('Name'),
              ),
              const SizedBox(width: 12),
              _buildFilterButton(
                label: 'By Capital',
                isActive: isByCapitalActive,
                onPressed: () => viewModel.setSortBy('Amount'),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  minimumSize: const Size(0, 0),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddShareholderPage()),
                  );
                  if (result == true) {
                    viewModel.fetchShareholders();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Shareholder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC06C4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  minimumSize: const Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC06C4D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFFC06C4D) : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                null,
                size: 16,
                color: isActive ? Colors.white : AppTheme.textDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
