import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../app/providers/partner_provider.dart';

class StorePage extends ConsumerWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(partnerProvider);

    if (partner == null) {
      return const Center(child: Text('No business data found'));
    }

    final partnerId = partner['id'] as String;
    final branchesAsyncValue = ref.watch(branchesProvider(partnerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _BannerWidget(partner: partner),
            _BusinessDetailsWidget(partner: partner),
            _BranchesWidget(branchesAsyncValue: branchesAsyncValue),
            //_BusinessMetricsWidget(partner: partner),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Banner Section with Logo and Business Info
class _BannerWidget extends StatelessWidget {
  final Map<String, dynamic> partner;

  const _BannerWidget({required this.partner});

  @override
  Widget build(BuildContext context) {
    final businessName = partner['business_name'] as String? ?? 'Business';
    final businessType = partner['business_type'] as String? ?? '';
    final logoUrl = partner['logo_url'] as String?;
    final bannerUrl = partner['banner_url'] as String?;
    final status = partner['status'] as String? ?? 'ACTIVE';

    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentGeometry.center,
      children: [
        // Banner Image
        Container(
          height: 200,
          width: MediaQuery.of(context).size.width * 0.91,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(15),
            image: bannerUrl != null && bannerUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(bannerUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: bannerUrl == null || bannerUrl.isEmpty
              ? Center(
                  child: Icon(
                    FluentIcons.image_20_regular,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                )
              : null,
        ),

        SizedBox(width: double.infinity),

        // Gradient Overlay
        Container(
          height: 200,
          width: MediaQuery.of(context).size.width * 0.91,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
        ),

        // Logo and Business Info
        Positioned(
          left: 16,
          bottom: -40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LogoContainer(logoUrl: logoUrl),
              const SizedBox(width: 16),
              _BusinessInfoColumn(
                businessName: businessName,
                businessType: businessType,
                status: status,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoContainer extends StatelessWidget {
  final String? logoUrl;

  const _LogoContainer({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(logoUrl!, fit: BoxFit.cover),
            )
          : Icon(
              FluentIcons.building_20_filled,
              size: 40,
              color: Colors.grey.shade400,
            ),
    );
  }
}

class _BusinessInfoColumn extends StatelessWidget {
  final String businessName;
  final String businessType;
  final String status;

  const _BusinessInfoColumn({
    required this.businessName,
    required this.businessType,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (businessType.isNotEmpty) ...[
                _BadgeChip(label: businessType, color: const Color(0xFF00D4AA)),
                const SizedBox(width: 8),
              ],
              _StatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pending,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Business Details Card
class _BusinessDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> partner;

  const _BusinessDetailsWidget({required this.partner});

  @override
  Widget build(BuildContext context) {
    final email = partner['email'] as String?;
    final phone = partner['phone'] as String?;
    final website = partner['website'] as String?;
    final address = partner['address'] as String?;
    final city = partner['city'] as String?;
    final state = partner['state'] as String?;
    final postalCode = partner['postal_code'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      child: _CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(title: 'Business Details'),
            const SizedBox(height: 16),
            if (email != null) ...[
              _DetailRow(
                icon: FluentIcons.mail_20_filled,
                title: 'Email',
                value: email,
                color: const Color(0xFF4A90E2),
              ),
              const _DividerWithSpacing(),
            ],
            if (phone != null) ...[
              _DetailRow(
                icon: FluentIcons.phone_20_filled,
                title: 'Phone',
                value: phone,
                color: const Color(0xFF00D4AA),
              ),
              const _DividerWithSpacing(),
            ],
            if (website != null) ...[
              _DetailRow(
                icon: FluentIcons.globe_20_filled,
                title: 'Website',
                value: website,
                color: const Color(0xFF9B59B6),
              ),
              const _DividerWithSpacing(),
            ],
            if (address != null)
              _DetailRow(
                icon: FluentIcons.location_20_filled,
                title: 'Address',
                value:
                    '$address${city != null ? ', $city' : ''}${state != null ? ', $state' : ''}${postalCode != null ? ' $postalCode' : ''}',
                color: const Color(0xFFFF6B9D),
              ),
          ],
        ),
      ),
    );
  }
}

/// Branches and Operating Hours Section
class _BranchesWidget extends ConsumerStatefulWidget {
  final AsyncValue<List<dynamic>> branchesAsyncValue;

  const _BranchesWidget({required this.branchesAsyncValue});

  @override
  ConsumerState<_BranchesWidget> createState() => _BranchesWidgetState();
}

class _BranchesWidgetState extends ConsumerState<_BranchesWidget> {
  late int selectedBranchIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: widget.branchesAsyncValue.when(
        data: (branches) {
          final selectedBranch = branches.isNotEmpty
              ? branches[selectedBranchIndex]
              : null;

          return Column(
            children: [
              if (branches.isNotEmpty && branches.length > 1)
                _BranchDropdown(
                  branches: branches,
                  selectedIndex: selectedBranchIndex,
                  onChanged: (index) {
                    setState(() => selectedBranchIndex = index);
                  },
                ),
              if (branches.isNotEmpty && branches.length > 1)
                const SizedBox(height: 16),
              if (selectedBranch != null)
                _BranchDetailsCard(branch: selectedBranch)
              else
                _EmptyBranchDetailsCard(),
              const SizedBox(height: 16),
              if (selectedBranch != null)
                _OperatingHoursCard(branch: selectedBranch)
              else
                _EmptyOperatingHoursCard(),
            ],
          );
        },
        loading: () => Column(
          children: [
            _LoadingBranchDropdown(),
            const SizedBox(height: 16),
            _LoadingBranchDetailsCard(),
            const SizedBox(height: 16),
            _LoadingOperatingHoursCard(),
          ],
        ),
        error: (error, stack) => Column(
          children: [
            _LoadingBranchDropdown(),
            const SizedBox(height: 16),
            _LoadingBranchDetailsCard(),
            const SizedBox(height: 16),
            _LoadingOperatingHoursCard(),
          ],
        ),
      ),
    );
  }
}

/// Branch Dropdown Selector
class _BranchDropdown extends StatelessWidget {
  final List<dynamic> branches;
  final int selectedIndex;
  final Function(int) onChanged;

  const _BranchDropdown({
    required this.branches,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: DropdownButtonFormField<int>(
        value: selectedIndex,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(
            FluentIcons.location_20_filled,
            color: Color(0xFF00D4AA),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
          hintText: "Select branch",
        ),
        items: List.generate(
          branches.length,
          (index) => DropdownMenuItem(
            value: index,
            child: Text(branches[index].branchName ?? 'Branch $index'),
          ),
        ),
      ),
    );
  }
}

/// Branch Details Card
class _BranchDetailsCard extends StatelessWidget {
  final dynamic branch;

  const _BranchDetailsCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    final branchName = branch.branchName as String? ?? 'Branch';
    final address = branch.address as String?;
    final city = branch.city as String?;
    final state = branch.state as String?;
    final country = branch.country as String?;
    final postalCode = branch.postalCode as String?;
    final email = branch.email as String?;
    final phone = branch.phone as String?;

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branchName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          if (address != null) ...[
            _DetailRow(
              icon: FluentIcons.location_20_filled,
              title: 'Address',
              value:
                  '$address${city != null ? ', $city' : ''}${state != null ? ', $state' : ''}${country != null ? ', $country' : ''}${postalCode != null ? ' $postalCode' : ''}',
              color: const Color(0xFFFF6B9D),
            ),
            const _DividerWithSpacing(),
          ],
          if (email != null) ...[
            _DetailRow(
              icon: FluentIcons.mail_20_filled,
              title: 'Email',
              value: email,
              color: const Color(0xFF4A90E2),
            ),
            const _DividerWithSpacing(),
          ],
          if (phone != null)
            _DetailRow(
              icon: FluentIcons.phone_20_filled,
              title: 'Phone',
              value: phone,
              color: const Color(0xFF00D4AA),
            ),
        ],
      ),
    );
  }
}

/// Operating Hours Card
class _OperatingHoursCard extends StatelessWidget {
  final dynamic branch;

  const _OperatingHoursCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    final operatingHoursData = branch.operatingHours as Map<String, dynamic>?;
    final timezone = operatingHoursData?['timezone'] as String? ?? 'UTC';
    final hoursData =
        operatingHoursData?['operating_hours'] as Map<String, dynamic>?;
    final is24Hours = hoursData?['is_24_hours'] as bool? ?? false;
    final regularHours =
        hoursData?['regular_hours'] as Map<String, dynamic>? ?? {};
    final specialHours = hoursData?['special_hours'] as List<dynamic>? ?? [];

    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    const dayDisplayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Operating Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 12),
              _BadgeChip(label: timezone, color: const Color(0xFF00D4AA)),
            ],
          ),
          const SizedBox(height: 16),
          if (is24Hours)
            _Open24HoursBadge()
          else
            _RegularHoursList(
              dayOrder: dayOrder,
              dayDisplayNames: dayDisplayNames,
              regularHours: regularHours,
            ),
          if (specialHours.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _SpecialHoursList(specialHours: specialHours),
          ],
        ],
      ),
    );
  }
}

class _Open24HoursBadge extends StatelessWidget {
  const _Open24HoursBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00D4AA), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.clock_20_filled,
            color: Color(0xFF00D4AA),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Open 24 Hours',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00D4AA),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegularHoursList extends StatelessWidget {
  final List<String> dayOrder;
  final Map<String, String> dayDisplayNames;
  final Map<String, dynamic> regularHours;

  const _RegularHoursList({
    required this.dayOrder,
    required this.dayDisplayNames,
    required this.regularHours,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(dayOrder.length, (index) {
        final day = dayOrder[index];
        final dayHours = regularHours[day] as Map<String, dynamic>?;
        final openTime = dayHours?['open'] as String? ?? '--:--';
        final closeTime = dayHours?['close'] as String? ?? '--:--';

        return Column(
          children: [
            _HourRow(
              day: dayDisplayNames[day] ?? day,
              hours: '$openTime - $closeTime',
            ),
            if (index < dayOrder.length - 1)
              Divider(height: 1, color: Colors.grey.shade200),
          ],
        );
      }),
    );
  }
}

class _HourRow extends StatelessWidget {
  final String day;
  final String hours;

  const _HourRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialHoursList extends StatelessWidget {
  final List<dynamic> specialHours;

  const _SpecialHoursList({required this.specialHours});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Hours',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...specialHours.map((special) {
          final date = special['date'] as String? ?? '';
          final isClosed = special['is_closed'] as bool? ?? false;
          final open = special['open'] as String?;
          final close = special['close'] as String?;
          final description = special['description'] as String? ?? '';

          return _SpecialHourItem(
            date: date,
            description: description,
            isClosed: isClosed,
            open: open,
            close: close,
          );
        }).toList(),
      ],
    );
  }
}

class _SpecialHourItem extends StatelessWidget {
  final String date;
  final String description;
  final bool isClosed;
  final String? open;
  final String? close;

  const _SpecialHourItem({
    required this.date,
    required this.description,
    required this.isClosed,
    required this.open,
    required this.close,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClosed ? Colors.red.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClosed ? Colors.red.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isClosed ? FluentIcons.clock_20_filled : FluentIcons.info_20_filled,
            color: isClosed ? Colors.red.shade700 : Colors.amber.shade700,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isClosed
                        ? Colors.red.shade900
                        : Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isClosed
                            ? Colors.red.shade700
                            : Colors.amber.shade700,
                      ),
                    ),
                    if (!isClosed) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${open ?? '--:--'} - ${close ?? '--:--'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isClosed
                              ? Colors.red.shade700
                              : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Business Metrics Widget
class _BusinessMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> partner;

  const _BusinessMetricsWidget({required this.partner});

  @override
  Widget build(BuildContext context) {
    final commissionRate = partner['commission_rate'] as num? ?? 0;
    final pointsMultiplier = partner['points_multiplier'] as num? ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MetricBox(
              icon: FluentIcons.money_20_filled,
              label: 'Commission Rate',
              value: '$commissionRate%',
              color: const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricBox(
              icon: FluentIcons.star_20_filled,
              label: 'Points Multiplier',
              value: '${pointsMultiplier}x',
              color: const Color(0xFFFFB020),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Components

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

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
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;

  const _CardTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

class _DividerWithSpacing extends StatelessWidget {
  const _DividerWithSpacing();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color.withOpacity(0.8), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading State Widgets

class _LoadingBranchDropdown extends StatelessWidget {
  const _LoadingBranchDropdown();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        children: [
          _ShimmerBox(height: 20, width: double.infinity),
          const SizedBox(height: 8),
          _ShimmerBox(height: 20, width: 150),
        ],
      ),
    );
  }
}

class _LoadingBranchDetailsCard extends StatelessWidget {
  const _LoadingBranchDetailsCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(height: 24, width: 150),
          const SizedBox(height: 20),
          ...[0, 1, 2].map(
            (i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(height: 14, width: 80),
                const SizedBox(height: 8),
                _ShimmerBox(height: 18, width: double.infinity),
                if (i < 2) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOperatingHoursCard extends StatelessWidget {
  const _LoadingOperatingHoursCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(height: 24, width: 180),
          const SizedBox(height: 20),
          ...[0, 1, 2, 3, 4, 5, 6].map(
            (i) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerBox(height: 16, width: 80),
                    _ShimmerBox(height: 16, width: 100),
                  ],
                ),
                if (i < 6) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double width;

  const _ShimmerBox({required this.height, required this.width});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                _animationController.value - 0.3,
                _animationController.value,
                _animationController.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Empty State Widgets

class _EmptyBranchDetailsCard extends StatelessWidget {
  const _EmptyBranchDetailsCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Branch Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.building_20_filled,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _EmptyOperatingHoursCard extends StatelessWidget {
  const _EmptyOperatingHoursCard();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operating Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.clock_20_filled,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
