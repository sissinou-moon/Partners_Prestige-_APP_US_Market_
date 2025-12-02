import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StatsService {
  static const String baseUrl =
      "https://usprestigeplusrewardsapp-production.up.railway.app/api/pos";

  /// ------------------------------------------------------
  /// 📌 1 — OVERVIEW STATS
  /// ------------------------------------------------------
  Future<Map<String, dynamic>?> getOverviewStats({required String partnerId}) async {
    final url = Uri.parse("$baseUrl/stats/overview?partner_id=$partnerId");

    final response = await http.get(url);

    print("🔵 RAW OVERVIEW RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("🟢 PARSED OVERVIEW DATA: $data");
      return data;
    } else {
      print("🔴 ERROR OVERVIEW: ${response.body}");
      return null;
    }
  }


  /// ------------------------------------------------------
  /// 📌 2 — LAST 7 DAYS STATS
  /// ------------------------------------------------------
  Future<Map<String, dynamic>?> getLast7Days({required String partnerId}) async {
    final url = Uri.parse("$baseUrl/stats/last-7-days?partner_id=$partnerId");

    final response = await http.get(url);

    print("🔵 RAW 7-DAYS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print("🟢 PARSED 7-DAYS DATA: $data");
      return data;
    } else {
      print("🔴 ERROR 7-DAYS: ${response.body}");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getPosTransactions({
    required String partnerId,
    String? branchId,
  }) async {
    // Construct the query params
    final queryParams = {
      'partner_id': partnerId,
      if (branchId != null) 'branch_id': branchId,
    };

    final uri = Uri.parse("$baseUrl/stats/pos-transactions").replace(queryParameters: queryParams);

    final response = await http.get(uri);

    print("🔵 RAW POS TRANSACTIONS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("🟢 PARSED POS TRANSACTIONS DATA: $data");

      // Cast each item to Map<String, dynamic>
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      print("🔴 ERROR POS TRANSACTIONS: ${response.body}");
      return null;
    }
  }

}

class POSIntegrationService {
  static const String baseUrl = 'https://usprestigeplusrewardsapp-production.up.railway.app/api/pos'; // Replace with your actual base URL

  /// Start OAuth flow - Opens browser for Square authentication
  static Future<bool> startSquareOAuth({
    required String partnerId,
    required String provider,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/oauth/start').replace(
        queryParameters: {
          'partner_id': partnerId,
          'provider': provider,
        },
      );
      print(uri.toString()); // ✅ Debug print the final URL


        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
    } catch (e) {
      print('Error starting OAuth: $e');
      rethrow;
    }
  }

  /// Check OAuth callback status (polling or webhook)
  /// This is called after the user returns from Square OAuth
  static Future<Map<String, dynamic>> handleOAuthCallback({
    required String code,
    required String partnerId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/pos/oauth/callback').replace(
        queryParameters: {
          'code': code,
          'state': partnerId,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'POS Connected Successfully',
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to connect: ${response.body}',
        };
      }
    } catch (e) {
      print('Error handling OAuth callback: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get current POS connection status
  static Future<Map<String, dynamic>?> getPOSConnection({
    required String partnerId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/connection/$partnerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting POS connection: $e');
      return null;
    }
  }

  /// Disconnect POS integration
  static Future<bool> disconnectPOS({
    required String partnerId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/pos/connection/$partnerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error disconnecting POS: $e');
      return false;
    }
  }

  /// Manual connection with credentials
  static Future<Map<String, dynamic>> connectManually({
    required String partnerId,
    required String token,
    required String applicationId,
    required String accessToken,
    required String applicationSecret,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pos/manual-connect'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'partner_id': partnerId,
          'application_id': applicationId,
          'access_token': accessToken,
          'application_secret': applicationSecret,
          'provider': 'SQUARE',
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected successfully',
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to connect: ${response.body}',
        };
      }
    } catch (e) {
      print('Error manual connection: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>?> getCustomers({
    required String partnerId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/square/customers").replace(
        queryParameters: {'partner_id': partnerId},
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🔵 RAW CUSTOMERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("🟢 PARSED CUSTOMERS DATA: $data");

        // Cast each item to Map<String, dynamic>
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print("🔴 ERROR CUSTOMERS: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔴 EXCEPTION CUSTOMERS: $e");
      return null;
    }
  }

  /// ------------------------------------------------------
  /// 📌 CREATE NEW CUSTOMER
  /// ------------------------------------------------------
  static Future<Map<String, dynamic>?> createCustomer({
    required String partnerId,
    required String token,
    required String givenName,
    required String familyName,
    String? emailAddress,
    String? phoneNumber,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/square/customers").replace(
        queryParameters: {'partner_id': partnerId},
      );

      final body = {
        'givenName': givenName,
        'familyName': familyName,
        if (emailAddress != null && emailAddress.isNotEmpty)
          'emailAddress': emailAddress,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("🔵 RAW CREATE CUSTOMER RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("🟢 PARSED CREATE CUSTOMER DATA: $data");
        return data;
      } else {
        print("🔴 ERROR CREATE CUSTOMER: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔴 EXCEPTION CREATE CUSTOMER: $e");
      return null;
    }
  }

  static Future<bool> disconnect(
      String partnerId,
      String token,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/disconnect?partner_id=$partnerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'];
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
