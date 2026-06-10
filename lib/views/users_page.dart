import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';
import '../viewmodels/shareholder_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/shareholder_table.dart';
import '../widgets/user_table.dart';
import 'add_shareholder_page.dart';
import 'shareholder_detail_page.dart';
import 'admin_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _isNavigating = false;

  Future<void> _handleView(BuildContext context, ShareholderModel user, ShareholderViewModel viewModel) async {
    // 1. Sanitize IDs
    final String? shId = (user.id.isNotEmpty && user.id.toLowerCase() != 'null') ? user.id : null;
    final String? uId = (user.userId.isNotEmpty && user.userId.toLowerCase() != 'null') ? user.userId : null;

    // 🚀 LOUD DEBUG LOGS
    debugPrint('**************************************************');
    debugPrint('DEBUG: [UsersPage] NAVIGATION REQUEST STARTED');
    debugPrint('DEBUG: [UsersPage] User: ${user.fullName}');
    debugPrint('DEBUG: [UsersPage] Role: ${user.role}');
    debugPrint('DEBUG: [UsersPage] Shareholder ID (shId): "$shId"');
    debugPrint('DEBUG: [UsersPage] User ID (uId): "$uId"');
    debugPrint('DEBUG: [UsersPage] Raw Map: ${user.toJson()}');
    debugPrint('**************************************************');

    setState(() => _isNavigating = true);

    try {
      if (user.role.toLowerCase() == 'admin' || user.role.toLowerCase() == 'cashier') {
        debugPrint('DEBUG: [UsersPage] Target -> AdminDetailPage');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDetailPage(userId: uId ?? ''),
          ),
        );
      } else {
        debugPrint('DEBUG: [UsersPage] Target -> ShareholderDetailPage');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareholderDetailPage(
              shareholderId: shId,
              userId: uId,
            ),
          ),
        );
      }
      
      if (mounted) {
        viewModel.fetchShareholders(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('DEBUG: [UsersPage] CRITICAL NAVIGATION ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareholderViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'User Management', 
              style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                onPressed: () => viewModel.fetchShareholders(forceRefresh: true),
                tooltip: 'Refresh Users',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async => viewModel.fetchShareholders(forceRefresh: true),
                  color: const Color(0xFFC06C4D),
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
                                viewModel.selectedRole == 'Shareholder'
                                    ? ShareholderTable(
                                        shareholders: viewModel.shareholders,
                                        onView: (user) => _handleView(context, user, viewModel),
                                      )
                                    : UserTable(
                                        users: viewModel.shareholders,
                                        onView: (user) => _handleView(context, user, viewModel),
                                      ),
                                
                                if (viewModel.isLoading && !viewModel.isInitialized)
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
              ),
              // 🚀 GLOBAL NAVIGATION OVERLAY
              if (_isNavigating)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFFC06C4D)),
                            const SizedBox(height: 20),
                            const Text(
                              'Loading Profile...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please wait while we fetch the details',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton(
                    label: 'All',
                    isActive: viewModel.selectedRole == 'All',
                    onPressed: () => viewModel.setSelectedRole('All'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'Admin',
                    isActive: viewModel.selectedRole == 'Admin',
                    onPressed: () => viewModel.setSelectedRole('Admin'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'Shareholder',
                    isActive: viewModel.selectedRole == 'Shareholder',
                    onPressed: () => viewModel.setSelectedRole('Shareholder'),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 16),
                  _buildFilterButton(
                    label: 'By Name',
                    isActive: isByNameActive,
                    onPressed: () => viewModel.setSortBy('Name'),
                  ),
                  if (viewModel.selectedRole == 'Shareholder') ...[
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      label: 'By Capital',
                      isActive: isByCapitalActive,
                      onPressed: () => viewModel.setSortBy('Amount'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
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
                    viewModel.fetchShareholders(forceRefresh: true);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add User'),
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
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
