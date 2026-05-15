import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/shareholders_viewmodel.dart'; 
import 'package:capstone_application/models/lending_models/shareholder.dart';
import 'package:capstone_application/screens/managements/add_shareholder.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Brand Colors
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFFDFBFA); // Background
  static const Color hoverColor = Color(0xFFF5E6DA);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareholderViewModel>().loadShareholders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShareholderViewModel>();

    return Scaffold(
      backgroundColor: accentPeach,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 600;
          final double horizontalPadding = isSmallScreen ? 12.0 : 24.0;

          return Column(
            children: [
              // ── Header Controls ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
                child: _buildResponsiveHeader(isSmallScreen, viewModel),
              ),

              // ── Main Content Area ─────────────────────────────────────────
              Expanded(
                child: _buildBody(viewModel, horizontalPadding),
              ),

              // ── Footer ────────────────────────────────────────────────────
              _buildFooter(viewModel, horizontalPadding),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResponsiveHeader(bool isSmallScreen, ShareholderViewModel viewModel) {
    final List<Widget> actions = [
      _buildFilterButton(Icons.group_outlined, "Role"),
      const SizedBox(width: 8),
      _buildFilterButton(null, "Status"),
      const SizedBox(width: 8),
      _buildActionOutlineButton(Icons.refresh_rounded, "Refresh", () => viewModel.loadShareholders()),
      const SizedBox(width: 8),
      _buildAddShareholderButton(),
    ];

    if (isSmallScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: actions),
      );
    }

    return Row(
      children: [
        _buildFilterButton(Icons.group_outlined, "Filter By"),
        const SizedBox(width: 8),
        _buildFilterButton(null, "Status"),
        const Spacer(),
        ...actions.sublist(4), // Refresh and Add
      ],
    );
  }

  Widget _buildBody(ShareholderViewModel viewModel, double hPadding) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: terracotta));
    }

    final displayList = viewModel.shareholders;

    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? "No shareholders found.",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                horizontalMargin: 20,
                columnSpacing: 24,
                headingRowHeight: 56,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingRowColor: WidgetStateProperty.all(terracotta),
                columns: const [
                  DataColumn(label: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Full Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ownership', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Investment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Joined Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: displayList.map((s) => _buildUserRow(s)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(ShareholderModel shareholder) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);
    
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) return hoverColor; 
        return Colors.white; 
      }),
      cells: [
        DataCell(Text("#${shareholder.id}", style: const TextStyle(fontSize: 13, color: Colors.grey))),
        DataCell(Text(shareholder.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: darkBrown))),
        DataCell(_buildPercentageBadge(shareholder.ownershipPercentage)),
        DataCell(Text(currencyFormat.format(shareholder.totalInvestment), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(shareholder.joinedAt != null ? dateFormat.format(shareholder.joinedAt!) : '-')),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(Icons.edit_outlined, Colors.green, () {}),
            _buildIconButton(Icons.delete_outline, Colors.red, () {}),
            _buildIconButton(Icons.visibility_outlined, darkBrown, () {}),
          ],
        )),
      ],
    );
  }

  // --- Helper UI Components ---

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  Widget _buildPercentageBadge(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: terracotta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: terracotta.withOpacity(0.2)),
      ),
      child: Text(
        "${percentage.toStringAsFixed(1)}%", 
        style: const TextStyle(color: terracotta, fontSize: 12, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildFooter(ShareholderViewModel viewModel, double hPadding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${viewModel.shareholders.length} shareholders", 
            style: const TextStyle(color: Colors.grey, fontSize: 13)
          ),
          const Row(
            children: [
              IconButton(icon: Icon(Icons.chevron_left), onPressed: null),
              SizedBox(width: 8),
              IconButton(icon: Icon(Icons.chevron_right, color: terracotta), onPressed: null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(IconData? icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderLine), 
      borderRadius: BorderRadius.circular(8)
    ),
    child: InkWell(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(icon != null) ...[Icon(icon, size: 16, color: darkBrown), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 13, color: darkBrown)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey)
        ]
      ),
    ),
  );

  Widget _buildActionOutlineButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
    onPressed: onTap, 
    icon: Icon(icon, size: 16, color: darkBrown), 
    label: Text(label, style: const TextStyle(color: darkBrown, fontSize: 13)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: borderLine), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  Widget _buildAddShareholderButton() => ElevatedButton.icon(
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddShareholderPage()));
    }, 
    icon: const Icon(Icons.add, size: 18, color: Colors.white), 
    label: const Text("New Shareholder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(
      backgroundColor: terracotta, 
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}