import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class RewardService {
  static const String baseUrl =
      "https://usprestigeplusrewardsapp-production.up.railway.app/api/db";
  final String token;

  RewardService(this.token);

  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  static Future<List<Map<String, dynamic>>> getPartnerRewards(
    String partnerId,
  ) async {
    final url = Uri.parse("$baseUrl/get/partner_rewards?partner_id=$partnerId");

    final response = await http.get(url);

    print("🔵 RAW REWARDS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final rewards = List<Map<String, dynamic>>.from(decoded["rewards"] ?? []);
      print("🟢 PARSED REWARDS: $rewards");
      return rewards;
    } else {
      print("🔴 ERROR REWARDS: ${response.body}");
      throw Exception("Failed to load rewards");
    }
  }

  // Create Reward
  Future<Map<String, dynamic>> createReward(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/rewards"),
      headers: headers,
      body: jsonEncode(payload),
    );

    return jsonDecode(res.body);
  }

  // Update Reward
  Future<Map<String, dynamic>> updateReward(
    String rewardId,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/rewards/$rewardId"),
      headers: headers,
      body: jsonEncode(payload),
    );

    return jsonDecode(res.body);
  }

  Future<String> uploadBanner({
    required String rewardID,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/rewards/$rewardID/upload-reward-banner");

      final request = http.MultipartRequest('POST', url)
        ..fields['reward_id'] = rewardID
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await imageFile.readAsBytes(),
            filename: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw {"error": "Failed to upload reward banner : $errorBody"};
      }

      final responseData = jsonDecode(response.body);
      return responseData['imageUrl'] as String;
    } catch (e) {
      throw {"error": "Failed to upload reward banner : $e"};
    }
  }
}
