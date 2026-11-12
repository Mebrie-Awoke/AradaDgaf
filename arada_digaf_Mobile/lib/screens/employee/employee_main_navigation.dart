import 'package:flutter/material.dart';
import '../../state/app_scope.dart';
import 'employee_home_screen.dart';
import 'my_tickets_screen.dart';
import '../common/profile_screen.dart';

class EmployeeMainNavigation extends StatefulWidget {
  final int initialIndex;

  const EmployeeMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<EmployeeMainNavigation> createState() => _EmployeeMainNavigationState();
}

class _EmployeeMainNavigationState extends State<EmployeeMainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchToMyTickets() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    final screens = [
      EmployeeHomeScreen(onViewMyTickets: _switchToMyTickets),
      const MyTicketsScreen(),
      const ProfileScreen(),
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
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: s.get('nav_my_tickets'),
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
