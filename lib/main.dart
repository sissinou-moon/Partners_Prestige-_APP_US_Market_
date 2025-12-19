import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Root.dart';
import 'app/providers/subscription_provider.dart';
import 'widgets/connectivity_overlay.dart';

final publish_key =
    "pk_test_51SXKwQ2fFh79gGsX6Kz76UZtnWvLapdC1pS2wI1hs01UA5PY0FlxViVjHSk2z8gKCec7SufHrvwNv5eS9vNJkJvH00hq5zS9Ba";
final secret_key =
    "sk_test_51SXKwQ2fFh79gGsX9AFz1EQd8zQT8ccJFrW6IOuqwDjCPJhxCLYnevdvXDBPEX7ew31BJMKWrL646LMZPO263GLi00tf32PSEV";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = publish_key;
  Stripe.instance.applySettings();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override the sharedPreferencesProvider
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prestige Business',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ConnectivityOverlay(child: child!);
      },
      home: RootLayout(),
    );
  }
}
