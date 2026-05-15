import 'package:capstone_application/screens/dashboard.dart';
import 'package:capstone_application/screens/activity_logs.dart';
import 'package:capstone_application/screens/fund_management.dart';
import 'package:capstone_application/screens/loan_request_management.dart';
import 'package:capstone_application/screens/transaction_management.dart';
import 'package:capstone_application/screens/user_management.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/nav_item_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  // Centralized Background Color to match your pages
  static const Color backgroundPeach = Color(0xFFFDFBFA);

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    final auth = context.watch<AuthViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // We use 900 as a standard desktop/tablet breakpoint
        final isLargeScreen = constraints.maxWidth >= 900;
        
        return Scaffold(
          backgroundColor: backgroundPeach,
          // Only show AppBar on mobile/small screens
          appBar: !isLargeScreen ? _buildPhoneAppBar(context, auth, nav) : null,
          drawer: !isLargeScreen ? _buildDrawer(context, nav, auth) : null,
          body: isLargeScreen 
              ? _buildTabletLayout(context, nav, auth) 
              : _buildPhoneLayout(context, nav),
          bottomNavigationBar: !isLargeScreen ? _buildBottomNav(nav) : null,
        );
      },
    );
  }

  // ── Phone/Mobile Layout ───────────────────────────────────────────────────
  Widget _buildPhoneLayout(NavigationViewModel nav) {
    final filteredItems = nav.getFilteredNavItems();
    return SafeArea(
      child: _buildPage(filteredItems, nav.selectedIndex),
    );
  }

  // ── Tablet/Desktop Layout (Side Bar) ──────────────────────────────────────
  Widget _buildTabletLayout(BuildContext context, NavigationViewModel nav, AuthViewModel auth) {
    final filteredItems = nav.getFilteredNavItems();

    return Row(
      children: [
        // FIXED SIDEBAR: It occupies its own space, pushing the body to the right
        _TabletRail(
          items: filteredItems,
          selectedIndex: nav.selectedIndex,
          onDestinationSelected: nav.navigateTo,
          auth: auth,
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE6DED8)),
        // EXPANDED BODY: Takes the remaining horizontal space
        Expanded(
          child: Column(
            children: [
              // Custom Header for Tablet since AppBar is hidden
              _buildTabletHeader(filteredItems, nav.selectedIndex, auth, context),
              Expanded(
                child: _buildPage(filteredItems, nav.selectedIndex),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header for Tablet (Replaces AppBar) ──────────────────────────────────
  Widget _buildTabletHeader(List<NavItemModel> items, int index, AuthViewModel auth, BuildContext context) {
    String title = items.isNotEmpty ? items[index].label : "Lending System";
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6DED8))),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3A2318))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _buildProfileButton(context, auth),
        ],
      ),
    );
  }

  // ── App Bar (Mobile) ──────────────────────────────────────────────────────
  AppBar _buildPhoneAppBar(BuildContext context, AuthViewModel auth, NavigationViewModel nav) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: const Text('Engr Canteen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF3A2318))),
      iconTheme: const IconThemeData(color: Color(0xFF3A2318)),
      actions: [
        _buildProfileButton(context, auth),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileButton(BuildContext context, AuthViewModel auth) {
    return InkWell(
      onTap: () => _showProfileMenu(context, auth),
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.person, size: 20, color: Colors.white),
      ),
    );
  }

  // ── Bottom Nav Logic ──────────────────────────────────────────────────────
  Widget? _buildBottomNav(NavigationViewModel nav) {
    final bottomItems = nav.getBottomNavItems();
    if (bottomItems.length < 2) return null;

    return _CompactBottomNav(
      items: bottomItems,
      selectedIndex: nav.getBottomNavIndex(),
      onTap: nav.navigateTo,
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, NavigationViewModel nav, AuthViewModel auth) {
    final drawerItems = nav.getDrawerItems();
    return Drawer(
      backgroundColor: backgroundPeach,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            accountName: const Text("Administrator", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(auth.currentUserEmail ?? "admin@system.com"),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppTheme.primary)),
          ),
          Expanded(
            child: ListView(
              children: drawerItems.map((item) {
                final allItems = nav.getFilteredNavItems();
                final index = allItems.indexOf(item);
                return ListTile(
                  leading: Icon(item.icon, color: nav.selectedIndex == index ? AppTheme.primary : Colors.grey),
                  title: Text(item.label, style: TextStyle(color: nav.selectedIndex == index ? AppTheme.primary : const Color(0xFF3A2318))),
                  selected: nav.selectedIndex == index,
                  onTap: () {
                    Navigator.pop(context);
                    nav.navigateTo(index);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthViewModel auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Account Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Page Router ───────────────────────────────────────────────────────────
  Widget _buildPage(List<NavItemModel> items, int selectedIndex) {
    if (items.isEmpty) return const Center(child: Text("Access Denied"));
    if (selectedIndex < 0 || selectedIndex >= items.length) selectedIndex = 0;

    final route = items[selectedIndex].route;

    switch (route) {
      case '/dashboard': return const DashboardPage();
      case '/loan-requests': return const LoanRequestManagementPage();
      case '/activity-logs': return const ActivityLogsPage();
      case '/fund-management': return const FundManagementPage();
      case '/shareholders': return const UserManagementPage();
      case '/transactions': return const TransactionManagementPage();
      default: return Center(child: Text('Route $route not implemented'));
    }
  }
}

// ── Supporting Widgets ──────────────────────────────────────────────────────

class _CompactBottomNav extends StatelessWidget {
  final List<NavItemModel> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _CompactBottomNav({required this.items, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE6DED8)))),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        items: items.map((i) => BottomNavigationBarItem(
          icon: Icon(i.icon), 
          activeIcon: Icon(i.activeIcon),
          label: i.label,
        )).toList(),
      ),
    );
  }
}

class _TabletRail extends StatelessWidget {
  final List<NavItemModel> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AuthViewModel auth;

  const _TabletRail({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      minWidth: 80,
      leading: const Column(
        children: [
          SizedBox(height: 24),
          Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 32),
          SizedBox(height: 24),
        ],
      ),
      destinations: items.map((i) => NavigationRailDestination(
        icon: Icon(i.icon, color: Colors.grey), 
        selectedIcon: Icon(i.activeIcon, color: AppTheme.primary),
        label: Text(i.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }
}