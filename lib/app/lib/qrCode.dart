import 'dart:convert';
import 'package:http/http.dart' as http;

class QRRedeemService {
  static const String baseUrl =
      "https://usprestigeplusrewardsapp-production.up.railway.app/api/qr";

  /// ------------------------------------------------------
  /// 📌 CREATE REDEEM QR CODE
  /// ------------------------------------------------------
  static Future<Map<String, dynamic>?> createRedeemQr({
    required String token,
    required String rewardId,
    String? partnerId,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/generate/redeem");

      final body = {
        'reward_id': rewardId,
        if (partnerId != null) 'partner_id': partnerId,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("🔵 RAW CREATE QR RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("🟢 PARSED CREATE QR DATA: $data");
        return data;
      } else {
        print("🔴 ERROR CREATE QR: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔴 EXCEPTION CREATE QR: $e");
      return null;
    }
  }

  /// ------------------------------------------------------
  /// 📌 SCAN AND REDEEM QR CODE
  /// ------------------------------------------------------
  static Future<Map<String, dynamic>?> scanRedeemQr({
    required String token,
    required String userId,
    String? qrId,
    String? encryptedData,
    String? nonce,
    String? authTag,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/scan/redeem");

      final body = {
        'user_id': userId,
        if (qrId != null) 'qr_id': qrId,
        if (encryptedData != null) 'encrypted_data': encryptedData,
        if (nonce != null) 'nonce': nonce,
        if (authTag != null) 'authTag': authTag,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("🔵 RAW SCAN QR RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("🟢 PARSED SCAN QR DATA: $data");
        return {'success': true, 'data': data};
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        print("🔴 ERROR SCAN QR: ${response.body}");
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to redeem',
          'balance': errorData['balance'],
          'required': errorData['required'],
        };
      }
    } catch (e) {
      print("🔴 EXCEPTION SCAN QR: $e");
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> scanEarnQr({
    required String token,
    required String userId,
    required int pointsToAdd,
    required String partnerId,
    required String partnerBranchId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan/earn'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'pointsToAdd': pointsToAdd,
          'partner_id': partnerId,
          'partner_branch_id': partnerBranchId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error scanning earn QR: $e');
      return null;
    }
  }

  /// ------------------------------------------------------
  /// 📌 PARSE QR CODE DATA
  /// ------------------------------------------------------
  static Map<String, dynamic>? parseQrData(String qrContent) {
    try {
      // Try to parse as JSON first
      final Map<String, dynamic> data = jsonDecode(qrContent);
      print("🟢 PARSED QR DATA (JSON): $data");
      return data;
    } catch (e) {
      print("⚠️ Not JSON format, trying other formats...");

      // Try to parse as comma-separated values (CSV)
      // Format: qr_id,encrypted_data,nonce,authTag,reward_id
      if (qrContent.contains(',')) {
        try {
          final parts = qrContent.split(',');
          if (parts.length >= 4) {
            final parsed = {
              'qr_id': parts[0].trim(),
              'encrypted_data': parts[1].trim(),
              'nonce': parts[2].trim(),
              'authTag': parts[3].trim(),
            };
            // Optional 5th part (reward_id)
            if (parts.length >= 5) {
              parsed['user_id'] = parts[4].trim();
            }
            print("🟢 PARSED QR DATA (CSV): $parsed");
            return parsed;
          }
        } catch (e2) {
          print("🔴 FAILED TO PARSE AS CSV: $e2");
        }
      }

      // Try to parse as query string format
      try {
        final uri = Uri.parse(
          qrContent.contains('?') ? qrContent : '?$qrContent',
        );
        if (uri.queryParameters.isNotEmpty) {
          print("🟢 PARSED QR DATA (Query String): ${uri.queryParameters}");
          return uri.queryParameters;
        }
      } catch (e3) {
        print("🔴 FAILED TO PARSE AS QUERY STRING: $e3");
      }

      print("🔴 FAILED TO PARSE QR DATA IN ANY FORMAT");
      return null;
    }
  }

  static Future<List<dynamic>> getRewardsForPartner(String partnerId) async {
    try {
      final url = Uri.parse(
        "$baseUrl/scan/redeem",
      ).replace(queryParameters: {'partner_id': partnerId});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['rewards'] as List<dynamic>;
      } else {
        print(
          'Error fetching rewards: ${response.statusCode} ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Exception fetching rewards: $e');
      return [];
    }
  }
}
