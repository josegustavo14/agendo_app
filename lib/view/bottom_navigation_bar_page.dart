import 'package:agendo/view/appointment_history_view.dart';
import 'package:agendo/view/appointments_view.dart';
import 'package:agendo/view/availability_view.dart';
import 'package:agendo/view/home_view.dart';
import 'package:agendo/view/profile_view.dart';
import 'package:agendo/view/professional_home_view.dart';
import 'package:agendo/view/select_profession_view.dart';
import 'package:agendo/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// CLIENT
const _clientPages = <Widget>[
  HomeView(),
  SelectProfessionView(),
  AppointmentHistoryView(),
  ProfileView(),
];

const _clientDestinations = <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
  NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
  NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Histórico'),
  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
];

const _clientRailDestinations = <NavigationRailDestination>[
  NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
  NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Buscar')),
  NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Histórico')),
  NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Perfil')),
];

// PROFESSIONAL
final _professionalPages = <Widget>[
  const ProfessionalHomeView(),
  const AppointmentsView(role: 'professional'),
  const AvailabilityView(),
  const ProfileView(),
];

const _professionalDestinations = <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
  NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Agenda'),
  NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Horários'),
  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
];

const _professionalRailDestinations = <NavigationRailDestination>[
  NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
  NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: Text('Agenda')),
  NavigationRailDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: Text('Horários')),
  NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Perfil')),
];

// ── Widget ────────────────────────────────────────────────────────────────────

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() => _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? 'CLIENT';
    final isProfessional = role == 'PROFESSIONAL';
    final isWide = MediaQuery.of(context).size.width >= 800;

    final pages = isProfessional ? _professionalPages : _clientPages;
    final destinations = isProfessional ? _professionalDestinations : _clientDestinations;
    final railDests = isProfessional ? _professionalRailDestinations : _clientRailDestinations;
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    if (isWide) {
      return _DesktopLayout(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        pages: pages,
        railDestinations: railDests,
      );
    }

    return _MobileLayout(
      selectedIndex: safeIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      pages: pages,
      destinations: destinations,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> pages;
  final List<NavigationDestination> destinations;

  const _MobileLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pages,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        indicatorColor: colors.primary.withValues(alpha: 0.2),
        backgroundColor: colors.surface,
        destinations: destinations,
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> pages;
  final List<NavigationRailDestination> railDestinations;

  const _DesktopLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pages,
    required this.railDestinations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
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
            destinations: railDestinations,
          ),
          VerticalDivider(thickness: 1, width: 1, color: colors.onSurface.withValues(alpha: 0.08)),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
