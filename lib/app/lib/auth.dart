import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

const API_URL =
    "https://usprestigeplusrewardsapp-production.up.railway.app/api";

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
    String role = "CASHIER",
    String? branchId,
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
        "partner_branch_id": branchId,
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
    final url = Uri.parse("$API_URL/auth/email/verify");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['message'] ?? "OTP verification failed",
      );
    }

    final data = jsonDecode(res.body);
    if (data['token'] != null) {
      await LocalStorage.setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyToken(String token) async {
    final res = await http.get(
      Uri.parse('$API_URL/auth/verify'),
      headers: {"Authorization": "Bearer $token"},
    );
    final json = jsonDecode(res.body);
    if (res.statusCode != 200 || json['user'] == null)
      throw Exception(json['message'] ?? 'Invalid token');
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

  // Send Password Reset OTP
  static Future<void> sendPasswordResetOTP({
    required bool isEmail,
    String? email,
    String? phone,
  }) async {
    final url = Uri.parse("$API_URL/auth/password/send");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"isEmail": isEmail, "email": email, "phone": phone}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? "Failed to send OTP");
    }
  }

  // Check Password OTP
  static Future<void> checkPasswordOTP(String email, String otp) async {
    final url = Uri.parse("$API_URL/auth/password/check");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? "Invalid OTP");
    }
  }

  // Reset Password
  static Future<void> resetPassword(String email, String newPassword) async {
    final url = Uri.parse("$API_URL/auth/password/reset");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "newPassword": newPassword}),
    );

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['message'] ?? "Failed to reset password",
      );
    }
  }

  // Contact Support
  static Future<Map<String, dynamic>> contactSupport({
    required String token,
    required String email,
    required String userId,
    required String subject,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$API_URL/user/contact-support'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "email": email,
        "user_id": userId,
        "subject": subject,
        "message": message,
      }),
    );

    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(json['message'] ?? 'Failed to send support request');
    }
    return json;
  }

  // Register Member
  static Future<void> registerMember({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String country,
    required String birthday,
    required String role,
    required String partnerBranchId,
  }) async {
    final res = await http.post(
      Uri.parse('$API_URL/auth/member/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "full_name": fullName,
        "phone": phone,
        "country": country,
        "birthday": birthday,
        "role": role,
        "partner_branch_id": partnerBranchId,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(
        jsonDecode(res.body)['message'] ?? 'Failed to register member',
      );
    }
  }

  // Edit User Profile
  static Future<Map<String, dynamic>> editUserProfile(
    String token,
    Map<String, dynamic> form,
  ) async {
    final res = await http.put(
      Uri.parse('$API_URL/user/profile'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(form),
    );
    final jsonData = jsonDecode(res.body);
    if (res.statusCode != 200 || jsonData['user'] == null) {
      throw Exception(jsonData['message'] ?? 'Failed to update profile');
    }
    return jsonData;
  }

  // Upload Profile Image
  static Future<Map<String, dynamic>> uploadProfileImage(
    String token,
    String filePath,
  ) async {
    final url = Uri.parse("$API_URL/user/upload-profile-image");

    // Create multipart request
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    // Send request
    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Failed to upload image: $responseData");
    }

    final Map<String, dynamic> json = jsonDecode(responseData);
    return json;
  }
}
