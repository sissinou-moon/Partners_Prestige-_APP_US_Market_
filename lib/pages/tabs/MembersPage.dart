import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/lib/supabase.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Members> _filterMembers(List<Members> members, String query) {
    if (query.isEmpty) return members;

    final lowerQuery = query.toLowerCase();
    return members.where((member) {
      return member.fullName.toLowerCase().contains(lowerQuery) ||
          (member.email?.toLowerCase().contains(lowerQuery) ?? false) ||
          (member.phone?.toLowerCase().contains(lowerQuery) ?? false) ||
          (member.referralCode?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider);

    if (partner == null) {
      return const Center(child: Text('No business data found'));
    }

    final partnerId = partner['id'] as String;
    final membersAsync = ref.watch(partnerMembersProvider(partnerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Member Count
              membersAsync.when(
                data: (members) => _buildMemberCount(members.length, partnerId),
                loading: () => _buildMemberCount(0, partnerId),
                error: (error, stack) => _buildMemberCount(0, partnerId),
              ),
              const SizedBox(height: 20),

              // Members Table
              membersAsync.when(
                data: (members) {
                  final filteredMembers = _filterMembers(members, _searchQuery);
                  return Opacity(
                    opacity: loading ? 0.5 : 1,
                    child: _MembersTable(
                      members: filteredMembers,
                      onUpdate: (userId, data) => _updateMember(userId, data, partnerId), loading: loading,
                    ),
                  );
                },
                loading: () => const _LoadingMembersTable(),
                error: (error, stack) => _ErrorMembersTable(error: error.toString()),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your team members',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search members by name, email, phone, or referral code...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(
          FluentIcons.search_20_filled,
          color: Colors.grey[600],
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: Icon(
            FluentIcons.dismiss_20_filled,
            color: Colors.grey[600],
          ),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMemberCount(int count, String partnerId) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'You have $count member${count != 1 ? 's' : ''} in your team',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            FluentIcons.arrow_clockwise_20_filled,
            size: 18,
            color: Color(0xFF00D4AA),
          ),
          onPressed: () {
            ref.invalidate(partnerMembersProvider(partnerId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Refreshing members...")),
            );
          },
          tooltip: 'Refresh members',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _updateMember(String userId, Map<String, dynamic> data, String partnerId) async {
    try {
      setState(() {
        loading = true;
      });
      await PartnerService.updatePartnerUser(userId: userId, data: data);

      // Refresh the members list
      ref.invalidate(partnerMembersProvider(partnerId));

      if (mounted) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Members Table Widget
class _MembersTable extends StatelessWidget {
  final List<Members> members;
  final Future<void> Function(String userId, Map<String, dynamic> data) onUpdate;
  bool loading = false;

   _MembersTable({
    required this.members,
    required this.onUpdate,
    required this.loading
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyMembersState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateColor.resolveWith(
                (states) => Colors.grey.shade50,
          ),
          headingRowHeight: 56,
          dataRowHeight: 72,
          columns: const [
            DataColumn(
              label: Text(
                'Member',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Contact',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Role',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Points',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Approved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
          rows: members.map((member) => _buildMemberRow(context, member)).toList(),
        ),
      ),
    );
  }

  DataRow _buildMemberRow(BuildContext context, Members member) {
    return DataRow(
      cells: [
        // Member (Avatar + Name)
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                    ? NetworkImage(member.profileImage!)
                    : null,
                child: member.profileImage == null || member.profileImage!.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ref: ${member.referralCode ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contact
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (member.email != null)
                Text(
                  member.email!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              if (member.phone != null) ...[
                const SizedBox(height: 2),
                Text(
                  member.phone!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Role
        DataCell(
          _RoleBadge(role: member.role),
        ),

        // Status
        DataCell(
          _StatusBadge(status: member.status),
        ),

        // Points
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB020).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FluentIcons.star_20_filled,
                  size: 14,
                  color: Color(0xFFFFB020),
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFB020),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Approved
        DataCell(
          member.approved
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const Icon(Icons.cancel, color: Colors.orange, size: 20),
        ),

        // Action
        DataCell(
          PopupMenuButton(
            enabled: !loading,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      member.approved ? FluentIcons.dismiss_circle_20_filled : FluentIcons.checkmark_circle_20_filled,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(member.approved ? 'Unapprove' : 'Approve'),
                  ],
                ),
                onTap: () => onUpdate(member.id, {'approved': !member.approved}),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.person_swap_20_filled,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    const Text('Change Role'),
                  ],
                ),
                onTap: () => _showRoleDialog(context, member),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.status_20_filled,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    const Text('Change Status'),
                  ],
                ),
                onTap: () => _showStatusDialog(context, member),
              ),
            ],
            child: Icon(
              FluentIcons.more_vertical_20_filled,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _showRoleDialog(BuildContext context, Members member) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('CASHIER'),
                leading: Radio<String>(
                  value: 'CASHIER',
                  groupValue: member.role,
                  onChanged: (value) {
                    Navigator.pop(context);
                    onUpdate(member.id, {'role': value});
                  },
                ),
              ),
              ListTile(
                title: const Text('OWNER'),
                leading: Radio<String>(
                  value: 'OWNER',
                  groupValue: member.role,
                  onChanged: (value) {
                    Navigator.pop(context);
                    onUpdate(member.id, {'role': value});
                  },
                ),
              ),
              ListTile(
                title: const Text('USER'),
                leading: Radio<String>(
                  value: 'USER',
                  groupValue: member.role,
                  onChanged: (value) {
                    Navigator.pop(context);
                    onUpdate(member.id, {'role': value});
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    });
  }

  void _showStatusDialog(BuildContext context, Members member) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('ACTIVE'),
                leading: Radio<String>(
                  value: 'ACTIVE',
                  groupValue: member.status,
                  onChanged: (value) {
                    Navigator.pop(context);
                    onUpdate(member.id, {'status': value});
                  },
                ),
              ),
              ListTile(
                title: const Text('INACTIVE'),
                leading: Radio<String>(
                  value: 'INACTIVE',
                  groupValue: member.status,
                  onChanged: (value) {
                    Navigator.pop(context);
                    onUpdate(member.id, {'status': value});
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    });
  }
}

// Role Badge Widget
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (role) {
      case 'OWNER':
        backgroundColor = const Color(0xFF9B59B6).withOpacity(0.1);
        textColor = const Color(0xFF9B59B6);
        icon = FluentIcons.crown_20_filled;
        break;
      case 'CASHIER':
        backgroundColor = const Color(0xFF00D4AA).withOpacity(0.1);
        textColor = const Color(0xFF00D4AA);
        icon = FluentIcons.person_20_filled;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey[700]!;
        icon = FluentIcons.person_20_regular;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// Loading State
class _LoadingMembersTable extends StatelessWidget {
  const _LoadingMembersTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          5,
              (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 120,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Error State
class _ErrorMembersTable extends StatelessWidget {
  final String error;

  const _ErrorMembersTable({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              FluentIcons.warning_20_filled,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State
class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              FluentIcons.people_20_filled,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No members found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No members match your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}