import 'package:flutter/material.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../app/lib/supabase.dart';
import '../../styles/styles.dart';
import 'OTPPage.dart';

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
  bool isEmailSignup = false; // Always phone for new flow

  int? selectedYear;
  String? selectedMonth;
  int? selectedDay;

  String? userRole; // 'CASHIER' or 'OWNER'
  Map<String, dynamic>? businessSetup; // Temporary storage

  String? selectedBusinessType;
  String? selectedBusinessCategory;
  String? selectedPOS; // 'SQUARE' or 'CLOVER'

  Map<String, dynamic> categories = {};

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/categories.json');
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
            country: "USA",
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
              // Continue even if logo upload fails
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
              // Continue even if banner upload fails
            }
          }

          _showSnackBar("Account and business created successfully!");
        } on PartnerException catch (partnerError) {
          // Partner creation failed, but user was created
          print("❌ Partner creation failed: ${partnerError.message}");
          _showSnackBar(
            "Account created, but business setup failed: ${partnerError.message}. You can complete setup later.",
          );
          // Don't return here - still proceed to OTP
        } catch (partnerError) {
          print("❌ Unexpected partner error: $partnerError");
          _showSnackBar(
            "Account created, but business setup encountered an error. You can complete setup later."
          );
          // Don't return here - still proceed to OTP
        }
      }

      // Step 5: Navigate to OTP page
      if (mounted) {
        // Small delay to ensure snackbar is visible
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPPage(
              email: phoneController.text,
              phone: "+1${phoneController.text.trim()}",
              isEmail: false,
            ),
          ),
        );
      }
    } catch (err) {
      print("❌ Unexpected error in signup: $err");
      _showSnackBar(
        "An unexpected error occurred: ${err.toString()}"
      );
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
      'Special': RegExp(r'[!@#\$%\^&\*\(\)\-\+\=_\.,;:{}\[\]]').hasMatch(password),
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

              // Phone (No toggle, always phone)
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

              // Single Checkbox for Terms
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 5),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 25, color: const Color(0x30000000)),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 5),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 15).copyWith(top: 7),
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
        const SizedBox(height: 10),
        _buildCheckItem("At least 6 characters", passwordController.text.length >= 6),
        _buildCheckItem("Contains a letter", RegExp(r'[a-zA-Z]').hasMatch(passwordController.text)),
        _buildCheckItem("Contains a capital letter", RegExp(r'[A-Z]').hasMatch(passwordController.text)),
        _buildCheckItem("Contains a number", RegExp(r'[0-9]').hasMatch(passwordController.text)),
        _buildCheckItem("Contains a special character", RegExp(r'[!@#\$%\^&\*\(\)\-\+\=_\.,;:{}\[\]]').hasMatch(passwordController.text)),
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
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
            Expanded(
              child: _buildRoleButton("CASHIER", "Cashier"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleButton("OWNER", "Owner"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role, String label) {
    final isSelected = userRole == role;
    return GestureDetector(
      onTap: () {
        setState(() => userRole = role);
        if (role == "OWNER") {
          _showBusinessSetupDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004F54) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF004F54) : const Color(0x30000000),
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: agreedToTerms,
            onChanged: (value) => setState(() => agreedToTerms = value ?? false),
            activeColor: const Color(0xFF004F54),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => agreedToTerms = !agreedToTerms),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(text: "I accept the "),
                  TextSpan(
                    text: "Terms of Use, Privacy Policy & SMS Opt-in",
                    style: TextStyle(color: Color(0xFF007BFF)),
                  ),
                  TextSpan(text: ". After registration, I'll complete my business setup."),
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
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
        onComplete: (setup) {
          setState(() => businessSetup = setup);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 17,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isValid ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
  final Function(Map<String, dynamic>) onComplete;

  const _BusinessSetupDialog({
    required this.categories,
    required this.onComplete,
  });

  @override
  State<_BusinessSetupDialog> createState() => _BusinessSetupDialogState();
}

class _BusinessSetupDialogState extends State<_BusinessSetupDialog> {
  int currentStep = 0; // 0 = info, 1 = address, 2 = branding

  // Controllers
  final businessNameController = TextEditingController();
  final businessPhoneController = TextEditingController();
  final supportEmailController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  // Dropdown values
  String? selectedBusinessType;
  String? selectedCategory;

  // Image files
  File? logoFile;
  File? bannerFile;

  final ImagePicker _imagePicker = ImagePicker();

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
        Text("Business Information", style: AppStyles.title),
        const SizedBox(height: 6),
        Text("Step 1 of 3", style: TextStyle(color: Colors.grey[600])),
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

        _buildBottomButtons(
          onNext: _validateStep1,
        ),
      ],
    );
  }

  Widget _buildBusinessTypeDropdown() { return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text( "Business Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), ), const SizedBox(height: 6), Container( height: 40, decoration: AppStyles.input, padding: const EdgeInsets.symmetric(horizontal: 12), child: DropdownButton<String>( isExpanded: true, underline: const SizedBox(), hint: const Text("Select type", style: TextStyle(fontSize: 12)), value: selectedBusinessType, items: ['RESTAURANT', 'CAFE', 'RETAIL', 'SERVICE', 'OTHER'] .map((type) => DropdownMenuItem(value: type, child: Text(type))) .toList(), onChanged: (value) => setState(() => selectedBusinessType = value), ), ), ], ); } Widget _buildCategoryDropdown() { final categoryList = widget.categories.keys.toList(); return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text( "Category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), ), const SizedBox(height: 6), Container( height: 40, decoration: AppStyles.input, padding: const EdgeInsets.symmetric(horizontal: 12), child: DropdownButton<String>( isExpanded: true, underline: const SizedBox(), hint: const Text("Select category", style: TextStyle(fontSize: 12)), value: selectedCategory, items: categoryList .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis))) .toList(), onChanged: (value) => setState(() => selectedCategory = value), ), ), ], ); }

  // -------------------------
  // STEP 2 — ADDRESS
  // -------------------------
  Widget _buildAddress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Business Address", style: AppStyles.title),
        const SizedBox(height: 6),
        Text("Step 2 of 3", style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),

        _buildText("Address", addressController, "123 Main Street"),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _buildText("City", cityController, "New York")),
            const SizedBox(width: 12),
            Expanded(child: _buildText("State", stateController, "NY")),
          ],
        ),

        const SizedBox(height: 25),
        _buildBottomButtons(
          onBack: () => setState(() => currentStep = 0),
          onNext: _validateStep2,
        ),
      ],
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
          Text("Branding", style: AppStyles.title),
          const SizedBox(height: 6),
          Text("Step 3 of 3", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),

          _buildImagePicker("Business Logo", logoFile, (file) {
            setState(() => logoFile = file);
          }),
          const SizedBox(height: 20),

          _buildImagePicker("Business Banner", bannerFile, (file) {
            setState(() => bannerFile = file);
          }),

          const SizedBox(height: 30),
          _buildBottomButtons(
            onBack: () => setState(() => currentStep = 1),
            onNext: _finishSetup,
          ),
        ],
      ),
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

  Widget _buildImagePicker(String label, File? file, Function(File) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.inputTitle),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final XFile? picked =
            await _imagePicker.pickImage(source: ImageSource.gallery);
            if (picked != null) onPicked(File(picked.path));
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: file == null
                ? Center(child: Text("Tap to upload"))
                : Image.file(file, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons({
    void Function()? onBack,
    void Function()? onNext,
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
                child: const Text("Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                color: const Color(0xFF004F54),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
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
      _error("Fill all fields");
      return;
    }
    setState(() => currentStep = 1);
  }

  void _validateStep2() {
    if (addressController.text.isEmpty ||
        cityController.text.isEmpty ||
        stateController.text.isEmpty) {
      _error("Fill address info");
      return;
    }
    setState(() => currentStep = 2);
  }

  void _finishSetup() {
    widget.onComplete({
      "businessName": businessNameController.text.trim(),
      "businessType": selectedBusinessType,
      "category": selectedCategory,
      "businessPhone": businessPhoneController.text.trim(),
      "supportEmail": supportEmailController.text.trim(),
      "website": websiteController.text.trim(),
      "address": addressController.text.trim(),
      "city": cityController.text.trim(),
      "state": stateController.text.trim(),
      "logoFile": logoFile,
      "bannerFile": bannerFile,
    });
    //Navigator.pop(context);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
