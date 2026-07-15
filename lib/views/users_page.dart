import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/user_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_management_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/user_table.dart';
import '../widgets/page_turner.dart';
import '../widgets/import_export_buttons.dart';
import 'shareholder_detail_page.dart';
import 'add_shareholder_page.dart';

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
      context.read<UserManagementViewModel>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, nav, child) {
        final selectedId = nav.selectedShareholderId;

        if (selectedId != null) {
          return ShareholderDetailPage(
            shareholderId: selectedId,
            onBack: () => nav.clearShareholderSelection(),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
                'Users Management',
                style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
            ),
            actions: [
              Consumer<UserManagementViewModel>(
                builder: (context, viewModel, _) => IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                  onPressed: viewModel.refresh,
                  tooltip: 'Refresh',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Consumer<UserManagementViewModel>(
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
                              child: UserTable(
                                users: viewModel.users,
                                isLoading: viewModel.isLoading,
                                onView: (user) {
                                  nav.navigateToShareholder(user.id);
                                },
                                onImpersonate: (user) async {
                                  try {
                                    final repo = context.read<UserRepository>();
                                    final response = await repo.impersonate(user.id);

                                    final authModel = context.read<AuthViewModel>();
                                    await authModel.startImpersonation(response);

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Now impersonating ${user.fullName}'),
                                          backgroundColor: const Color(0xFFC06C4D),
                                        ),
                                      );
                                      // Navigate to appropriate dashboard
                                      final route = authModel.dashboardRoute;
                                      if (route != null) {
                                        // Find dashboard index
                                        final navItems = nav.getFilteredNavItems();
                                        final idx = navItems.indexWhere((it) => it.route == route);
                                        if (idx != -1) nav.navigateTo(idx);
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Impersonation failed: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                onEdit: (user) {
                                  // Handle edit
                                },
                                onDelete: (user) {
                                  // Handle delete
                                },
                              ),
                            ),
                            // Pagination
                            PageTurner(
                              currentPage: viewModel.currentPage,
                              totalPages: viewModel.lastPage,
                              totalRows: viewModel.totalRows,
                              rowsPerPage: viewModel.rowsPerPage,
                              onPageChanged: (page) => viewModel.setPage(page),
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
      },
    );
  }

  Widget _buildActionBar(UserManagementViewModel viewModel) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT GROUP: Search bar and Filters tightly bound together
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      _buildFilterDropdown(
                        label: 'Role',
                        value: viewModel.roleFilter,
                        items: ['All', 'Admin', 'Shareholder'],
                        onChanged: (val) {
                          if (val != null) viewModel.setRoleFilter(val);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        label: 'Status',
                        value: viewModel.statusFilter,
                        items: ['All', 'Active', 'Inactive', 'Suspended', 'Pending'],
                        onChanged: (val) {
                          if (val != null) viewModel.setStatusFilter(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // RIGHT GROUP: Export, Import, and Add Shareholder button rightmost
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ImportExportButtons(
                        type: 'users',
                        onRefresh: viewModel.refresh,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddShareholderPage()),
                          ).then((_) => viewModel.refresh());
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Shareholder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC06C4D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
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