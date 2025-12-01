import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prestige_partners/app/lib/rewards.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';

import '../lib/supabase.dart';

final partnerProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final branchesProvider = FutureProvider.family<List<Branch>, String>((ref, partnerId) async {
  return await PartnerService.getBranches(partnerId);
});

final branchDetailsProvider = FutureProvider.family<Branch, Map<String, String>>(
        (ref, params) async {
      final partnerId = params['partnerId']!;
      final branchId = params['branchId']!;
      return await PartnerService.getBranchDetails(partnerId, branchId);
    });

final partnerRewardsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, partnerId) async {
    return await RewardService.getPartnerRewards(partnerId);
  },
);

final rewardServiceProvider = Provider<RewardService>((ref) {
  final token = ref.watch(tokenProvider).value ?? "";
  return RewardService(token);
});

final createRewardProvider =
FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, payload) async {
      final service = ref.read(rewardServiceProvider);
      return service.createReward(payload);
    });

final updateRewardProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({String id, Map<String, dynamic> data})>((ref, params) async {
  final service = ref.read(rewardServiceProvider);
  return service.updateReward(params.id, params.data);
});

final partnerMembersProvider =
FutureProvider.family<List<Members>, String>((ref, partnerId) async {
  return PartnerService.getPartnerUsers(partnerId);
});
