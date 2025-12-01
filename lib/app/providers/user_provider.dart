import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

final userProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final tokenProvider = FutureProvider<String?>((ref) async {
  return await LocalStorage.getToken();
});
