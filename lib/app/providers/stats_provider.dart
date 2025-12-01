import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lib/pos.dart';
import '../lib/supabase.dart';

// Service provider
final statsServiceProvider = Provider((ref) => StatsService());

// Overview stats provider
final overviewStatsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, partnerId) async {
  final service = ref.read(statsServiceProvider);
  return await service.getOverviewStats(partnerId: partnerId);
});

// Last 7 days provider
final last7DaysStatsProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, partnerId) async {
  final service = ref.read(statsServiceProvider);
  return await service.getLast7Days(partnerId: partnerId);
});


class PosTransactionParams {
  final String partnerId;
  final String? branchId;

  const PosTransactionParams({
    required this.partnerId,
    this.branchId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PosTransactionParams &&
              runtimeType == other.runtimeType &&
              partnerId == other.partnerId &&
              branchId == other.branchId;

  @override
  int get hashCode => partnerId.hashCode ^ branchId.hashCode;
}

// ============================================
// 2. FIX THE PROVIDER
// ============================================
final posTransactionsProvider = FutureProvider.family<List<Map<String, dynamic>>, PosTransactionParams>(
      (ref, params) async {
    print("🔵 PROVIDER CALLED with partnerId: ${params.partnerId}, branchId: ${params.branchId}");

    final data = await StatsService().getPosTransactions(
      partnerId: params.partnerId,
      branchId: params.branchId,
    );

    print("🟢 PROVIDER RETURNING: ${data?.length ?? 0} transactions");
    return data ?? [];
  },
);

final branchesComparisonProvider = FutureProvider.family<List<BranchComparison>, String>(
      (ref, partnerId) async {
    return await PartnerService.getBranchesComparison(partnerId);
  },
);