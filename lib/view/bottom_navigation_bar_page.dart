import 'package:agendo/view/home_view.dart';
import 'package:agendo/view/notifications_view.dart';
import 'package:agendo/view/profile_view.dart';
import 'package:agendo/view/search_view.dart';
import 'package:flutter/material.dart';

const _kPages = <Widget>[
  HomeView(),
  SearchView(),
  ProfileView(),
  NotificationsView(),
];

const _kNavDestinations = <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
  NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Busca'),
  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
  NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notificações'),
];

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() => _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return _DesktopLayout(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    return _MobileLayout(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
    );
  }
}

// ── Mobile Layout ──────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _MobileLayout({required this.selectedIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _kPages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        indicatorColor: colors.primary.withValues(alpha: 0.2),
        backgroundColor: colors.surface,
        destinations: _kNavDestinations,
      ),
    );
  }
}

// ── Desktop Layout ─────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _DesktopLayout({required this.selectedIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: MediaQuery.of(context).size.width >= 1100,
            backgroundColor: colors.surface,
            indicatorColor: colors.primary.withValues(alpha: 0.15),
            selectedIconTheme: IconThemeData(color: colors.primary),
            unselectedIconTheme: IconThemeData(color: colors.onSurface.withValues(alpha: 0.5)),
            selectedLabelTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.calendar_month_rounded, color: colors.primary, size: 32),
                  if (MediaQuery.of(context).size.width >= 1100) ...[
                    const SizedBox(height: 4),
                    Text('Agendo', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Busca')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Perfil')),
              NavigationRailDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: Text('Notificações')),
            ],
          ),

          // Divider
          VerticalDivider(thickness: 1, width: 1, color: colors.onSurface.withValues(alpha: 0.08)),

          // Content
          Expanded(child: _kPages[selectedIndex]),
        ],
      ),
    );
  }
}
