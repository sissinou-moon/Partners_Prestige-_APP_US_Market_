import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

const API_URL = "https://usprestigeplusrewardsapp-production.up.railway.app/api";

class AuthData {
  String? fullName;
  String? email;
  String? password;
  String? phone;
  String? country;
  String? referralCode;
  int? streakCount;
  String? lastActiveAt;
  String? birthday;
  String? address;
  String? role;

  AuthData({
    this.fullName,
    this.email,
    this.password,
    this.phone,
    this.country,
    this.referralCode,
    this.streakCount,
    this.lastActiveAt,
    this.birthday,
    this.address,
    this.role,
  });

  Map<String, dynamic> toJson() => {
    "full_name": fullName,
    "email": email,
    "password": password,
    "phone": phone,
    "country": country,
    "referral_code": referralCode,
    "streak_count": streakCount,
    "last_active_at": lastActiveAt,
    "birthday": birthday,
    "address": address,
    "role": role,
  };
}

class ApiService {
  // Sign In (email or phone)
  static Future<Map<String, dynamic>> signIn({
    String? email,
    required String password,
    required bool isEmail,
  }) async {
    final url = Uri.parse("$API_URL/auth/login");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "isEmail": isEmail,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? "Login failed");
    }

    final data = jsonDecode(res.body);
    if (data['token'] != null) {
      await LocalStorage.setToken(data['token']); // save JWT
    }
    return data;
  }

  // Sign Up (email)
  static Future<Map<String, dynamic>> signUpEmail({
    required String email,
    required String fullName,
    required String password,
    required String phone,
    required String country,
    String? referralCode,
    String? birthday,
    String role = "MERCHANT",
  }) async {
    final url = Uri.parse("$API_URL/auth/email/register");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "full_name": fullName,
        "password": password,
        "phone": phone,
        "country": country,
        "referral_code": referralCode,
        "birthday": birthday,
        "role": role,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['message'] ?? "Registration failed");
    }

    return jsonDecode(res.body);
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyEmailOTP({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse("$API_URL/email/verify");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? "OTP verification failed");
    }

    final data = jsonDecode(res.body);
    if (data['token'] != null) {
      await LocalStorage.setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyToken(String token) async {
    final res = await http.get(Uri.parse('$API_URL/auth/verify'), headers: {"Authorization": "Bearer $token"});
    final json = jsonDecode(res.body);
    if (res.statusCode != 200 || json['user'] == null) throw Exception(json['message'] ?? 'Invalid token');
    return json['user'];
  }

  static Future<void> resendEmailOTP(String email) async {
    final url = Uri.parse('$API_URL/auth/email/resend');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('OTP sent successfully: ${data['message']}');
    } else {
      print('Failed to resend OTP: ${response.body}');
    }
  }
}
