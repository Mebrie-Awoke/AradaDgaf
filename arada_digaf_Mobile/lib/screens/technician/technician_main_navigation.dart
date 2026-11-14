import 'package:flutter/material.dart';
import '../../state/app_scope.dart';
import 'technician_home_screen.dart';
import '../common/profile_screen.dart';

class TechnicianMainNavigation extends StatefulWidget {
  final int initialIndex;

  const TechnicianMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<TechnicianMainNavigation> createState() =>
      _TechnicianMainNavigationState();
}

class _TechnicianMainNavigationState extends State<TechnicianMainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    final screens = const [
      TechnicianHomeScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: s.get('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: s.get('nav_profile'),
          ),
        ],
      ),
    );
  }
}
