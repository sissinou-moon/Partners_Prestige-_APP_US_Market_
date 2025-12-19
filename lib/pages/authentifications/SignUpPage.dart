import 'package:flutter/material.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../app/lib/supabase.dart';
import '../../styles/styles.dart';
import 'OTPPage.dart';

// US States list
const List<String> usStates = [
  'Alabama',
  'Alaska',
  'Arizona',
  'Arkansas',
  'California',
  'Colorado',
  'Connecticut',
  'Delaware',
  'Florida',
  'Georgia',
  'Hawaii',
  'Idaho',
  'Illinois',
  'Indiana',
  'Iowa',
  'Kansas',
  'Kentucky',
  'Louisiana',
  'Maine',
  'Maryland',
  'Massachusetts',
  'Michigan',
  'Minnesota',
  'Mississippi',
  'Missouri',
  'Montana',
  'Nebraska',
  'Nevada',
  'New Hampshire',
  'New Jersey',
  'New Mexico',
  'New York',
  'North Carolina',
  'North Dakota',
  'Ohio',
  'Oklahoma',
  'Oregon',
  'Pennsylvania',
  'Rhode Island',
  'South Carolina',
  'South Dakota',
  'Tennessee',
  'Texas',
  'Utah',
  'Vermont',
  'Virginia',
  'Washington',
  'West Virginia',
  'Wisconsin',
  'Wyoming',
  'District of Columbia',
];

// Major US cities by state
const Map<String, List<String>> usCities = {
  'Alabama': [
    'Birmingham',
    'Montgomery',
    'Huntsville',
    'Mobile',
    'Tuscaloosa',
    'Hoover',
    'Dothan',
    'Auburn',
    'Decatur',
    'Madison',
  ],
  'Alaska': [
    'Anchorage',
    'Fairbanks',
    'Juneau',
    'Sitka',
    'Ketchikan',
    'Wasilla',
    'Kenai',
    'Kodiak',
    'Bethel',
    'Palmer',
  ],
  'Arizona': [
    'Phoenix',
    'Tucson',
    'Mesa',
    'Chandler',
    'Scottsdale',
    'Glendale',
    'Gilbert',
    'Tempe',
    'Peoria',
    'Surprise',
  ],
  'Arkansas': [
    'Little Rock',
    'Fort Smith',
    'Fayetteville',
    'Springdale',
    'Jonesboro',
    'Rogers',
    'Conway',
    'North Little Rock',
    'Bentonville',
    'Pine Bluff',
  ],
  'California': [
    'Los Angeles',
    'San Diego',
    'San Jose',
    'San Francisco',
    'Fresno',
    'Sacramento',
    'Long Beach',
    'Oakland',
    'Bakersfield',
    'Anaheim',
    'Santa Ana',
    'Riverside',
    'Stockton',
    'Irvine',
    'Chula Vista',
  ],
  'Colorado': [
    'Denver',
    'Colorado Springs',
    'Aurora',
    'Fort Collins',
    'Lakewood',
    'Thornton',
    'Arvada',
    'Westminster',
    'Pueblo',
    'Centennial',
  ],
  'Connecticut': [
    'Bridgeport',
    'New Haven',
    'Hartford',
    'Stamford',
    'Waterbury',
    'Norwalk',
    'Danbury',
    'New Britain',
    'Bristol',
    'Meriden',
  ],
  'Delaware': [
    'Wilmington',
    'Dover',
    'Newark',
    'Middletown',
    'Smyrna',
    'Milford',
    'Seaford',
    'Georgetown',
    'Elsmere',
    'New Castle',
  ],
  'Florida': [
    'Jacksonville',
    'Miami',
    'Tampa',
    'Orlando',
    'St. Petersburg',
    'Hialeah',
    'Tallahassee',
    'Fort Lauderdale',
    'Port St. Lucie',
    'Cape Coral',
    'Pembroke Pines',
    'Hollywood',
    'Gainesville',
    'Coral Springs',
  ],
  'Georgia': [
    'Atlanta',
    'Augusta',
    'Columbus',
    'Macon',
    'Savannah',
    'Athens',
    'Sandy Springs',
    'Roswell',
    'Johns Creek',
    'Albany',
  ],
  'Hawaii': [
    'Honolulu',
    'Pearl City',
    'Hilo',
    'Kailua',
    'Waipahu',
    'Kaneohe',
    'Mililani Town',
    'Kahului',
    'Ewa Gentry',
    'Kihei',
  ],
  'Idaho': [
    'Boise',
    'Meridian',
    'Nampa',
    'Idaho Falls',
    'Pocatello',
    'Caldwell',
    'Coeur d\'Alene',
    'Twin Falls',
    'Lewiston',
    'Post Falls',
  ],
  'Illinois': [
    'Chicago',
    'Aurora',
    'Naperville',
    'Joliet',
    'Rockford',
    'Springfield',
    'Elgin',
    'Peoria',
    'Champaign',
    'Waukegan',
  ],
  'Indiana': [
    'Indianapolis',
    'Fort Wayne',
    'Evansville',
    'South Bend',
    'Carmel',
    'Fishers',
    'Bloomington',
    'Hammond',
    'Gary',
    'Lafayette',
  ],
  'Iowa': [
    'Des Moines',
    'Cedar Rapids',
    'Davenport',
    'Sioux City',
    'Iowa City',
    'Waterloo',
    'Ames',
    'West Des Moines',
    'Council Bluffs',
    'Ankeny',
  ],
  'Kansas': [
    'Wichita',
    'Overland Park',
    'Kansas City',
    'Olathe',
    'Topeka',
    'Lawrence',
    'Shawnee',
    'Manhattan',
    'Lenexa',
    'Salina',
  ],
  'Kentucky': [
    'Louisville',
    'Lexington',
    'Bowling Green',
    'Owensboro',
    'Covington',
    'Richmond',
    'Georgetown',
    'Florence',
    'Hopkinsville',
    'Nicholasville',
  ],
  'Louisiana': [
    'New Orleans',
    'Baton Rouge',
    'Shreveport',
    'Lafayette',
    'Lake Charles',
    'Kenner',
    'Bossier City',
    'Monroe',
    'Alexandria',
    'New Iberia',
  ],
  'Maine': [
    'Portland',
    'Lewiston',
    'Bangor',
    'South Portland',
    'Auburn',
    'Biddeford',
    'Sanford',
    'Brunswick',
    'Saco',
    'Westbrook',
  ],
  'Maryland': [
    'Baltimore',
    'Columbia',
    'Germantown',
    'Silver Spring',
    'Waldorf',
    'Frederick',
    'Ellicott City',
    'Glen Burnie',
    'Gaithersburg',
    'Rockville',
  ],
  'Massachusetts': [
    'Boston',
    'Worcester',
    'Springfield',
    'Cambridge',
    'Lowell',
    'Brockton',
    'New Bedford',
    'Quincy',
    'Lynn',
    'Fall River',
  ],
  'Michigan': [
    'Detroit',
    'Grand Rapids',
    'Warren',
    'Sterling Heights',
    'Ann Arbor',
    'Lansing',
    'Flint',
    'Dearborn',
    'Livonia',
    'Troy',
  ],
  'Minnesota': [
    'Minneapolis',
    'Saint Paul',
    'Rochester',
    'Duluth',
    'Bloomington',
    'Brooklyn Park',
    'Plymouth',
    'Saint Cloud',
    'Eagan',
    'Woodbury',
  ],
  'Mississippi': [
    'Jackson',
    'Gulfport',
    'Southaven',
    'Hattiesburg',
    'Biloxi',
    'Meridian',
    'Tupelo',
    'Greenville',
    'Olive Branch',
    'Horn Lake',
  ],
  'Missouri': [
    'Kansas City',
    'St. Louis',
    'Springfield',
    'Columbia',
    'Independence',
    'Lee\'s Summit',
    'O\'Fallon',
    'St. Joseph',
    'St. Charles',
    'Blue Springs',
  ],
  'Montana': [
    'Billings',
    'Missoula',
    'Great Falls',
    'Bozeman',
    'Butte',
    'Helena',
    'Kalispell',
    'Havre',
    'Anaconda',
    'Miles City',
  ],
  'Nebraska': [
    'Omaha',
    'Lincoln',
    'Bellevue',
    'Grand Island',
    'Kearney',
    'Fremont',
    'Hastings',
    'Norfolk',
    'North Platte',
    'Columbus',
  ],
  'Nevada': [
    'Las Vegas',
    'Henderson',
    'Reno',
    'North Las Vegas',
    'Sparks',
    'Carson City',
    'Fernley',
    'Elko',
    'Mesquite',
    'Boulder City',
  ],
  'New Hampshire': [
    'Manchester',
    'Nashua',
    'Concord',
    'Derry',
    'Dover',
    'Rochester',
    'Salem',
    'Merrimack',
    'Hudson',
    'Londonderry',
  ],
  'New Jersey': [
    'Newark',
    'Jersey City',
    'Paterson',
    'Elizabeth',
    'Edison',
    'Woodbridge',
    'Lakewood',
    'Toms River',
    'Hamilton',
    'Trenton',
  ],
  'New Mexico': [
    'Albuquerque',
    'Las Cruces',
    'Rio Rancho',
    'Santa Fe',
    'Roswell',
    'Farmington',
    'Clovis',
    'Hobbs',
    'Alamogordo',
    'Carlsbad',
  ],
  'New York': [
    'New York City',
    'Buffalo',
    'Rochester',
    'Yonkers',
    'Syracuse',
    'Albany',
    'New Rochelle',
    'Mount Vernon',
    'Schenectady',
    'Utica',
  ],
  'North Carolina': [
    'Charlotte',
    'Raleigh',
    'Greensboro',
    'Durham',
    'Winston-Salem',
    'Fayetteville',
    'Cary',
    'Wilmington',
    'High Point',
    'Concord',
  ],
  'North Dakota': [
    'Fargo',
    'Bismarck',
    'Grand Forks',
    'Minot',
    'West Fargo',
    'Williston',
    'Dickinson',
    'Mandan',
    'Jamestown',
    'Wahpeton',
  ],
  'Ohio': [
    'Columbus',
    'Cleveland',
    'Cincinnati',
    'Toledo',
    'Akron',
    'Dayton',
    'Parma',
    'Canton',
    'Youngstown',
    'Lorain',
  ],
  'Oklahoma': [
    'Oklahoma City',
    'Tulsa',
    'Norman',
    'Broken Arrow',
    'Lawton',
    'Edmond',
    'Moore',
    'Midwest City',
    'Enid',
    'Stillwater',
  ],
  'Oregon': [
    'Portland',
    'Salem',
    'Eugene',
    'Gresham',
    'Hillsboro',
    'Beaverton',
    'Bend',
    'Medford',
    'Springfield',
    'Corvallis',
  ],
  'Pennsylvania': [
    'Philadelphia',
    'Pittsburgh',
    'Allentown',
    'Reading',
    'Scranton',
    'Bethlehem',
    'Lancaster',
    'Harrisburg',
    'Altoona',
    'Erie',
  ],
  'Rhode Island': [
    'Providence',
    'Warwick',
    'Cranston',
    'Pawtucket',
    'East Providence',
    'Woonsocket',
    'Newport',
    'Central Falls',
    'Westerly',
    'North Providence',
  ],
  'South Carolina': [
    'Charleston',
    'Columbia',
    'North Charleston',
    'Mount Pleasant',
    'Rock Hill',
    'Greenville',
    'Summerville',
    'Goose Creek',
    'Hilton Head Island',
    'Florence',
  ],
  'South Dakota': [
    'Sioux Falls',
    'Rapid City',
    'Aberdeen',
    'Brookings',
    'Watertown',
    'Mitchell',
    'Yankton',
    'Pierre',
    'Huron',
    'Vermillion',
  ],
  'Tennessee': [
    'Nashville',
    'Memphis',
    'Knoxville',
    'Chattanooga',
    'Clarksville',
    'Murfreesboro',
    'Franklin',
    'Jackson',
    'Johnson City',
    'Bartlett',
  ],
  'Texas': [
    'Houston',
    'San Antonio',
    'Dallas',
    'Austin',
    'Fort Worth',
    'El Paso',
    'Arlington',
    'Corpus Christi',
    'Plano',
    'Laredo',
    'Lubbock',
    'Garland',
    'Irving',
    'Frisco',
    'McKinney',
  ],
  'Utah': [
    'Salt Lake City',
    'West Valley City',
    'Provo',
    'West Jordan',
    'Orem',
    'Sandy',
    'Ogden',
    'St. George',
    'Layton',
    'Taylorsville',
  ],
  'Vermont': [
    'Burlington',
    'South Burlington',
    'Rutland',
    'Barre',
    'Montpelier',
    'Winooski',
    'St. Albans',
    'Newport',
    'Vergennes',
    'Middlebury',
  ],
  'Virginia': [
    'Virginia Beach',
    'Norfolk',
    'Chesapeake',
    'Richmond',
    'Newport News',
    'Alexandria',
    'Hampton',
    'Roanoke',
    'Portsmouth',
    'Suffolk',
  ],
  'Washington': [
    'Seattle',
    'Spokane',
    'Tacoma',
    'Vancouver',
    'Bellevue',
    'Kent',
    'Everett',
    'Renton',
    'Spokane Valley',
    'Federal Way',
  ],
  'West Virginia': [
    'Charleston',
    'Huntington',
    'Morgantown',
    'Parkersburg',
    'Wheeling',
    'Weirton',
    'Fairmont',
    'Martinsburg',
    'Beckley',
    'Clarksburg',
  ],
  'Wisconsin': [
    'Milwaukee',
    'Madison',
    'Green Bay',
    'Kenosha',
    'Racine',
    'Appleton',
    'Waukesha',
    'Eau Claire',
    'Oshkosh',
    'Janesville',
  ],
  'Wyoming': [
    'Cheyenne',
    'Casper',
    'Laramie',
    'Gillette',
    'Rock Springs',
    'Sheridan',
    'Green River',
    'Evanston',
    'Riverton',
    'Cody',
  ],
  'District of Columbia': ['Washington'],
};

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // ========================
  // CONTROLLERS
  // ========================
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Business Setup
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessPhoneController = TextEditingController();
  final TextEditingController supportEmailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  // ========================
  // STATE VARIABLES
  // ========================
  bool isLoading = false;
  bool showPassword = false;
  bool agreedToTerms = false;
  bool isEmailSignup = false;

  int? selectedYear;
  String? selectedMonth;
  int? selectedDay;

  String? userRole;
  Map<String, dynamic>? businessSetup;

  String? selectedBusinessType;
  String? selectedBusinessCategory;
  String? selectedPOS;

  Map<String, dynamic> categories = {};

  List<NewPartner> availablePartners = [];
  NewPartner? selectedPartner;
  PartnerBranch? selectedBranch;
  bool isLoadingPartners = false;

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => isLoadingPartners = true);
    try {
      final partners = await PartnerService.fetchPartnersWithBranches();
      setState(() {
        availablePartners = partners;
        isLoadingPartners = false;
      });
    } catch (e) {
      print('Error loading partners: $e');
      setState(() => isLoadingPartners = false);
      _showSnackBar('Failed to load partners: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/categories.json');
      setState(() {
        categories = jsonDecode(jsonString);
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  int daysInMonth(String? month, int? year) {
    if (month == null || year == null) return 31;
    int monthIndex = months.indexOf(month) + 1;
    return DateTime(year, monthIndex + 1, 0).day;
  }

  Future<void> _handleSignUp() async {
    // Validation
    if (fullNameController.text.trim().isEmpty) {
      _showSnackBar("Please enter your full name");
      return;
    }

    if (userRole == "CASHIER") {
      if (selectedPartner == null) {
        _showSnackBar("Please select a partner business");
        return;
      }
      if (selectedBranch == null) {
        _showSnackBar("Please select a branch location");
        return;
      }
    }

    if (phoneController.text.trim().isEmpty) {
      _showSnackBar("Please enter your phone number");
      return;
    }

    if (passwordController.text.isEmpty) {
      _showSnackBar("Please enter a password");
      return;
    }

    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      _showSnackBar("Please select your complete birthday");
      return;
    }

    if (!agreedToTerms) {
      _showSnackBar("Please accept the terms and conditions");
      return;
    }

    if (userRole == null) {
      _showSnackBar("Please select an account type (Cashier or Owner)");
      return;
    }

    if (!_validatePassword()) return;

    // Validate business setup if user is OWNER
    if (userRole == "OWNER" && businessSetup == null) {
      _showSnackBar("Please complete business setup");
      return;
    }

    setState(() => isLoading = true);

    String? userId;
    String? partnerId;

    try {
      final phone = "+1${phoneController.text.trim()}";

      // Step 1: Create User Account
      try {
        final newUser = await ApiService.signUpEmail(
          email: emailController.text.trim(),
          fullName: fullNameController.text.trim(),
          password: passwordController.text.trim(),
          phone: phone,
          country: "USA",
          birthday: "$selectedYear-$selectedMonth-$selectedDay",
          role: userRole ?? "CASHIER",
          branchId: userRole == "CASHIER" ? selectedBranch?.id : null,
        );

        userId = newUser["user"]["id"] as String;
        print("✅ User created successfully: $userId");
      } catch (userError) {
        print("❌ User creation failed: $userError");
        _showSnackBar("Failed to create account: ${userError.toString()}");
        return;
      }

      // Step 2: If OWNER role, create partner account
      if (userRole == "OWNER" && businessSetup != null) {
        try {
          // Create partner data
          final partnerData = PartnerData(
            business_name: businessSetup!["businessName"],
            business_type: businessSetup!["businessType"],
            category: businessSetup!["category"],
            email: businessSetup!["supportEmail"],
            phone: businessSetup!["businessPhone"],
            website: businessSetup!["website"]?.isNotEmpty == true
                ? businessSetup!["website"]
                : null,
            address: businessSetup!["address"],
            city: businessSetup!["city"],
            state: businessSetup!["state"],
            country: businessSetup!["country"] ?? "USA",
            postal_code: businessSetup!["postalCode"],
            license_number: businessSetup!["licenseNumber"],
            user_id: userId,
          );

          // Create partner
          final partner = await PartnerService.createPartner(
            partnerData: partnerData,
          );

          partnerId = partner.id;
          print("✅ Partner created successfully: $partnerId");

          // Step 3: Upload logo if provided
          if (businessSetup!["logoFile"] != null) {
            try {
              final logoUrl = await PartnerService.uploadLogo(
                partnerId: partnerId!,
                imageFile: businessSetup!["logoFile"] as File,
              );
              print("✅ Logo uploaded: $logoUrl");
            } catch (logoError) {
              print("⚠️ Logo upload failed: $logoError");
            }
          }

          // Step 4: Upload banner if provided
          if (businessSetup!["bannerFile"] != null) {
            try {
              final bannerUrl = await PartnerService.uploadBanner(
                partnerId: partnerId!,
                imageFile: businessSetup!["bannerFile"] as File,
              );
              print("✅ Banner uploaded: $bannerUrl");
            } catch (bannerError) {
              print("⚠️ Banner upload failed: $bannerError");
            }
          }

          _showSnackBar("Account and business created successfully!");
        } on PartnerException catch (partnerError) {
          print("❌ Partner creation failed: ${partnerError.message}");
          _showSnackBar(
            "Account created, but business setup failed: ${partnerError.message}. You can complete setup later.",
          );
        } catch (partnerError) {
          print("❌ Unexpected partner error: $partnerError");
          _showSnackBar(
            "Account created, but business setup encountered an error. You can complete setup later.",
          );
        }
      }

      // Step 5: Navigate to OTP page
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPPage(
              email: emailController.text,
              phone: "+1${phoneController.text.trim()}",
              isEmail: true,
            ),
          ),
        );
      }
    } catch (err) {
      print("❌ Unexpected error in signup: $err");
      _showSnackBar("An unexpected error occurred: ${err.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _validatePassword() {
    final password = passwordController.text;
    final checks = {
      'Length': password.length >= 6,
      'Letter': RegExp(r'[a-zA-Z]').hasMatch(password),
      'Capital': RegExp(r'[A-Z]').hasMatch(password),
      'Number': RegExp(r'[0-9]').hasMatch(password),
      'Special': RegExp(
        r'[!@#\$%\^\&\*\(\)\-\+\=_\.,;:{}\[\]]',
      ).hasMatch(password),
    };

    if (checks.values.every((v) => v)) return true;
    _showSnackBar("Password doesn't meet all requirements");
    return false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/prestige_logo.png', width: 90, height: 30),
              const SizedBox(height: 40),
              const Text("Create Account", style: AppStyles.title),
              const SizedBox(height: 8),
              const Text(
                "Join Prestige+ Rewards today",
                textAlign: TextAlign.center,
                style: AppStyles.description,
              ),
              const SizedBox(height: 40),

              // Full Name
              _buildTextField(
                controller: fullNameController,
                label: "Full Name",
                hint: "John Doe",
              ),
              const SizedBox(height: 20),

              // Email
              _buildTextField(
                controller: emailController,
                label: "Email",
                hint: "johandoe@gmail.com",
              ),
              const SizedBox(height: 20),

              // Phone
              _buildPhoneField(),
              const SizedBox(height: 20),

              // Password
              _buildPasswordField(),
              const SizedBox(height: 20),

              // Birthday
              _buildBirthdayPicker(width),
              const SizedBox(height: 25),

              // User Role Selector
              _buildRoleSelector(),
              const SizedBox(height: 25),

              // Partner Selector (only for Cashiers)
              _buildPartnerSelector(),
              if (userRole == "CASHIER" && selectedPartner != null)
                const SizedBox(height: 20),

              // Branch Selector (only for Cashiers)
              _buildBranchSelector(),
              if (userRole == "CASHIER" && selectedBranch != null)
                const SizedBox(height: 25),

              // Terms Checkbox
              const SizedBox(height: 15),
              _buildTermsCheckbox(),
              const SizedBox(height: 30),

              // Sign Up Button
              _buildSignUpButton(),
              const SizedBox(height: 5),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Already have an account? Sign In",
                    style: AppStyles.textButton,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          height: 43,
          decoration: AppStyles.input,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
              ).copyWith(bottom: 5),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppStyles.hintText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Phone Number", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          height: 43,
          decoration: AppStyles.input,
          child: Row(
            children: [
              const SizedBox(width: 15),
              const Text("🇺🇸", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                "+1",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 25, color: const Color(0x30000000)),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ).copyWith(bottom: 5),
                    border: InputBorder.none,
                    hintText: "983 728 1234",
                    hintStyle: AppStyles.hintText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final password = passwordController.text;
    final checks = [
      {'label': 'At least 6 characters', 'valid': password.length >= 6},
      {
        'label': 'Contains a letter',
        'valid': RegExp(r'[a-zA-Z]').hasMatch(password),
      },
      {
        'label': 'Contains a capital',
        'valid': RegExp(r'[A-Z]').hasMatch(password),
      },
      {
        'label': 'Contains a number',
        'valid': RegExp(r'[0-9]').hasMatch(password),
      },
      {
        'label': 'Contains special char',
        'valid': RegExp(
          r'[!@#\$%\^\&\*\(\)\-\+\=_\.,;:{}\[\]]',
        ).hasMatch(password),
      },
    ];
    final validCount = checks.where((c) => c['valid'] == true).length;
    final strength = validCount / checks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Password", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          height: 43,
          decoration: AppStyles.input,
          child: TextField(
            controller: passwordController,
            obscureText: !showPassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
              ).copyWith(top: 7),
              border: InputBorder.none,
              hintText: "•••••••••••",
              hintStyle: AppStyles.hintText,
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Modern password strength indicator
        if (password.isNotEmpty) ...[
          // Strength bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.grey[200],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: constraints.maxWidth * strength,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: strength < 0.4
                            ? [Colors.red, Colors.red.shade400]
                            : strength < 0.7
                            ? [Colors.orange, Colors.amber]
                            : [
                                const Color(0xFF00D4AA),
                                const Color(0xFF13B386),
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strength < 0.4
                    ? 'Weak'
                    : strength < 0.7
                    ? 'Medium'
                    : 'Strong',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strength < 0.4
                      ? Colors.red
                      : strength < 0.7
                      ? Colors.orange
                      : const Color(0xFF00D4AA),
                ),
              ),
              Text(
                '$validCount/${checks.length} requirements',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Compact check items
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: checks.map((c) {
              final isValid = c['valid'] as bool;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isValid
                      ? const Color(0xFF00D4AA).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isValid
                        ? const Color(0xFF00D4AA).withOpacity(0.3)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid ? Icons.check : Icons.close,
                      size: 12,
                      color: isValid
                          ? const Color(0xFF00D4AA)
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isValid
                            ? const Color(0xFF00D4AA)
                            : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBirthdayPicker(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Birthday", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: selectedYear,
                hint: "Year",
                items: List.generate(
                  (DateTime.now().year - 18) - 1900 + 1,
                  (i) => (DateTime.now().year - 18) - i,
                ),
                onChanged: (value) => setState(() {
                  selectedYear = value;
                  selectedDay = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                value: selectedMonth,
                hint: "Month",
                items: months,
                onChanged: (value) => setState(() {
                  selectedMonth = value;
                  selectedDay = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                value: selectedDay,
                hint: "Day",
                items: List.generate(
                  daysInMonth(selectedMonth, selectedYear),
                  (i) => i + 1,
                ),
                onChanged: (value) => setState(() => selectedDay = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppStyles.input,
      height: 43,
      child: DropdownButton<T>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint, style: AppStyles.hintText),
        dropdownColor: Colors.white,
        value: value,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(item.toString())),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Account Type", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildRoleButton("CASHIER", "Cashier")),
            const SizedBox(width: 12),
            Expanded(child: _buildRoleButton("OWNER", "Owner")),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role, String label) {
    final isSelected = userRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          userRole = role;
          if (role == "CASHIER") {
            selectedPartner = null;
            selectedBranch = null;
          } else {
            selectedPartner = null;
            selectedBranch = null;
          }
        });
        if (role == "OWNER") {
          _showBusinessSetupDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF13B386) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF13B386)
                : const Color(0x30000000),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerSelector() {
    if (userRole != "CASHIER") return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Partner Business", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AppStyles.input,
          height: 43,
          child: isLoadingPartners
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButton<NewPartner>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text("Choose a business", style: AppStyles.hintText),
                  dropdownColor: Colors.white,
                  value: selectedPartner,
                  items: availablePartners.map((partner) {
                    return DropdownMenuItem(
                      value: partner,
                      child: Row(
                        children: [
                          if (partner.logoUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                partner.logoUrl,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.business, size: 24),
                              ),
                            )
                          else
                            const Icon(Icons.business, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              partner.businessName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (NewPartner? partner) {
                    setState(() {
                      selectedPartner = partner;
                      selectedBranch = null;
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBranchSelector() {
    if (userRole != "CASHIER" || selectedPartner == null) {
      return const SizedBox.shrink();
    }

    final branches = selectedPartner!.branches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Branch Location", style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AppStyles.input,
          height: 43,
          child: branches.isEmpty
              ? const Center(
                  child: Text(
                    "No branches available",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : DropdownButton<PartnerBranch>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text("Choose a branch", style: AppStyles.hintText),
                  dropdownColor: Colors.white,
                  value: selectedBranch,
                  items: branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            branch.branchName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${branch.city}, ${branch.state}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (PartnerBranch? branch) {
                    setState(() => selectedBranch = branch);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: agreedToTerms,
            onChanged: (value) =>
                setState(() => agreedToTerms = value ?? false),
            activeColor: const Color(0xFF13B386),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => agreedToTerms = !agreedToTerms),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: "I accept the "),
                  TextSpan(
                    text: "Terms of Use, Privacy Policy & SMS Opt-in",
                    style: TextStyle(color: Color(0xFF007BFF)),
                  ),
                  TextSpan(
                    text:
                        ". After registration, I'll complete my business setup.",
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: isLoading ? null : _handleSignUp,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: AppStyles.button,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Continue", style: AppStyles.buttonContent),
        ),
      ),
    );
  }

  void _showBusinessSetupDialog() {
    if (userRole != "OWNER") return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BusinessSetupDialog(
        categories: categories,
        existingSetup: businessSetup,
        onComplete: (setup) {
          setState(() => businessSetup = setup);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    businessNameController.dispose();
    businessPhoneController.dispose();
    supportEmailController.dispose();
    websiteController.dispose();
    super.dispose();
  }
}

// ========================
// BUSINESS SETUP DIALOG
// ========================
class _BusinessSetupDialog extends StatefulWidget {
  final Map<String, dynamic> categories;
  final Map<String, dynamic>? existingSetup;
  final Function(Map<String, dynamic>) onComplete;

  const _BusinessSetupDialog({
    required this.categories,
    this.existingSetup,
    required this.onComplete,
  });

  @override
  State<_BusinessSetupDialog> createState() => _BusinessSetupDialogState();
}

class _BusinessSetupDialogState extends State<_BusinessSetupDialog> {
  int currentStep = 0; // 0 = info, 1 = address, 2 = branding, 3 = license

  // Controllers
  final businessNameController = TextEditingController();
  final businessPhoneController = TextEditingController();
  final supportEmailController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final licenseNumberController = TextEditingController();

  // Location values
  String? selectedState;
  String? selectedCity;

  // Dropdown values
  String? selectedBusinessType;
  String? selectedCategory;

  // Image files
  File? logoFile;
  File? bannerFile;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final setup = widget.existingSetup;
    if (setup != null) {
      businessNameController.text = setup['businessName'] ?? '';
      businessPhoneController.text = setup['businessPhone'] ?? '';
      supportEmailController.text = setup['supportEmail'] ?? '';
      websiteController.text = setup['website'] ?? '';
      addressController.text = setup['address'] ?? '';
      selectedCity = setup['city'];
      postalCodeController.text = setup['postalCode'] ?? '';
      licenseNumberController.text = setup['licenseNumber'] ?? '';
      selectedState = setup['state'];
      selectedBusinessType = setup['businessType'];
      selectedCategory = setup['category'];
      logoFile = setup['logoFile'];
      bannerFile = setup['bannerFile'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (currentStep) {
      case 0:
        return _buildBasicInfo();
      case 1:
        return _buildAddress();
      case 2:
        return _buildBranding();
      case 3:
        return _buildLicense();
      default:
        return Container();
    }
  }

  // -------------------------
  // STEP 1 — BUSINESS INFO
  // -------------------------
  Widget _buildBasicInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("Business Information", 1, 4),
        const SizedBox(height: 20),

        _buildText("Business Name", businessNameController, "Your Business"),
        const SizedBox(height: 16),

        _buildBusinessTypeDropdown(),
        const SizedBox(height: 16),

        _buildCategoryDropdown(),
        const SizedBox(height: 16),

        _buildText("Business Phone", businessPhoneController, "+1 555..."),
        const SizedBox(height: 16),

        _buildText("Support Email", supportEmailController, "support@mail.com"),
        const SizedBox(height: 16),

        _buildText("Website (Optional)", websiteController, "www.site.com"),
        const SizedBox(height: 25),

        _buildBottomButtons(onNext: _validateStep1),
      ],
    );
  }

  Widget _buildStepHeader(String title, int step, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppStyles.title),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF13B386).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Step $step of $total",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF13B386),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[200],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Container(
                  width: constraints.maxWidth * (step / total),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF13B386)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Type",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 43,
          decoration: AppStyles.input,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text("Select type", style: TextStyle(fontSize: 12)),
            value: selectedBusinessType,
            items: ['RESTAURANT', 'CAFE', 'RETAIL', 'SERVICE', 'OTHER']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => selectedBusinessType = value),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categoryList = widget.categories.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 43,
          decoration: AppStyles.input,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text("Select category", style: TextStyle(fontSize: 12)),
            value: selectedCategory,
            items: categoryList
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => selectedCategory = value),
          ),
        ),
      ],
    );
  }

  // -------------------------
  // STEP 2 — ADDRESS
  // -------------------------
  Widget _buildAddress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("Business Address", 2, 4),
        const SizedBox(height: 20),

        _buildText("Street Address", addressController, "123 Main Street"),
        const SizedBox(height: 16),

        // State dropdown
        const Text(
          "State",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        _buildSearchableStateDropdown(),
        const SizedBox(height: 16),

        // City dropdown (enabled after state selection)
        const Text(
          "City",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        _buildSearchableCityDropdown(),
        const SizedBox(height: 16),

        // Postal Code
        _buildText("Postal/Zip Code", postalCodeController, "10001"),

        const SizedBox(height: 25),
        _buildBottomButtons(
          onBack: () => setState(() => currentStep = 0),
          onNext: _validateStep2,
        ),
      ],
    );
  }

  Widget _buildSearchableStateDropdown() {
    return GestureDetector(
      onTap: () => _showStateSearchDialog(),
      child: Container(
        height: 43,
        decoration: AppStyles.input,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedState ?? "Select State",
                style: TextStyle(
                  fontSize: 14,
                  color: selectedState != null
                      ? Colors.black87
                      : Colors.grey[500],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showStateSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _StateSearchDialog(
        selectedState: selectedState,
        onSelected: (state) {
          setState(() {
            selectedState = state;
            selectedCity = null; // Reset city when state changes
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSearchableCityDropdown() {
    final cities = selectedState != null ? (usCities[selectedState] ?? []) : [];
    final isEnabled = selectedState != null && cities.isNotEmpty;

    return GestureDetector(
      onTap: isEnabled ? () => _showCitySearchDialog() : null,
      child: Container(
        height: 43,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                !isEnabled
                    ? "Select state first"
                    : (selectedCity ?? "Select City"),
                style: TextStyle(
                  fontSize: 14,
                  color: !isEnabled
                      ? Colors.grey[400]
                      : (selectedCity != null
                            ? Colors.black87
                            : Colors.grey[500]),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySearchDialog() {
    if (selectedState == null) return;
    final cities = usCities[selectedState] ?? [];
    if (cities.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _CitySearchDialog(
        cities: cities,
        selectedCity: selectedCity,
        stateName: selectedState!,
        onSelected: (city) {
          setState(() => selectedCity = city);
          Navigator.pop(context);
        },
      ),
    );
  }

  // -------------------------
  // STEP 3 — BRANDING
  // -------------------------
  Widget _buildBranding() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader("Branding", 3, 4),
          const SizedBox(height: 20),

          _buildImagePicker(
            "Business Logo",
            "Square image recommended",
            logoFile,
            (file) => setState(() => logoFile = file),
            isRequired: true,
          ),
          const SizedBox(height: 20),

          _buildImagePicker(
            "Business Banner",
            "Wide image (1200x400 recommended)",
            bannerFile,
            (file) => setState(() => bannerFile = file),
            isRequired: true,
          ),

          const SizedBox(height: 30),
          _buildBottomButtons(
            onBack: () => setState(() => currentStep = 1),
            onNext: _validateStep3,
          ),
        ],
      ),
    );
  }

  // -------------------------
  // STEP 4 — LICENSE/EIN
  // -------------------------
  Widget _buildLicense() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader("Business License", 4, 4),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Business Verification",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your EIN or Business Number helps us verify your business for payments and compliance.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildText(
          "EIN / Business Number",
          licenseNumberController,
          "XX-XXXXXXX",
        ),

        const SizedBox(height: 30),
        _buildBottomButtons(
          onBack: () => setState(() => currentStep = 2),
          onNext: _finishSetup,
          nextLabel: "Complete Setup",
        ),
      ],
    );
  }

  // -------------------------
  // HELPERS
  // -------------------------

  Widget _buildText(String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.inputTitle),
        const SizedBox(height: 6),
        Container(
          decoration: AppStyles.input,
          height: 43,
          child: TextField(
            controller: c,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(
    String label,
    String subtitle,
    File? file,
    Function(File) onPicked, {
    bool isRequired = false,
  }) {
    final hasImage = file != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppStyles.inputTitle),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final XFile? picked = await _imagePicker.pickImage(
              source: ImageSource.gallery,
            );
            if (picked != null) onPicked(File(picked.path));
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: hasImage ? null : const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage
                    ? const Color(0xFF00D4AA)
                    : Colors.grey.shade300,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: file == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons({
    void Function()? onBack,
    void Function()? onNext,
    String nextLabel = "Continue",
  }) {
    return Row(
      children: [
        if (onBack != null)
          Expanded(
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        if (onBack != null) const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF13B386),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                nextLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------
  // VALIDATIONS
  // -------------------------

  void _validateStep1() {
    if (businessNameController.text.isEmpty ||
        selectedBusinessType == null ||
        selectedCategory == null ||
        businessPhoneController.text.isEmpty ||
        supportEmailController.text.isEmpty) {
      _error("Please fill all required fields");
      return;
    }
    setState(() => currentStep = 1);
  }

  void _validateStep2() {
    if (addressController.text.isEmpty ||
        selectedState == null ||
        selectedCity == null ||
        postalCodeController.text.isEmpty) {
      _error(
        "Please fill all address fields including state, city, and postal code",
      );
      return;
    }
    setState(() => currentStep = 2);
  }

  void _validateStep3() {
    if (logoFile == null) {
      _error("Please upload a business logo");
      return;
    }
    if (bannerFile == null) {
      _error("Please upload a business banner");
      return;
    }
    setState(() => currentStep = 3);
  }

  void _finishSetup() {
    if (licenseNumberController.text.isEmpty) {
      _error("Please enter your EIN or Business Number");
      return;
    }

    widget.onComplete({
      "businessName": businessNameController.text.trim(),
      "businessType": selectedBusinessType,
      "category": selectedCategory,
      "businessPhone": businessPhoneController.text.trim(),
      "supportEmail": supportEmailController.text.trim(),
      "website": websiteController.text.trim(),
      "address": addressController.text.trim(),
      "country": "USA",
      "state": selectedState,
      "city": selectedCity,
      "postalCode": postalCodeController.text.trim(),
      "licenseNumber": licenseNumberController.text.trim(),
      "logoFile": logoFile,
      "bannerFile": bannerFile,
    });
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    businessNameController.dispose();
    businessPhoneController.dispose();
    supportEmailController.dispose();
    websiteController.dispose();
    addressController.dispose();

    postalCodeController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }
}

// ========================
// STATE SEARCH DIALOG
// ========================
class _StateSearchDialog extends StatefulWidget {
  final String? selectedState;
  final Function(String) onSelected;

  const _StateSearchDialog({this.selectedState, required this.onSelected});

  @override
  State<_StateSearchDialog> createState() => _StateSearchDialogState();
}

class _StateSearchDialogState extends State<_StateSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredStates = usStates;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStates);
  }

  void _filterStates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStates = usStates
          .where((state) => state.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF13B386).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select State",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search states...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // States list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredStates.length,
                itemBuilder: (context, index) {
                  final state = _filteredStates[index];
                  final isSelected = state == widget.selectedState;
                  return InkWell(
                    onTap: () => widget.onSelected(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF13B386).withOpacity(0.1)
                            : null,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              state,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF13B386)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF13B386),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CitySearchDialog extends StatefulWidget {
  final List<String> cities;
  final String? selectedCity;
  final String stateName;
  final Function(String) onSelected;

  const _CitySearchDialog({
    Key? key,
    required this.cities,
    required this.selectedCity,
    required this.stateName,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  late TextEditingController _searchController;
  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    filteredCities = widget.cities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCities = widget.cities;
      } else {
        filteredCities = widget.cities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select City in ${widget.stateName}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterCities,
            ),
            SizedBox(height: 16),

            // City Count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filteredCities.length} cities',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            SizedBox(height: 8),

            // Cities List
            Expanded(
              child: filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        'No cities found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final isSelected = city == widget.selectedCity;

                        return ListTile(
                          title: Text(city),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => widget.onSelected(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// US Cities by State Data
class USCitiesData {
  static final Map<String, List<String>> citiesByState = {
    'Alabama': [
      'Birmingham',
      'Montgomery',
      'Mobile',
      'Huntsville',
      'Tuscaloosa',
      'Hoover',
      'Dothan',
      'Auburn',
      'Decatur',
      'Madison',
      'Florence',
      'Gadsden',
      'Vestavia Hills',
      'Prattville',
      'Phenix City',
    ],
    'Alaska': [
      'Anchorage',
      'Fairbanks',
      'Juneau',
      'Sitka',
      'Ketchikan',
      'Wasilla',
      'Kenai',
      'Kodiak',
      'Bethel',
      'Palmer',
      'Homer',
      'Unalaska',
      'Soldotna',
      'Barrow',
      'Nome',
    ],
    'Arizona': [
      'Phoenix',
      'Tucson',
      'Mesa',
      'Chandler',
      'Scottsdale',
      'Glendale',
      'Gilbert',
      'Tempe',
      'Peoria',
      'Surprise',
      'Yuma',
      'Avondale',
      'Goodyear',
      'Flagstaff',
      'Buckeye',
      'Lake Havasu City',
      'Casa Grande',
    ],
    'Arkansas': [
      'Little Rock',
      'Fort Smith',
      'Fayetteville',
      'Springdale',
      'Jonesboro',
      'North Little Rock',
      'Conway',
      'Rogers',
      'Pine Bluff',
      'Bentonville',
      'Hot Springs',
      'Benton',
      'Texarkana',
      'Sherwood',
      'Jacksonville',
    ],
    'California': [
      'Los Angeles',
      'San Diego',
      'San Jose',
      'San Francisco',
      'Fresno',
      'Sacramento',
      'Long Beach',
      'Oakland',
      'Bakersfield',
      'Anaheim',
      'Santa Ana',
      'Riverside',
      'Stockton',
      'Irvine',
      'Chula Vista',
      'Fremont',
      'San Bernardino',
      'Modesto',
      'Fontana',
      'Oxnard',
      'Moreno Valley',
      'Huntington Beach',
      'Glendale',
      'Santa Clarita',
      'Garden Grove',
      'Oceanside',
      'Rancho Cucamonga',
      'Santa Rosa',
      'Ontario',
      'Lancaster',
      'Elk Grove',
      'Corona',
      'Palmdale',
      'Salinas',
    ],
    'Colorado': [
      'Denver',
      'Colorado Springs',
      'Aurora',
      'Fort Collins',
      'Lakewood',
      'Thornton',
      'Arvada',
      'Westminster',
      'Pueblo',
      'Centennial',
      'Boulder',
      'Greeley',
      'Longmont',
      'Loveland',
      'Grand Junction',
    ],
    'Connecticut': [
      'Bridgeport',
      'New Haven',
      'Stamford',
      'Hartford',
      'Waterbury',
      'Norwalk',
      'Danbury',
      'New Britain',
      'Bristol',
      'Meriden',
      'Milford',
      'West Haven',
      'Middletown',
      'Norwich',
      'Shelton',
    ],
    'Delaware': [
      'Wilmington',
      'Dover',
      'Newark',
      'Middletown',
      'Smyrna',
      'Milford',
      'Seaford',
      'Georgetown',
      'Elsmere',
      'New Castle',
    ],
    'Florida': [
      'Jacksonville',
      'Miami',
      'Tampa',
      'Orlando',
      'St. Petersburg',
      'Hialeah',
      'Tallahassee',
      'Fort Lauderdale',
      'Port St. Lucie',
      'Cape Coral',
      'Pembroke Pines',
      'Hollywood',
      'Miramar',
      'Coral Springs',
      'Clearwater',
      'Miami Gardens',
      'Palm Bay',
      'West Palm Beach',
      'Pompano Beach',
      'Lakeland',
      'Davie',
      'Miami Beach',
      'Sunrise',
      'Plantation',
      'Boca Raton',
    ],
    'Georgia': [
      'Atlanta',
      'Augusta',
      'Columbus',
      'Macon',
      'Savannah',
      'Athens',
      'Sandy Springs',
      'Roswell',
      'Johns Creek',
      'Albany',
      'Warner Robins',
      'Alpharetta',
      'Marietta',
      'Valdosta',
      'Smyrna',
      'Dunwoody',
    ],
    'Hawaii': [
      'Honolulu',
      'Pearl City',
      'Hilo',
      'Kailua',
      'Waipahu',
      'Kaneohe',
      'Mililani Town',
      'Kahului',
      'Ewa Gentry',
      'Mililani Mauka',
    ],
    'Idaho': [
      'Boise',
      'Meridian',
      'Nampa',
      'Idaho Falls',
      'Pocatello',
      'Caldwell',
      'Coeur d\'Alene',
      'Twin Falls',
      'Lewiston',
      'Post Falls',
    ],
    'Illinois': [
      'Chicago',
      'Aurora',
      'Naperville',
      'Joliet',
      'Rockford',
      'Springfield',
      'Elgin',
      'Peoria',
      'Champaign',
      'Waukegan',
      'Cicero',
      'Bloomington',
      'Arlington Heights',
      'Evanston',
      'Decatur',
      'Schaumburg',
      'Bolingbrook',
    ],
    'Indiana': [
      'Indianapolis',
      'Fort Wayne',
      'Evansville',
      'South Bend',
      'Carmel',
      'Fishers',
      'Bloomington',
      'Hammond',
      'Gary',
      'Muncie',
      'Lafayette',
      'Terre Haute',
      'Kokomo',
      'Anderson',
      'Noblesville',
      'Greenwood',
    ],
    'Iowa': [
      'Des Moines',
      'Cedar Rapids',
      'Davenport',
      'Sioux City',
      'Iowa City',
      'Waterloo',
      'Council Bluffs',
      'Ames',
      'West Des Moines',
      'Dubuque',
      'Ankeny',
      'Urbandale',
      'Cedar Falls',
      'Marion',
      'Bettendorf',
    ],
    'Kansas': [
      'Wichita',
      'Overland Park',
      'Kansas City',
      'Topeka',
      'Olathe',
      'Lawrence',
      'Shawnee',
      'Manhattan',
      'Lenexa',
      'Salina',
      'Hutchinson',
    ],
    'Kentucky': [
      'Louisville',
      'Lexington',
      'Bowling Green',
      'Owensboro',
      'Covington',
      'Hopkinsville',
      'Richmond',
      'Florence',
      'Georgetown',
      'Elizabethtown',
    ],
    'Louisiana': [
      'New Orleans',
      'Baton Rouge',
      'Shreveport',
      'Lafayette',
      'Lake Charles',
      'Kenner',
      'Bossier City',
      'Monroe',
      'Alexandria',
      'Houma',
    ],
    'Maine': [
      'Portland',
      'Lewiston',
      'Bangor',
      'South Portland',
      'Auburn',
      'Biddeford',
      'Sanford',
      'Saco',
      'Westbrook',
      'Augusta',
    ],
    'Maryland': [
      'Baltimore',
      'Frederick',
      'Rockville',
      'Gaithersburg',
      'Bowie',
      'Hagerstown',
      'Annapolis',
      'College Park',
      'Salisbury',
      'Laurel',
    ],
    'Massachusetts': [
      'Boston',
      'Worcester',
      'Springfield',
      'Cambridge',
      'Lowell',
      'Brockton',
      'Quincy',
      'Lynn',
      'New Bedford',
      'Fall River',
      'Newton',
      'Lawrence',
      'Somerville',
      'Waltham',
      'Haverhill',
    ],
    'Michigan': [
      'Detroit',
      'Grand Rapids',
      'Warren',
      'Sterling Heights',
      'Ann Arbor',
      'Lansing',
      'Flint',
      'Dearborn',
      'Livonia',
      'Troy',
      'Westland',
      'Farmington Hills',
      'Kalamazoo',
      'Wyoming',
      'Southfield',
      'Rochester Hills',
    ],
    'Minnesota': [
      'Minneapolis',
      'St. Paul',
      'Rochester',
      'Duluth',
      'Bloomington',
      'Brooklyn Park',
      'Plymouth',
      'St. Cloud',
      'Eagan',
      'Woodbury',
      'Maple Grove',
      'Eden Prairie',
      'Coon Rapids',
      'Burnsville',
      'Blaine',
    ],
    'Mississippi': [
      'Jackson',
      'Gulfport',
      'Southaven',
      'Hattiesburg',
      'Biloxi',
      'Meridian',
      'Tupelo',
      'Greenville',
      'Olive Branch',
      'Horn Lake',
    ],
    'Missouri': [
      'Kansas City',
      'St. Louis',
      'Springfield',
      'Columbia',
      'Independence',
      'Lee\'s Summit',
      'O\'Fallon',
      'St. Joseph',
      'St. Charles',
      'St. Peters',
      'Blue Springs',
      'Florissant',
      'Joplin',
      'Chesterfield',
      'Jefferson City',
    ],
    'Montana': [
      'Billings',
      'Missoula',
      'Great Falls',
      'Bozeman',
      'Butte',
      'Helena',
      'Kalispell',
      'Havre',
      'Anaconda',
      'Miles City',
    ],
    'Nebraska': [
      'Omaha',
      'Lincoln',
      'Bellevue',
      'Grand Island',
      'Kearney',
      'Fremont',
      'Hastings',
      'Norfolk',
      'Columbus',
      'Papillion',
    ],
    'Nevada': [
      'Las Vegas',
      'Henderson',
      'Reno',
      'North Las Vegas',
      'Sparks',
      'Carson City',
      'Fernley',
      'Elko',
      'Mesquite',
      'Boulder City',
    ],
    'New Hampshire': [
      'Manchester',
      'Nashua',
      'Concord',
      'Derry',
      'Rochester',
      'Salem',
      'Dover',
      'Merrimack',
      'Londonderry',
      'Hudson',
    ],
    'New Jersey': [
      'Newark',
      'Jersey City',
      'Paterson',
      'Elizabeth',
      'Edison',
      'Woodbridge',
      'Lakewood',
      'Toms River',
      'Hamilton',
      'Trenton',
      'Clifton',
      'Camden',
      'Brick',
      'Cherry Hill',
      'Passaic',
    ],
    'New Mexico': [
      'Albuquerque',
      'Las Cruces',
      'Rio Rancho',
      'Santa Fe',
      'Roswell',
      'Farmington',
      'Clovis',
      'Hobbs',
      'Alamogordo',
      'Carlsbad',
    ],
    'New York': [
      'New York City',
      'Buffalo',
      'Rochester',
      'Yonkers',
      'Syracuse',
      'Albany',
      'New Rochelle',
      'Mount Vernon',
      'Schenectady',
      'Utica',
      'White Plains',
      'Hempstead',
      'Troy',
      'Niagara Falls',
      'Binghamton',
    ],
    'North Carolina': [
      'Charlotte',
      'Raleigh',
      'Greensboro',
      'Durham',
      'Winston-Salem',
      'Fayetteville',
      'Cary',
      'Wilmington',
      'High Point',
      'Greenville',
      'Asheville',
      'Concord',
      'Gastonia',
      'Jacksonville',
      'Chapel Hill',
    ],
    'North Dakota': [
      'Fargo',
      'Bismarck',
      'Grand Forks',
      'Minot',
      'West Fargo',
      'Williston',
      'Dickinson',
      'Mandan',
      'Jamestown',
      'Wahpeton',
    ],
    'Ohio': [
      'Columbus',
      'Cleveland',
      'Cincinnati',
      'Toledo',
      'Akron',
      'Dayton',
      'Parma',
      'Canton',
      'Youngstown',
      'Lorain',
      'Hamilton',
      'Springfield',
      'Kettering',
      'Elyria',
      'Lakewood',
      'Cuyahoga Falls',
      'Middletown',
    ],
    'Oklahoma': [
      'Oklahoma City',
      'Tulsa',
      'Norman',
      'Broken Arrow',
      'Edmond',
      'Lawton',
      'Moore',
      'Midwest City',
      'Enid',
      'Stillwater',
    ],
    'Oregon': [
      'Portland',
      'Salem',
      'Eugene',
      'Gresham',
      'Hillsboro',
      'Beaverton',
      'Bend',
      'Medford',
      'Springfield',
      'Corvallis',
      'Albany',
      'Tigard',
    ],
    'Pennsylvania': [
      'Philadelphia',
      'Pittsburgh',
      'Allentown',
      'Erie',
      'Reading',
      'Scranton',
      'Bethlehem',
      'Lancaster',
      'Harrisburg',
      'Altoona',
      'York',
      'State College',
      'Wilkes-Barre',
      'Chester',
      'Norristown',
    ],
    'Rhode Island': [
      'Providence',
      'Warwick',
      'Cranston',
      'Pawtucket',
      'East Providence',
      'Woonsocket',
      'Coventry',
      'Cumberland',
      'North Providence',
      'South Kingstown',
    ],
    'South Carolina': [
      'Columbia',
      'Charleston',
      'North Charleston',
      'Mount Pleasant',
      'Rock Hill',
      'Greenville',
      'Summerville',
      'Sumter',
      'Goose Creek',
      'Hilton Head Island',
    ],
    'South Dakota': [
      'Sioux Falls',
      'Rapid City',
      'Aberdeen',
      'Brookings',
      'Watertown',
      'Mitchell',
      'Yankton',
      'Pierre',
      'Huron',
      'Vermillion',
    ],
    'Tennessee': [
      'Nashville',
      'Memphis',
      'Knoxville',
      'Chattanooga',
      'Clarksville',
      'Murfreesboro',
      'Franklin',
      'Jackson',
      'Johnson City',
      'Bartlett',
      'Hendersonville',
      'Kingsport',
      'Collierville',
      'Smyrna',
      'Cleveland',
    ],
    'Texas': [
      'Houston',
      'San Antonio',
      'Dallas',
      'Austin',
      'Fort Worth',
      'El Paso',
      'Arlington',
      'Corpus Christi',
      'Plano',
      'Laredo',
      'Lubbock',
      'Garland',
      'Irving',
      'Amarillo',
      'Grand Prairie',
      'Brownsville',
      'Pasadena',
      'McKinney',
      'Mesquite',
      'McAllen',
      'Killeen',
      'Frisco',
      'Waco',
      'Carrollton',
    ],
    'Utah': [
      'Salt Lake City',
      'West Valley City',
      'Provo',
      'West Jordan',
      'Orem',
      'Sandy',
      'Ogden',
      'St. George',
      'Layton',
      'Taylorsville',
      'South Jordan',
    ],
    'Vermont': [
      'Burlington',
      'South Burlington',
      'Rutland',
      'Barre',
      'Montpelier',
      'Winooski',
      'St. Albans',
      'Newport',
      'Vergennes',
      'Essex Junction',
    ],
    'Virginia': [
      'Virginia Beach',
      'Norfolk',
      'Chesapeake',
      'Richmond',
      'Newport News',
      'Alexandria',
      'Hampton',
      'Roanoke',
      'Portsmouth',
      'Suffolk',
      'Lynchburg',
      'Harrisonburg',
      'Leesburg',
      'Charlottesville',
      'Blacksburg',
    ],
    'Washington': [
      'Seattle',
      'Spokane',
      'Tacoma',
      'Vancouver',
      'Bellevue',
      'Kent',
      'Everett',
      'Renton',
      'Yakima',
      'Federal Way',
      'Spokane Valley',
      'Bellingham',
      'Kennewick',
      'Auburn',
      'Pasco',
      'Marysville',
    ],
    'West Virginia': [
      'Charleston',
      'Huntington',
      'Morgantown',
      'Parkersburg',
      'Wheeling',
      'Weirton',
      'Fairmont',
      'Martinsburg',
      'Beckley',
      'Clarksburg',
    ],
    'Wisconsin': [
      'Milwaukee',
      'Madison',
      'Green Bay',
      'Kenosha',
      'Racine',
      'Appleton',
      'Waukesha',
      'Eau Claire',
      'Oshkosh',
      'Janesville',
      'West Allis',
      'La Crosse',
      'Sheboygan',
      'Wauwatosa',
      'Fond du Lac',
    ],
    'Wyoming': [
      'Cheyenne',
      'Casper',
      'Laramie',
      'Gillette',
      'Rock Springs',
      'Sheridan',
      'Green River',
      'Evanston',
      'Riverton',
      'Jackson',
    ],
  };

  static List<String> getCitiesForState(String state) {
    return citiesByState[state] ?? [];
  }
}
