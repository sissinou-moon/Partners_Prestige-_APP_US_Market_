// Provider for POS connection state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';

import '../lib/pos.dart';
import '../lib/supabase.dart';

final posConnectionProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final locationsProvider = FutureProvider.autoDispose<List<SquareLocation>>((ref) async {
  final partner = ref.watch(partnerProvider);
  final user = ref.watch(userProvider);
  if (partner == null) throw Exception('Partner not found');

  final partnerId = partner['id'] as String;

  return await PartnerService.getSquareLocations(partnerId, );
});