import 'package:flutter/material.dart';
import '../../core/ethiopian_date.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';
import 'ticket_details_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  TicketStatus? _selectedStatusFilter; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final isAmharic = state.language.isAmharic;

    final query = _searchController.text.trim().toLowerCase();
    final filteredTickets = state.tickets.where((ticket) {
      if (_selectedStatusFilter != null && ticket.status != _selectedStatusFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesId = ticket.id.toLowerCase().contains(query);
        final matchesCategory = ticket.category.labelEn.toLowerCase().contains(query) ||
            ticket.category.labelAm.contains(query);
        final matchesProblem = ticket.problemDescription.toLowerCase().contains(query);
        if (!matchesId && !matchesCategory && !matchesProblem) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('my_tickets')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: s.get('search_tickets_hint'),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips (All, Submitted, In Progress, Resolved)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: s.get('all'),
                          isSelected: _selectedStatusFilter == null,
                          onSelected: () => setState(() => _selectedStatusFilter = null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAmharic ? TicketStatus.submitted.labelAm : TicketStatus.submitted.labelEn,
                          isSelected: _selectedStatusFilter == TicketStatus.submitted,
                          onSelected: () => setState(() => _selectedStatusFilter = TicketStatus.submitted),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAmharic ? TicketStatus.inProgress.labelAm : TicketStatus.inProgress.labelEn,
                          isSelected: _selectedStatusFilter == TicketStatus.inProgress,
                          onSelected: () => setState(() => _selectedStatusFilter = TicketStatus.inProgress),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAmharic ? TicketStatus.resolved.labelAm : TicketStatus.resolved.labelEn,
                          isSelected: _selectedStatusFilter == TicketStatus.resolved,
                          onSelected: () => setState(() => _selectedStatusFilter = TicketStatus.resolved),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tickets List with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: state.refreshTickets,
                color: AppColors.primaryGreen,
                child: filteredTickets.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  s.get('no_tickets_found'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: filteredTickets.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = filteredTickets[index];
                          final ethDate = EthiopianDate.fromDateTime(ticket.createdAt);
                          final categoryText = isAmharic
                              ? ticket.fullCategoryDisplayAm
                              : ticket.fullCategoryDisplayEn;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailsScreen(ticketId: ticket.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Leading Category Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: ticket.status.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      ticket.category.icon,
                                      color: ticket.status.color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              ticket.id,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: ticket.status.backgroundColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isAmharic ? ticket.status.labelAm : ticket.status.labelEn,
                                                style: TextStyle(
                                                  color: ticket.status.color,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          categoryText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          ethDate.formatEC(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Chevron arrow
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.mintLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : AppColors.border,
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

