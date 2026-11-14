import 'package:flutter/material.dart';
import '../../core/painters.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';
import '../common/notifications_screen.dart';
import 'new_ticket_flow.dart';

class EmployeeHomeScreen extends StatelessWidget {
  final VoidCallback onViewMyTickets;

  const EmployeeHomeScreen({super.key, required this.onViewMyTickets});

  void _openNewTicket(
    BuildContext context, {
    ServiceCategory? category,
    DeviceType? deviceType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewTicketFlow(
          initialCategory: category,
          initialDeviceType: deviceType,
          onViewMyTickets: onViewMyTickets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final isAmharic = state.language.isAmharic;
    final user = state.currentUser;
    final firstName = user?.fullName.split(' ').first ?? 'Selam';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('app_name')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                if (state.unreadNotificationsCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.badgeRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${state.unreadNotificationsCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting Card with Vector Illustration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.get('hello')}, $firstName!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.get('how_can_we_help'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Vector illustration of woman at desk with laptop
                    const EmployeeIllustration(width: 90, height: 80),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Big Green "+ New Ticket / አዲስ ጥያቄ" Button
              InkWell(
                onTap: () => _openNewTicket(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withAlpha(70),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            s.get('new_ticket'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            s.getOther('new_ticket'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Services Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.get('quick_services'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s.getOther('quick_services'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Services 2x2 Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.35,
                children: [
                  _buildQuickServiceCard(
                    title: isAmharic ? 'ኮምፒውተር' : 'Computer',
                    subtitle: isAmharic ? 'Computer' : 'ኮምፒውተር',
                    icon: Icons.computer,
                    onTap: () => _openNewTicket(
                      context,
                      category: ServiceCategory.maintenance,
                      deviceType: DeviceType.computer,
                    ),
                  ),
                  _buildQuickServiceCard(
                    title: isAmharic ? 'ፕሪንተር' : 'Printer',
                    subtitle: isAmharic ? 'Printer' : 'ፕሪንተር',
                    icon: Icons.print_outlined,
                    onTap: () => _openNewTicket(
                      context,
                      category: ServiceCategory.maintenance,
                      deviceType: DeviceType.printer,
                    ),
                  ),
                  _buildQuickServiceCard(
                    title: isAmharic ? 'ኔትወርክ' : 'Network',
                    subtitle: isAmharic ? 'Network' : 'ኔትወርክ',
                    icon: Icons.wifi,
                    onTap: () => _openNewTicket(
                      context,
                      category: ServiceCategory.maintenance,
                      deviceType: DeviceType.network,
                    ),
                  ),
                  _buildQuickServiceCard(
                    title: isAmharic ? 'ሶፍትዌር' : 'Software',
                    subtitle: isAmharic ? 'Software' : 'ሶፍትዌር',
                    icon: Icons.grid_view,
                    onTap: () => _openNewTicket(
                      context,
                      category: ServiceCategory.software,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

