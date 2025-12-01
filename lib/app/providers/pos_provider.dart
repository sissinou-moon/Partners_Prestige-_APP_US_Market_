// Provider for POS connection state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';

import '../lib/pos.dart';
import '../lib/supabase.dart';

final posConnectionProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final locationsProvider = FutureProvider.autoDispose<List<SquareLocation>>((ref) async {
  final partner = ref.watch(partnerProvider);
  if (partner == null) throw Exception('Partner not found');

  final partnerId = partner['id'] as String;
  print(partnerId);
  return await PartnerService.getSquareLocations(partnerId);
});