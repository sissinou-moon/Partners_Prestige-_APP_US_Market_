// lib/app/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prestige_partners/app/lib/stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart');
});

// Main subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      (ref) => SubscriptionNotifier(ref.read(sharedPreferencesProvider)),
);

// State class
class SubscriptionState {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;
  final bool hasChecked;

  const SubscriptionState({
    this.data,
    this.isLoading = false,
    this.error,
    this.hasChecked = false,
  });

  Map<String, dynamic> toJSON() {
    return {
      'data': data,
      'isLoading': isLoading,
      'error': error,
      'hasChecked': hasChecked,
    };
  }

  bool get hasSubscription => data != null;
  String? get plan => data?['plan'];
  String? get status => data?['status'];

  SubscriptionState copyWith({
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
    bool? hasChecked,
  }) {
    return SubscriptionState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }
}

// Notifier class
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'subscription_cache';

  SubscriptionNotifier(this._prefs) : super(const SubscriptionState()) {
    // Load cached subscription on initialization
    _loadCachedSubscription();
  }

  // Load from local cache
  void _loadCachedSubscription() {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null) {
        final cachedData = json.decode(jsonString) as Map<String, dynamic>;
        state = state.copyWith(data: cachedData, hasChecked: true);
      }
    } catch (e) {
      print('Error loading cached subscription: $e');
    }
  }

  // Save to local cache
  Future<void> _saveToCache(Map<String, dynamic> subscription) async {
    try {
      await _prefs.setString(_storageKey, json.encode(subscription));
    } catch (e) {
      print('Error saving subscription to cache: $e');
    }
  }

  // Clear cache
  Future<void> _clearCache() async {
    await _prefs.remove(_storageKey);
  }

  // Check subscription from API
  Future<void> checkSubscription(String userId, String token) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Import your SubscriptionApiService
      final subscription = await directStripeSubscription().checkUserSubscription(userId, token);
      print("===============");
      print(subscription);

      if (subscription != null) {
        await _saveToCache(subscription);
        state = state.copyWith(
          data: subscription,
          isLoading: false,
          hasChecked: true,
        );
      } else {
        await _clearCache();
        state = state.copyWith(
          data: null,
          isLoading: false,
          hasChecked: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check subscription: $e',
        hasChecked: true,
      );
    }
  }

  // Set subscription (when user subscribes)
  Future<void> setSubscription(Map<String, dynamic> subscription) async {
    await _saveToCache(subscription);
    state = state.copyWith(
      data: subscription,
      error: null,
      hasChecked: true,
    );
  }

  // Update subscription status
  Future<void> updateSubscription(Map<String, dynamic> updates) async {
    if (state.data == null) return;

    final updated = {...state.data!, ...updates};
    await _saveToCache(updated);
    state = state.copyWith(data: updated);
  }

  // Clear subscription (when user cancels)
  Future<void> clearSubscription() async {
    await _clearCache();
    state = const SubscriptionState(hasChecked: true);
  }

  // Refresh subscription from API
  Future<void> refresh(String userId, String token) async {
    await checkSubscription(userId, token);
  }
}