import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/app/providers/stats_provider.dart';
import 'package:prestige_partners/components/PointsHomePageChart.dart';

import '../../components/BranchesTable.dart';
import '../../components/HomePosTransactionsTable.dart';
import '../../components/PartnerTransactionsTable.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedChartPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider);
    final user = ref.read(userProvider);
    final partnerId = partner?['id'];

    if (partnerId == null) {
      return const Center(child: Text("No partner data found"));
    }

    final overviewAsync = ref.watch(overviewStatsProvider(partnerId));
    final last7daysAsync = ref.watch(
      last7DaysStatsProvider((
        partnerId: partnerId,
        period: _selectedChartPeriod,
      )),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overview Cards
            overviewAsync.when(
              loading: () => _buildOverviewLoadingState(),
              error: (e, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                });
                return const SizedBox();
              },
              data: (stats) {
                print("UI RECEIVED OVERVIEW: $stats");
                if (stats == null) return const Text("No stats available");

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.79,
                  children: [
                    _buildOverviewCard(
                      title: "Points Earned",
                      value: stats["points_earned"].toString(),
                      color: const Color(0xFF00D4AA),
                      icon: Icons.arrow_upward,
                    ),
                    _buildOverviewCard(
                      title: "Points Redeemed",
                      value: stats["points_redeemed"].toString(),
                      color: const Color(0xFFFF6B9D),
                      icon: Icons.arrow_downward,
                    ),
                  ],
                );
              },
            ),

            if (user!['tier'] != 'none') const SizedBox(height: 20),

            // Branches Comparison Table
            if (user['tier'] != 'none')
              BranchesComparisonTable(partnerId: partnerId),

            const SizedBox(height: 20),

            // CHART with proper loading states
            last7daysAsync.when(
              loading: () => PointsChart(
                branchData: null,
                isLoading: true,
                period: _selectedChartPeriod,
                onPeriodChanged: (p) =>
                    setState(() => _selectedChartPeriod = p),
              ),
              error: (e, _) => PointsChart(
                branchData: null,
                errorMessage: e.toString(),
                period: _selectedChartPeriod,
                onPeriodChanged: (p) =>
                    setState(() => _selectedChartPeriod = p),
              ),
              data: (days) {
                if (days == null || days.isEmpty) {
                  return PointsChart(
                    branchData: null,
                    period: _selectedChartPeriod,
                    onPeriodChanged: (p) =>
                        setState(() => _selectedChartPeriod = p),
                  );
                }

                // In the new API logic, 'days' is already Map<String, List<Map<String, dynamic>>>
                // because we processed it in StatsService.
                // However, the provider return type says Map<String, dynamic>.
                // We should cast it safely.

                final Map<String, List<Map<String, dynamic>>> branchData = {};

                try {
                  days.forEach((key, value) {
                    if (value is List) {
                      branchData[key] = List<Map<String, dynamic>>.from(value);
                      // Sort by date
                      // Depending on period (week, month, year), the date field might format differently?
                      // Assuming it's YYYY-MM-DD or similar sortable string.
                      branchData[key]!.sort(
                        (a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''),
                      );
                    }
                  });
                } catch (e) {
                  print("Error processing chart data: $e");
                }

                return PointsChart(
                  branchData: branchData,
                  period: _selectedChartPeriod,
                  onPeriodChanged: (p) =>
                      setState(() => _selectedChartPeriod = p),
                );
              },
            ),

            const SizedBox(height: 20),

            // Partner Transactions Table (EARN/REDEEM)
            PartnerTransactionsTable(partnerId: partnerId),

            const SizedBox(height: 20),

            // POS Transactions Table
            PosTransactionsTable(partnerId: partnerId),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.only(top: 13, right: 10, left: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewLoadingState() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.79,
      children: List.generate(4, (index) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
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
      child: Padding(
        padding: const EdgeInsets.only(top: 13, right: 10, left: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 80,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
