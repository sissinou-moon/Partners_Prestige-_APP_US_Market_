import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:prestige_partners/main.dart';

class SubscriptionService {
  final String baseUrl = 'https://usprestigeplusrewardsapp-production.up.railway.app/api/subscriptions';
  final String authToken; // Get from your auth system

  SubscriptionService(this.authToken);

  // Get payment intent and ephemeral key
  Future<Map<String, dynamic>> createPaymentIntent(String planId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-payment-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'plan_id': planId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create payment intent');
  }

  // Confirm subscription after payment
  Future<Map<String, dynamic>> confirmSubscription(
      String planId,
      String paymentMethodId,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/confirm-subscription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'plan_id': planId,
        'payment_method_id': paymentMethodId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to confirm subscription');
  }

  // Get current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final response = await http.get(
      Uri.parse('$baseUrl/current'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['subscription'];
    }
    throw Exception('Failed to get subscription');
  }

  // Cancel subscription
  Future<void> cancelSubscription({bool immediate = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'immediate': immediate}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription');
    }
  }
}


class directStripeSubscription {

  final String baseUrl = 'https://usprestigeplusrewardsapp-production.up.railway.app/api/subscriptions';

  Future<dynamic> createSetupIntent(String customerId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/setup_intents'),
        headers: {
          'Authorization': 'Bearer $secret_key',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'payment_method_types[]': 'card',
        },
      );

      final data = jsonDecode(response.body);
      print("SetupIntent: $data");

      return data; // important!
    } catch (e) {
      print("Error creating setup intent: $e");
      return null;
    }
  }

  Future<bool> attachPaymentMethod(String paymentMethodId, String customerId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_methods/$paymentMethodId/attach'),
        headers: {
          'Authorization': 'Bearer $secret_key',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
        },
      );

      print("Attach Payment Method Response: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("Error attaching payment method: $e");
      return false;
    }
  }

  Future<String?> createCustomer(String email) async {
    print("Start creating customer...");
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secret_key',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
        },
      );

      print("HTTP status: ${response.statusCode}");
      //print("HTTP body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final customerId = jsonBody['id'];
        print("Customer created ✅: $customerId");
        return customerId;
      } else {
        print("Failed to create customer");
        return null;
      }
    } catch (e, stacktrace) {
      print("Exception creating customer: $e");
      print(stacktrace);
      return null;
    }
  }

  // Create a subscription for an existing customer
  Future<Map<String, dynamic>?> createSubscription(String customerId, String priceId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions'),
        headers: {
          'Authorization': 'Bearer $secret_key',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings[save_default_payment_method]': 'on_subscription',
          'expand[]': 'latest_invoice.confirmation_secret',
        },
      );

      print('SUBSCRIPTION 🔽🔽');
      print("HTTP body: ${response.body}");
      final data = jsonDecode(response.body);

      print("Status: ${data['status']}");
      print("Invoice: ${data['latest_invoice']}");
      print("confirmation_secret: ${data['latest_invoice']?['confirmation_secret']}");

      return data;

    } catch (e, stack) {
      print("Exception creating subscription: $e");
      print(stack);
      return null;
    }
  }



  Future<String?> createPaymentIntent(String currency, int amount) async {
    print("Start getting client secret");
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secret_key', // ⚠️ Make sure it's 'Bearer', not 'Bear'
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
        },
      );

      print("HTTP status: ${response.statusCode}");
      print("HTTP body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final clientSecret = jsonBody['client_secret'];
        if (clientSecret != null) {
          print("Client secret retrieved ✅: $clientSecret");
          return clientSecret;
        } else {
          print("Error: client_secret is null in response");
          return null;
        }
      } else {
        print("Failed to create payment intent. Status code: ${response.statusCode}");
        try {
          final errorBody = jsonDecode(response.body);
          print("Error response: $errorBody");
        } catch (_) {
          print("Cannot parse error response body.");
        }
        return null;
      }
    } catch (e, stacktrace) {
      print("Exception while creating payment intent: $e");
      print("Stacktrace: $stacktrace");
      return null;
    }
  }

  Future<String?> fetchPaymentMethodFromSetupIntent(String setupIntentSecret) async {
    final response = await http.get(
      Uri.parse("https://api.stripe.com/v1/setup_intents/$setupIntentSecret"),
      headers: {
        "Authorization": "Bearer $secret_key",
      },
    );

    final data = jsonDecode(response.body);

    return data["payment_method"];
  }

  Future<Map<String, dynamic>?> saveNewSubscription(
      String customer_id,
      String subscription_id,
      String price_id,
      Map<String, dynamic> user,
      String status,
      String plan,
      String token
      ) async {
    print("Start saving ========================================================================");

    final uri = Uri.parse('$baseUrl/save-new-subscription');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': user['id'],
          'customer_id': customer_id,
          'subscription_id': subscription_id,
          'price_id': price_id,
          'plan': plan,
          'status': status,
          'user_email': user['email'],
          'partnerUser': user, // Send as JSON in body
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        print("Subscription saved successfully ✅");
        return body['subscription'];
      } else {
        print("Failed to save subscription ❌: ${body['message']}");
        return null;
      }
    } catch (e) {
      throw e.toString();
    }
  }


  Future<Map<String, dynamic>?> makePayment(Map<String, dynamic> user, String plan, String token, String price_id) async {
    try {
      // STEP A create customer
      final customerId = await createCustomer(user['email']);
      if (customerId == null) return null;

      // STEP E create subscription
      final subscription = await createSubscription(customerId, price_id);
      if (subscription == null) return null;

      final clientSecret = subscription["latest_invoice"]["confirmation_secret"]['client_secret'];
      if (clientSecret == null) {
        print("❌ Subscription has no payment_intent");
        return null;
      }

      // STEP F confirm payment via payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: "Prestige+",
          paymentIntentClientSecret: clientSecret,
        ),
      );

      final paymentResult = await Stripe.instance.presentPaymentSheet();

      // STEP G: Save subscription to Supabase
      final subscriptionSaved = await saveNewSubscription(customerId, subscription['id'], price_id, user, subscription['status'], plan, token);

      return subscriptionSaved;

    } catch (e) {
      print("Error in makePayment: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkUserSubscription(
      String userId,
      String token,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check?userId=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data['subscription']);
        return data['subscription'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error checking subscription: $e');
      return null;
    }
  }

  // Get subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails(
      String userId,
      String subscriptionId,
      String token,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/details?userId=$userId&subscriptionId=$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['subscription'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting subscription details: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(
      String subscriptionId,
      String token,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subscriptionId': subscriptionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }
}