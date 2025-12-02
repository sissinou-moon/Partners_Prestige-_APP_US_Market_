import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/lib/supabase.dart';
import '../app/providers/stats_provider.dart';

class BranchesComparisonTable extends ConsumerWidget {
  final String partnerId;
  final int maxVisibleItems;
  final double maxHeight;

  const BranchesComparisonTable({
    super.key,
    required this.partnerId,
    this.maxVisibleItems = 5,
    this.maxHeight = 400,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(branchesComparisonProvider(partnerId));

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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Branches Comparison",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Today's performance across locations",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00D4AA)),
                  onPressed: () => ref.refresh(branchesComparisonProvider(partnerId)),
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          comparisonAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error.toString()),
            data: (branches) {
              if (branches.isEmpty) {
                return _buildEmptyState();
              }
              return _buildBranchesList(branches);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesList(List<BranchComparison> branches) {
    // Calculate responsive height
    const double itemHeight = 70.0;
    const double separatorHeight = 1.0;
    final int itemsToShow = branches.length > maxVisibleItems
        ? maxVisibleItems
        : branches.length;

    final double calculatedHeight = (itemHeight * itemsToShow) +
        (separatorHeight * (itemsToShow - 1));

    final double finalHeight = calculatedHeight > maxHeight
        ? maxHeight
        : calculatedHeight;
    final double constrainedMaxHeight = finalHeight - 30;
    final double maxHeightSafe = constrainedMaxHeight < itemHeight
        ? itemHeight
        : constrainedMaxHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: itemHeight,
        maxHeight: maxHeightSafe,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: branches.length > maxVisibleItems
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: branches.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final branch = branches[index];
          return _buildBranchCard(branch, index);
        },
      ),
    );
  }

  Widget _buildBranchCard(BranchComparison branch, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Branch indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getBranchColor(index),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Branch name
          Expanded(
            flex: 2,
            child: Text(
              branch.locationName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 12),

          // Visitors badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9B59B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people,
                  size: 14,
                  color: Color(0xFF9B59B6),
                ),
                const SizedBox(width: 4),
                Text(
                  branch.membersServed.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9B59B6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Points earned badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward,
                  size: 14,
                  color: Color(0xFF00D4AA),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatNumber(branch.pointsEarnedToday),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00D4AA),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Redeemed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: Color(0xFFFF6B9D),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatNumber(branch.redemptionsToday),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B9D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trend indicator
          _buildTrendIndicator(branch.trendDirection, branch.trendPercent),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String direction, double? percent) {
    IconData icon;
    Color color;
    String text;

    switch (direction) {
      case 'up':
        icon = Icons.trending_up;
        color = const Color(0xFF00D4AA);
        text = percent != null ? '+${percent.toStringAsFixed(0)}%' : '+N/A';
        break;
      case 'down':
        icon = Icons.trending_down;
        color = const Color(0xFFFF6B9D);
        text = percent != null ? '${percent.toStringAsFixed(0)}%' : '-N/A';
        break;
      case 'no-data':
      default:
        icon = Icons.remove;
        color = Colors.grey;
        text = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBranchColor(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];
    return colors[index % colors.length];
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 135,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 7),
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Dot skeleton
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          // Name skeleton
          Expanded(
            flex: 2,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Badge skeletons
          ...List.generate(2, (index) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                width: 70,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No branches to compare',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Branches will appear here once available',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}