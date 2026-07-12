import 'package:capstone_application/views/loans_page.dart';
import 'package:capstone_application/views/users_page.dart';
import 'package:capstone_application/views/activity_logs_page.dart';
import 'package:capstone_application/views/transactions_page.dart';
import 'package:capstone_application/views/update_interest_page.dart';
import 'package:capstone_application/views/admin_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/nav_item_model.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'dashboard_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        return isTablet ? _buildTabletLayout() : _buildPhoneLayout();
      },
    );
  }

  Widget _buildPhoneLayout() {
    return Consumer2<NavigationViewModel, AuthViewModel>(
      builder: (context, nav, auth, _) {
        final filteredItems = nav.getFilteredNavItems();
        
        if (filteredItems.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final bottomItems = nav.getBottomNavItems();
        final drawerItems = nav.getDrawerItems();
        final bottomIndex = nav.getBottomNavIndex();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: _buildPhoneAppBar(context),
          drawer: drawerItems.isNotEmpty
              ? _buildDrawer(nav, auth, drawerItems)
              : null,
          body: _buildPage(filteredItems, nav.selectedIndex),
          bottomNavigationBar: bottomItems.length >= 2
              ? _CompactBottomNav(
            items: bottomItems,
            selectedIndex: bottomIndex,
            onTap: nav.navigateTo,
          )
              : null,
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return Consumer2<NavigationViewModel, AuthViewModel>(
      builder: (context, nav, auth, _) {
        final filteredItems = nav.getFilteredNavItems();

        if (filteredItems.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (auth.isImpersonating) _buildImpersonationBanner(context, auth, nav),
                Expanded(
                  child: Row(
                    children: [
                      _TabletRail(
                        items: filteredItems,
                        selectedIndex: nav.selectedIndex,
                        onDestinationSelected: nav.navigateTo,
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildPage(filteredItems, nav.selectedIndex)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildPhoneAppBar(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Lending System',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen())),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                    ? Image.network(user.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppTheme.primary, size: 18))
                    : const Icon(Icons.person_rounded, color: AppTheme.primary, size: 18),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F1F5)),
      ),
    );
  }

  Widget _buildDrawer(
      NavigationViewModel nav,
      AuthViewModel auth,
      List<NavItemModel> drawerItems,
      ) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: ClipOval(
                        child: (auth.currentUser?.avatarUrl != null && auth.currentUser!.avatarUrl!.isNotEmpty)
                            ? Image.network(auth.currentUser!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20))
                            : const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.fullName ?? 'Lending System',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted.withOpacity(0.7),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  ...drawerItems.map((item) {
                    final allItems = nav.getFilteredNavItems();
                    final itemIndex = allItems.indexOf(item);
                    final isSelected = nav.selectedIndex == itemIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                          size: 20,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppTheme.primary.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          nav.navigateTo(itemIndex);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(List<NavItemModel> items, int selectedIndex) {
    if (items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedIndex >= items.length) {
      return const Center(child: Text('Invalid page selection'));
    }

    final route = items[selectedIndex].route;

    switch (route) {
      case '/dashboard':
        return const DashboardPage();
      case '/loans':
        return const LoansPage();
      case '/users':
        return const UsersPage();
      case '/transactions':
        return const TransactionsPage();
      case '/update-interest':
        return const InterestManagementPage();
      case '/activity-logs':
        return const ActivityLogsPage();
      case '/shareholder-dashboard':
        // 🚀 Redirect to user dashboard if impersonating or is shareholder
        return _placeholderPage(title: 'Shareholder Dashboard', icon: Icons.dashboard_rounded);
      default:
        return _placeholderPage(
          title: route
              .replaceAll('/', '')
              .replaceAll('-', ' ')
              .split(' ')
              .map((w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1)
              : w)
              .join(' '),
          icon: items[selectedIndex].icon,
        );
    }
  }

  Widget _buildImpersonationBanner(BuildContext context, AuthViewModel auth, NavigationViewModel nav) {
    return Container(
      color: Colors.amber[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are currently impersonating ${auth.currentUser?.fullName} (ID: ${auth.currentUser?.id.substring(0, 8)}...).',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.stopImpersonation();
              // Back to users management
              final items = nav.getFilteredNavItems();
              final idx = items.indexWhere((it) => it.route == '/users');
              if (idx != -1) nav.navigateTo(idx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Exit Session'),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPage(
      {required String title, required IconData icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CompactBottomNav extends StatelessWidget {
  final List<NavItemModel> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CompactBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFF0F1F5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabletRail extends StatefulWidget {
  final List<NavItemModel> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _TabletRail({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<_TabletRail> createState() => _TabletRailState();
}

class _TabletRailState extends State<_TabletRail> {
  bool _extended = false;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: _extended
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logoIcon(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Engr Canteen',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Text(
                      'Lending',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            )
                : _logoIcon(),
          ),
          const Divider(height: 1),
          Expanded(
            child: NavigationRail(
              extended: _extended,
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              labelType: _extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              unselectedLabelTextStyle: const TextStyle(
                fontSize: 10,
                color: Colors.transparent, // Hide by default
              ),
              selectedLabelTextStyle: const TextStyle(
                fontSize: 10,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
              leading: const SizedBox.shrink(),
              trailing: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      IconButton(
                        icon: Icon(
                          _extended
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _extended = !_extended),
                        tooltip: _extended ? 'Collapse' : 'Expand',
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen())),
                        tooltip: 'Account Settings',
                      ),
                    ],
                  ),
                ),
              ),
              destinations: widget.items.asMap().entries.map((entry) {
                final int idx = entry.key;
                final item = entry.value;
                final bool isHovered = _hoveredIndex == idx;
                final bool isSelected = widget.selectedIndex == idx;

                return NavigationRailDestination(
                  icon: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = idx),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: Icon(item.icon),
                  ),
                  selectedIcon: Icon(item.activeIcon),
                  label: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: (isSelected || isHovered)
                          ? AppTheme.primary
                          : Colors.transparent,
                    ),
                    child: Text(item.label),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.account_balance_rounded,
          color: Colors.white, size: 18),
    );
  }
}
