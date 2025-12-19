import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/lib/supabase.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/storage/local_storage.dart';

class BusinessProfilePage extends ConsumerStatefulWidget {
  final Partner partner;

  const BusinessProfilePage({Key? key, required this.partner})
    : super(key: key);

  @override
  ConsumerState<BusinessProfilePage> createState() =>
      _BusinessProfilePageState();
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

  String? _selectedBranchId;
  Branch? _selectedBranch;
  bool _branchDataChanged = false;

  // Branch controllers
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _branchCityController = TextEditingController();
  final _branchStateController = TextEditingController();
  final _branchPhoneController = TextEditingController();
  final _branchEmailController = TextEditingController();
  final _branchManagerController = TextEditingController();

  bool _is24Hours = false;
  Map<String, Map<String, String>> _regularHours = {};
  String _selectedTimezone = 'America/Los_Angeles';

  // Branch location coordinates
  double? _branchLatitude;
  double? _branchLongitude;

  List<String> _businessTypes = [];
  List<String> _categories = [];

  // Keep partner's existing values so we can re-apply after loading JSON.
  String? _initialBusinessType;
  String? _initialCategory;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadCategoriesFromAsset();
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

    // Capture initial selections; actual lists load from JSON.
    _initialBusinessType = widget.partner.businessType;
    _initialCategory = widget.partner.category;
    _selectedBusinessType = _initialBusinessType;
    _selectedCategory = _initialCategory;
  }

  Future<void> _loadCategoriesFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/categories.json');
      final Map<String, dynamic> data = jsonDecode(raw);
      // Only expose the requested keys
      const allowed = [
        'Restaurants & Cafes',
        'Wellness',
        'Beauty & Personal Care',
        'Retail',
      ];
      final keys = allowed.where((k) => data.containsKey(k)).toList();

      setState(() {
        _categories = keys;
        _businessTypes = List<String>.from(keys);

        if (_initialBusinessType != null) {
          if (_businessTypes.contains(_initialBusinessType)) {
            _selectedBusinessType = _initialBusinessType;
          } else {
            _businessTypes.add(_initialBusinessType!);
            _selectedBusinessType = _initialBusinessType;
          }
        }

        if (_initialCategory != null) {
          if (_categories.contains(_initialCategory)) {
            _selectedCategory = _initialCategory;
          } else {
            _categories.add(_initialCategory!);
            _selectedCategory = _initialCategory;
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to load categories.json: $e');
    }
  }

  void _populateBranchFields(Branch branch) {
    _selectedBranch = branch;
    _branchNameController.text = branch.branchName;
    _branchAddressController.text = branch.address ?? '';
    _branchCityController.text = branch.city ?? '';
    _branchStateController.text = branch.state ?? '';
    _branchPhoneController.text = branch.phone ?? '';
    _branchEmailController.text = branch.email ?? '';
    _branchManagerController.text = branch.managerName ?? '';
    _branchLatitude = branch.latitude;
    _branchLongitude = branch.longitude;

    // 🆕 Parse operating hours
    if (branch.operatingHours != null) {
      final opHours = branch.operatingHours as Map<String, dynamic>;
      _selectedTimezone = opHours['timezone'] ?? 'America/Los_Angeles';

      final operatingData = opHours['operating_hours'] as Map<String, dynamic>?;
      if (operatingData != null) {
        _is24Hours = operatingData['is_24_hours'] ?? false;

        final regularHours =
            operatingData['regular_hours'] as Map<String, dynamic>?;
        if (regularHours != null) {
          _regularHours = {};
          regularHours.forEach((day, hours) {
            if (hours is Map) {
              _regularHours[day] = {
                'open': hours['open'] ?? '09:00',
                'close': hours['close'] ?? '17:00',
              };
            }
          });
        }
      }
    }

    // Reset change flag
    setState(() => _branchDataChanged = false);

    // Existing listeners...
    _branchNameController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchAddressController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchCityController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchStateController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchPhoneController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchEmailController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
    _branchManagerController.addListener(
      () => setState(() => _branchDataChanged = true),
    );
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
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _branchCityController.dispose();
    _branchStateController.dispose();
    _branchPhoneController.dispose();
    _branchEmailController.dispose();
    _branchManagerController.dispose();
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

      // Existing partner update code...
      String? logoUrl = widget.partner.logoUrl;
      String? bannerUrl = widget.partner.bannerUrl;

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

      final newPartner = await PartnerService.updatePartner(
        partnerId: widget.partner.id,
        updates: updates,
      );

      ref.invalidate(partnerProvider);
      ref.read(partnerProvider.notifier).state = newPartner.toJson();

      // Handle image uploads (existing code)...
      if (_logoFile != null) {
        final logoUrl = await PartnerService.uploadLogo(
          partnerId: widget.partner.id,
          imageFile: _logoFile!,
        );
        if (context.mounted) {
          ref.read(partnerProvider.notifier).update((partner) {
            if (partner == null) return partner;
            return {...partner, "logo_url": logoUrl};
          });
        }
      }

      if (_bannerFile != null) {
        bannerUrl = await PartnerService.uploadBanner(
          partnerId: widget.partner.id,
          imageFile: _bannerFile!,
        );
        if (context.mounted) {
          ref.read(partnerProvider.notifier).update((partner) {
            if (partner == null) return partner;
            return {...partner, "banner_url": bannerUrl};
          });
        }
      }

      // 🆕 Update branch if changed
      if (_branchDataChanged && _selectedBranch != null) {
        try {
          await _updateBranchData();
        } catch (e) {
          // Error already handled in _updateBranchData
          print('Branch update failed: $e');
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

  // 🆕 Add this method (you'll implement the actual API call later)
  Future<void> _updateBranchData() async {
    if (_selectedBranch == null) return;

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final operatingHours = {
        'timezone': _selectedTimezone,
        'operating_hours': {
          'is_24_hours': _is24Hours,
          'regular_hours': _regularHours,
          'special_hours':
              _selectedBranch
                  ?.operatingHours?['operating_hours']?['special_hours'] ??
              [],
        },
      };

      final updates = {
        'branch_name': _branchNameController.text.trim(),
        'address': _branchAddressController.text.trim(),
        'city': _branchCityController.text.trim(),
        'state': _branchStateController.text.trim(),
        'phone': _branchPhoneController.text.trim(),
        'email': _branchEmailController.text.trim(),
        'manager_name': _branchManagerController.text.trim(),
        'operating_hours': operatingHours,
        if (_branchLatitude != null) 'latitude': _branchLatitude,
        if (_branchLongitude != null) 'longitude': _branchLongitude,
      };

      final result = await PartnerService.updateBranch(
        token: token,
        partnerId: widget.partner.id,
        branchId: _selectedBranch!.id,
        updates: updates,
      );

      if (result == null) {
        throw Exception('Network error: No response from server');
      }

      if (result['success'] == true) {
        // Invalidate branches provider to refresh data
        ref.invalidate(branchesProvider(widget.partner.id));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch updated successfully'),
              backgroundColor: Color(0xFF00D4AA),
              duration: Duration(seconds: 2),
            ),
          );
        }

        setState(() => _branchDataChanged = false);
      } else {
        throw Exception(result['error'] ?? 'Failed to update branch');
      }
    } catch (e) {
      print('❌ Branch update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update branch: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateBranchData(),
            ),
          ),
        );
      }
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

              const SizedBox(height: 24),

              _buildSection(
                title: 'Branch Management',
                child: _buildBranchSection(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchSection() {
    final branchesAsync = ref.watch(branchesProvider(widget.partner.id));

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No branches available',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Branch Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    LineIcons.mapMarker,
                    color: Color(0xFF00D4AA),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBranchId,
                        hint: Text(
                          'Select Branch',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        items: branches.map((branch) {
                          return DropdownMenuItem<String>(
                            value: branch.id,
                            child: Text(branch.branchName),
                          );
                        }).toList(),
                        onChanged: (branchId) {
                          final branch = branches.firstWhere(
                            (b) => b.id == branchId,
                          );
                          setState(() {
                            _selectedBranchId = branchId;
                            _branchDataChanged = false;
                            _populateBranchFields(branch);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Branch Details (shown when branch is selected)
            if (_selectedBranchId != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _branchNameController,
                      label: 'Branch Name',
                      icon: LineIcons.store,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _branchAddressController,
                      label: 'Address',
                      icon: LineIcons.mapMarker,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _branchCityController,
                            label: 'City',
                            icon: LineIcons.building,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _branchStateController,
                            label: 'State',
                            icon: LineIcons.map,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _branchPhoneController,
                      label: 'Phone',
                      icon: LineIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _branchEmailController,
                      label: 'Email',
                      icon: LineIcons.envelope,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _branchManagerController,
                      label: 'Manager Name',
                      icon: LineIcons.user,
                    ),
                    const SizedBox(height: 12),
                    _buildBranchLocationField(),
                    if (_branchDataChanged) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LineIcons.exclamationTriangle,
                              size: 16,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Branch changes will be saved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Operating Hours Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '24/7',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _is24Hours,
                            activeColor: const Color(0xFF00D4AA),
                            onChanged: (value) {
                              setState(() {
                                _is24Hours = value;
                                _branchDataChanged = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (!_is24Hours) ...[
                    const SizedBox(height: 12),
                    ..._buildWeekdayHours(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00D4AA),
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Error loading branches',
            style: TextStyle(color: Colors.red[600], fontSize: 14),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWeekdayHours() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Initialize default hours if empty
    if (_regularHours.isEmpty) {
      for (var day in days) {
        _regularHours[day] = {'open': '09:00', 'close': '17:00'};
      }
    }

    return List.generate(days.length, (index) {
      final day = days[index];
      final label = dayLabels[index];
      final hours = _regularHours[day] ?? {'open': '09:00', 'close': '17:00'};

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 45,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeField(
                value: hours['open']!,
                onChanged: (time) {
                  setState(() {
                    _regularHours[day]!['open'] = time;
                    _branchDataChanged = true;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                LineIcons.arrowRight,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
            Expanded(
              child: _buildTimeField(
                value: hours['close']!,
                onChanged: (time) {
                  setState(() {
                    _regularHours[day]!['close'] = time;
                    _branchDataChanged = true;
                  });
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimeField({
    required String value,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(value.split(':')[0]),
            minute: int.parse(value.split(':')[1]),
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF00D4AA),
                ),
              ),
              child: child!,
            );
          },
        );

        if (time != null) {
          final formattedTime =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Icon(LineIcons.clock, size: 16, color: Colors.grey[600]),
          ],
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
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

  Widget _buildBranchLocationField() {
    return GestureDetector(
      onTap: () => _openMapPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            const Icon(LineIcons.mapMarker, color: Color(0xFF00D4AA), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Branch Location',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _branchLatitude != null && _branchLongitude != null
                        ? '${_branchLatitude!.toStringAsFixed(6)}, ${_branchLongitude!.toStringAsFixed(6)}'
                        : 'Tap to select location on map',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _branchLatitude != null && _branchLongitude != null
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchLocationPicker(
          initialLatitude: _branchLatitude,
          initialLongitude: _branchLongitude,
        ),
      ),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        _branchLatitude = result['latitude'];
        _branchLongitude = result['longitude'];
        _branchDataChanged = true;
      });
    }
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

                  Positioned(top: 12, right: 12, child: _smallEditButton()),
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

                    Positioned(top: 6, right: 6, child: _smallEditButton()),
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
          Text(
            "Upload Banner",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
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
          ),
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
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// Map Picker Widget for Branch Location
class BranchLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const BranchLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  State<BranchLocationPicker> createState() => _BranchLocationPickerState();
}

class _BranchLocationPickerState extends State<BranchLocationPicker> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(
    37.7749,
    -122.4194,
  ); // Default to San Francisco
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _selectedLocation = LatLng(
          widget.initialLatitude!,
          widget.initialLongitude!,
        );
        _isLoading = false;
      });
    } else {
      // Try to get current location
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _isLoading = false);
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _isLoading = false);
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() => _isLoading = false);
          return;
        }

        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15),
        );
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );
    }
  }

  void _onDone() {
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Branch Location',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onDone,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onTap: _onMapTap,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                ),
                // Center marker
                Center(
                  child: Icon(
                    LineIcons.mapMarker,
                    size: 50,
                    color: const Color(0xFF00D4AA),
                  ),
                ),
                // Instructions
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LineIcons.infoCircle,
                              color: const Color(0xFF00D4AA),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap on the map to select location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
