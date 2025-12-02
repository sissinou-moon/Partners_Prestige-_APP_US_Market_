import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/Root.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/app/providers/stats_provider.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prestige_partners/components/PointsHomePageChart.dart';

import '../../components/BranchesTable.dart';
import '../../components/HomePosTransactionsTable.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(partnerProvider);
    final user = ref.read(userProvider);
    final partnerId = partner?['id'];

    if (partnerId == null) {
      return const Center(child: Text("No partner data found"));
    }

    final overviewAsync = ref.watch(overviewStatsProvider(partnerId));
    final last7daysAsync = ref.watch(last7DaysStatsProvider(partnerId));

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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: $e")));
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
                    _buildOverviewCard(
                      title: "Balance",
                      value: stats["outstanding_balance"].toString(),
                      color: const Color(0xFF4A90E2),
                      icon: Icons.account_balance_wallet,
                    ),
                    _buildOverviewCard(
                      title: "Total Visitors",
                      value: stats["total_visitors"].toString(),
                      color: const Color(0xFF9B59B6),
                      icon: Icons.people,
                    ),
                  ],
                );
              },
            ),

            if(user!['tier'] != 'none') const SizedBox(height: 20),

            // Branches Comparison Table - NEW!
            if(user['tier'] != 'none') BranchesComparisonTable(partnerId: partnerId),

            const SizedBox(height: 20),

            // CHART with proper loading states
            last7daysAsync.when(
              loading: () => const PointsChart(
                branchData: null,
                isLoading: true,
              ),
              error: (e, _) => PointsChart(
                branchData: null,
                errorMessage: e.toString(),
              ),
              data: (days) {
                if (days == null || days.isEmpty) {
                  return const PointsChart(branchData: null);
                }

                // Convert to the correct format: Map<String, List<Map<String, dynamic>>>
                final Map<String, List<Map<String, dynamic>>> branchData = {};

                days.forEach((branchName, list) {
                  branchData[branchName] = List<Map<String, dynamic>>.from(list);
                  // Sort each branch's data by date
                  branchData[branchName]!.sort((a, b) => a['date'].compareTo(b['date']));
                });

                return PointsChart(branchData: branchData);
              },
            ),

            const SizedBox(height: 20),

            // POS Transactions Table
            PosTransactionsTable(
              partnerId: partnerId,
            ),

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