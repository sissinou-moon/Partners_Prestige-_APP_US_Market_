import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app/lib/supabase.dart';
import '../../app/providers/partner_provider.dart';


class BusinessProfilePage extends ConsumerStatefulWidget {
  final Partner partner;

  const BusinessProfilePage({
    Key? key,
    required this.partner,
  }) : super(key: key);

  @override
  ConsumerState<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends ConsumerState<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  String? _selectedBusinessType;
  String? _selectedCategory;
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;

  final List<String> _businessTypes = [
    'RESTAURANT',
    'CAFE',
    'RETAIL',
    'SERVICE',
    'ENTERTAINMENT',
    'HEALTH',
    'EDUCATION',
    'HOTEL',
    'GYM',
    'SALON',
    'OTHER',
  ];

  final List<String> _categories = [
    'Restaurants & Cafes',
    'Fashion & Apparel',
    'Beauty & Spa',
    'Electronics',
    'Grocery & Supermarket',
    'Health & Fitness',
    'Entertainment',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _businessNameController.text = widget.partner.businessName;
    _emailController.text = widget.partner.email;
    _phoneController.text = widget.partner.phone;
    _websiteController.text = widget.partner.website ?? '';
    _addressController.text = widget.partner.address ?? '';
    _cityController.text = widget.partner.city ?? '';
    _stateController.text = widget.partner.state ?? '';
    _countryController.text = widget.partner.country;

    // Safely set business type - only if it exists in the list
    if (widget.partner.businessType != null &&
        _businessTypes.contains(widget.partner.businessType)) {
      _selectedBusinessType = widget.partner.businessType;
    } else if (widget.partner.businessType != null) {
      // If business type exists but not in list, add it
      _businessTypes.add(widget.partner.businessType!);
      _selectedBusinessType = widget.partner.businessType;
    }

    // Safely set category - only if it exists in the list
    if (widget.partner.category != null &&
        _categories.contains(widget.partner.category)) {
      _selectedCategory = widget.partner.category;
    } else if (widget.partner.category != null) {
      // If category exists but not in list, add it
      _categories.add(widget.partner.category!);
      _selectedCategory = widget.partner.category;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isLogo ? 500 : 1200,
      maxHeight: isLogo ? 500 : 400,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(pickedFile.path);
        } else {
          _bannerFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();

      // Upload images if selected
      String? logoUrl = widget.partner.logoUrl;
      String? bannerUrl = widget.partner.bannerUrl;

      // Update partner data
      final updates = {
        'business_name': _businessNameController.text,
        'business_type': _selectedBusinessType,
        'category': _selectedCategory,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'website': _websiteController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
      };

      final newPartner = await PartnerService.updatePartner(partnerId: widget.partner.id, updates: updates);

      // Refresh partner provider
      ref.invalidate(partnerProvider);
      ref.read(partnerProvider.notifier).state = newPartner.toJson();

      if (_logoFile != null) {
        final logoUrl = await PartnerService.uploadLogo(
          partnerId: widget.partner.id,
          imageFile: _logoFile!,
        );

        if (context.mounted) {
          // Update only the logo_url field
          ref.read(partnerProvider.notifier).update((partner) {
            if (partner == null) return partner;

            return {
              ...partner,                 // keep all existing fields
              "logo_url": logoUrl,        // update the field we want
            };
          });
        }
      }

      if (_bannerFile != null) {
         bannerUrl = await PartnerService.uploadBanner(
           partnerId: widget.partner.id,
           imageFile: _bannerFile!,
         );

         if (context.mounted) {
           // Update only the logo_url field
           ref.read(partnerProvider.notifier).update((partner) {
             if (partner == null) return partner;

             return {
               ...partner,                 // keep all existing fields
               "banner_url": logoUrl,        // update the field we want
             };
           });
         }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Business Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00D4AA),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              buildBannerAndLogoSection(
                bannerFile: _bannerFile,
                bannerUrl: widget.partner.bannerUrl,
                logoFile: _logoFile,
                logoUrl: widget.partner.logoUrl,
                onBannerTap: () => _pickImage(false),
                onLogoTap: () => _pickImage(true),
              ),

              // Basic Information
              _buildSection(
                title: 'Basic Information',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      icon: LineIcons.store,
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Business Type',
                      icon: LineIcons.briefcase,
                      value: _selectedBusinessType,
                      items: _businessTypes,
                      onChanged: (value) =>
                          setState(() => _selectedBusinessType = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Category',
                      icon: LineIcons.tag,
                      value: _selectedCategory,
                      items: _categories,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contact Information
              _buildSection(
                title: 'Contact Information',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: LineIcons.envelope,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (!value!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: LineIcons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      icon: LineIcons.globe,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Address Information
              _buildSection(
                title: 'Address Information',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: LineIcons.mapMarker,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: LineIcons.building,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _stateController,
                      label: 'State/Province',
                      icon: LineIcons.map,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: LineIcons.flag,
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4AA), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBannerAndLogoSection({
    required File? bannerFile,
    required String? bannerUrl,
    required File? logoFile,
    required String? logoUrl,
    required VoidCallback onBannerTap,
    required VoidCallback onLogoTap,
  }) {
    return Container(
      height: 230,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ------------------ BANNER ------------------
          GestureDetector(
            onTap: onBannerTap,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerFile != null)
                    Image.file(bannerFile, fit: BoxFit.cover)
                  else if (bannerUrl != null)
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildBannerFallback(),
                    )
                  else
                    _buildBannerFallback(),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: _smallEditButton(),
                  ),
                ],
              ),
            ),
          ),

          // ------------------ LOGO (OVER BANNER) ------------------
          Positioned(
            bottom: 10,
            left: 20,
            child: GestureDetector(
              onTap: onLogoTap,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (logoFile != null)
                      Image.file(logoFile, fit: BoxFit.cover)
                    else if (logoUrl != null)
                      Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildLogoFallback(),
                      )
                    else
                      _buildLogoFallback(),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: _smallEditButton(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBannerFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.photoVideo, size: 46, color: Colors.grey.shade600),
          const SizedBox(height: 6),
          Text("Upload Banner",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(LineIcons.image, size: 40, color: Colors.grey.shade600),
    );
  }

  Widget _smallEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Icon(LineIcons.edit, size: 14, color: Colors.black),
          SizedBox(width: 3),
          Text(
            "Edit",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }


  Widget _buildImagePicker({
    required bool isLogo,
    String? imageUrl,
    File? selectedFile,
  }) {
    return GestureDetector(
      onTap: () => _pickImage(isLogo),
      child: Container(
        height: isLogo ? 150 : 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: selectedFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedFile,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        )
            : imageUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(isLogo);
            },
          ),
        )
            : _buildPlaceholder(isLogo),
      ),
    );
  }

  Widget _buildPlaceholder(bool isLogo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLogo ? LineIcons.image : LineIcons.photoVideo,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload ${isLogo ? 'logo' : 'banner'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLogo ? 'Recommended: 500x500px' : 'Recommended: 1200x400px',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}