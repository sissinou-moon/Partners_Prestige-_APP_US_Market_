import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

const API_URL = "https://usprestigeplusrewardsapp-production.up.railway.app/api/partners";
const PARTNERS_API_URL = "https://usprestigeplusrewardsapp-production.up.railway.app/api/partners";

class PartnerException implements Exception {
  final String message;
  final String? code;

  PartnerException(this.message, {this.code});

  @override
  String toString() => message;
}

// ========================
// DATA MODELS
// ========================

// Location Model
class SquareLocation {
  final String id;
  final String name;
  final String? businessName;
  final LocationAddress? address;
  final String? phoneNumber;
  final String? websiteUrl;
  final String status;
  final List<String>? capabilities;
  final String? timezone;
  final String? currency;
  final String? country;
  final String? languageCode;

  SquareLocation({
    required this.id,
    required this.name,
    this.businessName,
    this.address,
    this.phoneNumber,
    this.websiteUrl,
    required this.status,
    this.capabilities,
    this.timezone,
    this.currency,
    this.country,
    this.languageCode,
  });

  factory SquareLocation.fromJson(Map<String, dynamic> json) {
    return SquareLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      businessName: json['business_name'] as String?,
      address: json['address'] != null
          ? LocationAddress.fromJson(json['address'])
          : null,
      phoneNumber: json['phone_number'] as String?,
      websiteUrl: json['website_url'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      capabilities: json['capabilities'] != null
          ? List<String>.from(json['capabilities'])
          : null,
      timezone: json['timezone'] as String?,
      currency: json['currency'] as String?,
      country: json['country'] as String?,
      languageCode: json['language_code'] as String?,
    );
  }

  bool get isActive => status == 'ACTIVE';
}

class LocationAddress {
  final String? addressLine1;
  final String? addressLine2;
  final String? locality;
  final String? administrativeDistrictLevel1;
  final String? postalCode;
  final String? country;

  LocationAddress({
    this.addressLine1,
    this.addressLine2,
    this.locality,
    this.administrativeDistrictLevel1,
    this.postalCode,
    this.country,
  });

  factory LocationAddress.fromJson(Map<String, dynamic> json) {
    return LocationAddress(
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      locality: json['locality'] as String?,
      administrativeDistrictLevel1: json['administrative_district_level_1'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
    );
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      locality,
      administrativeDistrictLevel1,
      postalCode,
      country,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  String get shortAddress {
    final parts = [
      locality,
      administrativeDistrictLevel1,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }
}

class PartnerData {
  String? business_name;
  String? business_type;
  String? category;
  String? email;
  String? phone;
  String? website;
  String? address;
  String? city;
  String? state;
  String? country;
  String? logo_url;
  String? banner_url;
  String? user_id;

  PartnerData({
    this.business_name,
    this.business_type,
    this.category,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.state,
    this.country,
    this.logo_url,
    this.banner_url,
    this.user_id,
  });

  Map<String, dynamic> toJson() => {
    "business_name": business_name,
    "business_type": business_type,
    "email": email,
    "phone": phone,
    "website": website,
    "address": address,
    "city": city,
    "state": state,
    "country": country,
    "category": category,
    "logo_url": logo_url,
    "banner_url": banner_url,
    "user_id": user_id,
  };
}

class Branch {
  final String id;
  final String partnerId;
  final String branchName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? managerName;
  final String status;
  final dynamic operatingHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? posLocationId;
  final Map<String, dynamic>? partner;

  Branch({
    required this.id,
    required this.partnerId,
    required this.branchName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.managerName,
    required this.status,
    this.operatingHours,
    required this.createdAt,
    required this.updatedAt,
    this.posLocationId,
    this.partner,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      partnerId: json['partner_id'],
      branchName: json['branch_name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'],
      email: json['email'],
      managerName: json['manager_name'],
      status: json['status'],
      operatingHours: json['operating_hours'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      posLocationId: json['pos_location_id'],
      partner: json['partners'],
    );
  }
}

class Members {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool approved;
  final String branchId;
  final String? referralCode;
  final String profileImage;
  final String status;

  Members({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.approved,
    required this.branchId,
    this.referralCode,
    required this.profileImage,
    required this.status,
  });

  factory Members.fromJson(Map<String, dynamic> json) {
    return Members(
      id: json["id"],
      fullName: json["full_name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      role: json["role"] ?? "",
      approved: json["approved"] == "true" || json["approved"] == true,
      branchId: json["partner_branch_id"] ?? "",
        referralCode: json["referral_code"] ?? "",
        profileImage: json["profile_image"] ?? "",
        status: json["status"] ?? ""
    );
  }
}


class Partner {
  final String id;
  final String businessName;
  final String? businessType;
  final String? category;
  final String email;
  final String phone;
  final String? website;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final String? logoUrl;
  final String? bannerUrl;
  final String? status;
  final String? createdAt;

  Partner({
    required this.id,
    required this.businessName,
    this.businessType,
    this.category,
    required this.email,
    required this.phone,
    this.website,
    this.address,
    this.city,
    this.state,
    required this.country,
    this.logoUrl,
    this.bannerUrl,
    this.status,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "business_name": businessName,
    "business_type": businessType,
    "category": category,
    "email": email,
    "phone": phone,
    "website": website,
    "address": address,
    "city": city,
    "state": state,
    "country": country,
    "logo_url": logoUrl,
    "banner_url": bannerUrl,
    "status": status,
    "created_at": createdAt,
  };

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      businessType: json['business_type'] as String?,
      category: json['category'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class BranchComparison {
  final String locationName;
  final int membersServed;
  final int pointsEarnedToday;
  final int redemptionsToday;
  final String trendDirection;
  final double? trendPercent;

  BranchComparison({
    required this.locationName,
    required this.membersServed,
    required this.pointsEarnedToday,
    required this.redemptionsToday,
    required this.trendDirection,
    this.trendPercent,
  });

  factory BranchComparison.fromJson(Map<String, dynamic> json) {
    return BranchComparison(
      locationName: json['location_name'] as String,
      membersServed: json['members_served'] as int,
      pointsEarnedToday: json['points_earned_today'] as int,
      redemptionsToday: json['redemptions_today'] as int,
      trendDirection: json['trend_direction'] as String,
      trendPercent: json['trend_percent'] != null
          ? (json['trend_percent'] as num).toDouble()
          : null,
    );
  }
}

// ========================
// PARTNER SERVICE
// ========================

class PartnerService {
  /// Upload partner logo
  static Future<String> uploadLogo({
    required String partnerId,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse("$PARTNERS_API_URL/upload-partner-logo");

      final request = http.MultipartRequest('POST', url)
        ..fields['partner_id'] = partnerId
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await imageFile.readAsBytes(),
            filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['message'] ?? 'Failed to upload logo',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return responseData['imageUrl'] as String;
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Logo upload error: $e');
    }
  }

  /// Upload partner banner
  static Future<String> uploadBanner({
    required String partnerId,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse("$PARTNERS_API_URL/upload-partner-banner");

      final request = http.MultipartRequest('POST', url)
        ..fields['partner_id'] = partnerId
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
        throw PartnerException(
          errorBody['message'] ?? 'Failed to upload banner',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return responseData['imageUrl'] as String;
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Banner upload error: $e');
    }
  }

  /// Create a new partner
  static Future<Partner> createPartner({
    required PartnerData partnerData,
  }) async {
    try {
      final url = Uri.parse("$API_URL/");

      final body = jsonEncode(partnerData.toJson());

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode != 201) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['error'] ?? 'Failed to create partner account',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return Partner.fromJson(responseData['partner'] as Map<String, dynamic>);
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Create partner error: $e');
    }
  }

  /// Get partner by owner user ID
  static Future<Partner> getPartnerByOwner(String userId) async {
    try {
      final url = Uri.parse("$API_URL/owner/$userId");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['error'] ?? 'Failed to load partner data',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return Partner.fromJson(responseData['partner'] as Map<String, dynamic>);
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Get partner error: $e');
    }
  }

  /// Get partner by ID
  static Future<Partner> getPartnerById(String partnerId) async {
    try {
      final url = Uri.parse("$API_URL/$partnerId");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['error'] ?? 'Failed to load partner data',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return Partner.fromJson(responseData['partner'] as Map<String, dynamic>);
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Get partner error: $e');
    }
  }

  /// Update partner information
  static Future<Partner> updatePartner({
    required String partnerId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final url = Uri.parse("$API_URL/$partnerId");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['error'] ?? 'Failed to update partner',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return Partner.fromJson(responseData['partner'] as Map<String, dynamic>);
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Update partner error: $e');
    }
  }

  /// Get partner statistics
  static Future<Map<String, dynamic>> getPartnerStats(String partnerId) async {
    try {
      final url = Uri.parse("$API_URL/$partnerId/stats");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw PartnerException(
          errorBody['error'] ?? 'Failed to fetch partner stats',
          code: response.statusCode.toString(),
        );
      }

      final responseData = jsonDecode(response.body);
      return responseData['stats'] as Map<String, dynamic>;
    } on PartnerException {
      rethrow;
    } catch (e) {
      throw PartnerException('Get partner stats error: $e');
    }
  }

  static Future<List<Branch>> getBranches(String partnerId) async {
    final url = Uri.parse(
        "$API_URL/$partnerId/branches");

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw PartnerException("Failed to load branches");
    }

    final decoded = jsonDecode(response.body);

    if (decoded['success'] != true) {
      throw PartnerException(decoded['error'] ?? 'Unknown error');
    }

    final List list = decoded['branches'];

    return list.map((e) => Branch.fromJson(e)).toList();
  }

  static Future<Branch> getBranchDetails(String partnerId, String branchId) async {
    final url = Uri.parse("$API_URL/$partnerId/branches/$branchId");

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw PartnerException("Failed to load branch details");
    }

    final decoded = jsonDecode(response.body);

    if (decoded['success'] != true) {
      throw PartnerException(decoded['error'] ?? 'Unknown error');
    }

    return Branch.fromJson(decoded['branches']);
  }

  static Future<List<Members>> getPartnerUsers(String partnerId) async {
    try {
      final token = await LocalStorage.getToken();

      final url = Uri.parse("$API_URL/$partnerId/branch-users");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw PartnerException(err['error'] ?? "Failed to load partner users");
      }

      final decoded = jsonDecode(response.body);

      final List users = decoded["data"];

      return users.map((e) => Members.fromJson(e)).toList();
    } catch (e) {
      throw PartnerException("Get partner users error: $e");
    }
  }

  static Future<Members> updatePartnerUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final token = await LocalStorage.getToken();

      final url = Uri.parse("$API_URL/modify/branch-users/$userId");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw PartnerException(err["error"] ?? "Failed to update user");
      }

      final decoded = jsonDecode(response.body);

      return Members.fromJson(decoded["user"]);
    } catch (e) {
      throw PartnerException("Update user error: $e");
    }
  }

  static Future<List<BranchComparison>> getBranchesComparison(String partnerId) async {
    try {
      final token = await LocalStorage.getToken();
      final url = Uri.parse("$API_URL/$partnerId/branches-comparison");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw PartnerException(err['error'] ?? "Failed to load branches comparison");
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        throw PartnerException(decoded['error'] ?? 'Unknown error');
      }

      final List branches = decoded['branches'];
      return branches.map((e) => BranchComparison.fromJson(e)).toList();
    } catch (e) {
      throw PartnerException("Get branches comparison error: $e");
    }
  }

  static Future<Map<String, dynamic>> updateNotificationSettings({
    required String userId,
    required Map<String, dynamic> notifications,
    required String token,
  }) async {
    final url = Uri.parse("$API_URL/notifications/$userId");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(notifications),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        return body["user"];
      } else {
        throw Exception(body["error"] ?? "Failed to update notifications");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<SquareLocation>> getSquareLocations(String partnerId) async {
    try {
      final url = Uri.parse("https://usprestigeplusrewardsapp-production.up.railway.app/api/pos/square/locations?partner_id=$partnerId");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Failed to load locations: ${response.statusCode}");
      }

      final List<dynamic> locationsJson = jsonDecode(response.body);

      return locationsJson
          .map((json) => SquareLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching Square locations: $e");
      throw Exception("Failed to load Square locations: $e");
    }
  }

  /// Sync locations from Square to local database branches
  static Future<bool> syncLocationsToDatabase(String partnerId) async {
    try {
      final url = Uri.parse("$API_URL/api/pos/square/sync-locations");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partner_id": partnerId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to sync locations: ${response.statusCode}");
      }

      final result = jsonDecode(response.body);
      return result['success'] == true;
    } catch (e) {
      print("Error syncing locations: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCashierBranch(String branchId) async {
    try {
      final uri = Uri.parse("$API_URL/cashier/branch")
          .replace(queryParameters: {"partner_branch_id": branchId});

      final response = await http.get(uri);

      print("🔵 RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("🔴 ERROR: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔴 EXCEPTION getCashierBranch: $e");
      return null;
    }
  }

}

// ========================
// USAGE EXAMPLES
// ========================

/*
// Create partner
try {
  final partnerData = PartnerData(
    business_name: 'My Restaurant',
    business_type: 'RESTAURANT',
    category: 'Restaurants & Cafes',
    email: 'info@restaurant.com',
    phone: '+1234567890',
    address: '123 Main St',
    city: 'New York',
    state: 'NY',
    country: 'USA',
    user_id: 'user_123',
  );

  final partner = await PartnerService.createPartner(partnerData: partnerData);
  print('Partner created: ${partner.id}');
} on PartnerException catch (e) {
  print('Error: ${e.message}');
}

// Upload logo
try {
  final logoUrl = await PartnerService.uploadLogo(
    partnerId: 'partner_123',
    imageFile: File('/path/to/logo.jpg'),
  );
  print('Logo uploaded: $logoUrl');
} on PartnerException catch (e) {
  print('Error: ${e.message}');
}

// Upload banner
try {
  final bannerUrl = await PartnerService.uploadBanner(
    partnerId: 'partner_123',
    imageFile: File('/path/to/banner.jpg'),
  );
  print('Banner uploaded: $bannerUrl');
} on PartnerException catch (e) {
  print('Error: ${e.message}');
}

// Get partner
try {
  final partner = await PartnerService.getPartnerByOwner('user_123');
  print('Partner: ${partner.businessName}');
} on PartnerException catch (e) {
  print('Error: ${e.message}');
}
*/