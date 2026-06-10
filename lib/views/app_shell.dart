import 'package:capstone_application/views/loans_page.dart';
import 'package:capstone_application/views/users_page.dart';
import 'package:capstone_application/views/activity_logs_page.dart';
import 'package:capstone_application/views/transactions_page.dart';
import 'package:capstone_application/views/update_interest_page.dart';
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
        
        // If items are loading or role is not yet set in NavViewModel
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
          appBar: _buildPhoneAppBar(drawerItems),
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
        );
      },
    );
  }

  AppBar _buildPhoneAppBar(List<NavItemModel> drawerItems) {
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
            'Engr Canteen',
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
            onTap: () => _showProfileMenu(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 18,
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
                    child: const Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 11),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engr Canteen',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Lending',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
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
                      'MORE',
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
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              child: const Icon(Icons.person_rounded,
                  color: AppTheme.primary, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            if (user != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.name[0].toUpperCase() +
                      user.role.name.substring(1),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.pop(context);
                auth.logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
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
        return TransactionsPage();
      case '/update-interest':
        return const UpdateInterestPage();
      case '/activity-logs':
        return ActivityLogsPage();
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
              children: [
                _logoIcon(),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engr Canteen',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Lending',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
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
                  : NavigationRailLabelType.selected,
              leading: const SizedBox.shrink(),
              trailing: Expanded(
                child: Align(
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
                            Icons.account_circle_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () {
                            final auth = context.read<AuthViewModel>();
                            final user = auth.currentUser;
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              builder: (_) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 12, 24, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius:
                                        BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppTheme.primary
                                          .withOpacity(0.12),
                                      child: const Icon(
                                          Icons.person_rounded,
                                          color: AppTheme.primary,
                                          size: 30),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      user?.fullName ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      user?.email ?? '',
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 20),
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                          Icons.logout_rounded,
                                          size: 16),
                                      label: const Text('Logout'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        side: const BorderSide(
                                            color: AppTheme.error),
                                        minimumSize:
                                        const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        auth.logout();
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                            '/login', (route) => false);
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            );
                          },
                          tooltip: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: widget.items
                  .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: Text(item.label),
              ))
                  .toList(),
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
