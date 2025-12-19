import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/lib/rewards.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

import '../../app/lib/supabase.dart';
import '../../app/providers/partner_provider.dart';

// Campaign Page with enhanced functionality
class CompaignPage extends ConsumerStatefulWidget {
  const CompaignPage({super.key});

  @override
  ConsumerState<CompaignPage> createState() => _CompaignPageState();
}

class _CompaignPageState extends ConsumerState<CompaignPage> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCampaignDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CampaignFormDialog(),
    );
  }

  void _showEditCampaignDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => _CampaignFormDialog(reward: reward),
    );
  }

  void _showViewDetailsDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => _CampaignDetailsDialog(reward: reward),
    );
  }

  Future<void> _deleteCampaign(String rewardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: const Text(
          'Are you sure you want to delete this campaign? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              PartnerService.deleteReward(rewardId);
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement delete functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign deleted successfully, click refresh!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider);

    if (partner == null) {
      return const Center(child: Text('No business data found'));
    }

    final partnerId = partner['id'] as String;
    final rewardsAsyncValue = ref.watch(partnerRewardsProvider(partnerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(context),

              const SizedBox(height: 24),

              // Search and Actions Bar
              _buildSearchBar(),

              const SizedBox(height: 16),

              // Campaign Count
              rewardsAsyncValue.when(
                data: (rewards) {
                  return _buildCampaignCount(rewards.length);
                },
                loading: () => _buildCampaignCount(0),
                error: (error, stack) => _buildCampaignCount(0),
              ),

              const SizedBox(height: 20),

              // Rewards Table
              rewardsAsyncValue.when(
                data: (rewards) {
                  final filteredRewards = _filterRewards(rewards, _searchQuery);
                  return _RewardsTable(
                    rewards: filteredRewards,
                    onEdit: _showEditCampaignDialog,
                    onViewDetails: _showViewDetailsDialog,
                    onDelete: _deleteCampaign,
                  );
                },
                loading: () => const _LoadingRewardsTable(),
                error: (error, stack) =>
                    _ErrorRewardsTable(error: error.toString()),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campaigns',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your promotional campaigns',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddCampaignDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13B386),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            FluentIcons.add_20_filled,
            size: 18,
            color: Colors.white,
          ),
          label: const Text(
            'Add Campaign',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search campaigns by title or description...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(FluentIcons.search_20_filled, color: Colors.grey[600]),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  FluentIcons.dismiss_20_filled,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCampaignCount(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'You already have $count existing campaign${count != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            FluentIcons.arrow_clockwise_20_filled,
            size: 18,
            color: const Color(0xFF00D4AA),
          ),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Loading...")));
            final partner = ref.read(partnerProvider);
            if (partner != null) {
              ref.invalidate(partnerRewardsProvider(partner['id'] as String));
            }
          },
          tooltip: 'Refresh campaigns',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterRewards(
    List<Map<String, dynamic>> rewards,
    String query,
  ) {
    if (query.isEmpty) {
      return rewards;
    }

    final lowerQuery = query.toLowerCase();
    return rewards
        .where(
          (reward) =>
              (reward['title'] as String? ?? '').toLowerCase().contains(
                lowerQuery,
              ) ||
              (reward['description'] as String? ?? '').toLowerCase().contains(
                lowerQuery,
              ),
        )
        .toList();
  }
}

/// Campaign Form Dialog
class _CampaignFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? reward;

  const _CampaignFormDialog({this.reward});

  @override
  ConsumerState<_CampaignFormDialog> createState() =>
      _CampaignFormDialogState();
}

class _CampaignFormDialogState extends ConsumerState<_CampaignFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _discountAmountController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _maxRedemptionsController;
  late TextEditingController _maxPerUserController;
  late TextEditingController _termsController;

  bool diasbleButtonsActions = false;
  File? _selectedImage;
  bool _isUploadingImage = false;

  String _rewardType = 'DISCOUNT_PERCENTAGE';
  String _status = 'ACTIVE';
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isGlobal = true;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    final reward = widget.reward;
    _titleController = TextEditingController(text: reward?['title'] ?? '');
    _descriptionController = TextEditingController(
      text: reward?['description'] ?? '',
    );
    _pointsController = TextEditingController(
      text: (reward?['points_required'] ?? '').toString(),
    );
    _discountPercentageController = TextEditingController(
      text: (reward?['discount_percentage'] ?? '').toString(),
    );
    _discountAmountController = TextEditingController(
      text: (reward?['discount_amount'] ?? '').toString(),
    );
    _maxDiscountController = TextEditingController(
      text: (reward?['max_discount_amount'] ?? '').toString(),
    );
    _maxRedemptionsController = TextEditingController(
      text: (reward?['max_redemptions'] ?? '').toString(),
    );
    _maxPerUserController = TextEditingController(
      text: (reward?['max_per_user'] ?? '').toString(),
    );
    _termsController = TextEditingController(
      text: reward?['terms_conditions'] ?? '',
    );

    // Initialize branch selection
    _selectedBranchId = reward?['partner_branch_id'];

    if (reward != null) {
      _rewardType = reward['reward_type'] ?? 'DISCOUNT_PERCENTAGE';
      _status = reward['status'] ?? 'ACTIVE';
      _isGlobal = reward['is_global'] ?? true;
      _validFrom = DateTime.tryParse(reward['valid_from'] ?? '');
      _validUntil = DateTime.tryParse(reward['valid_until'] ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _maxDiscountController.dispose();
    _maxRedemptionsController.dispose();
    _maxPerUserController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? _validFrom : _validUntil;
    final firstDate = DateTime.now();
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage(String rewardId) async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final token = await LocalStorage.getToken();
      final imageUrl = await RewardService(
        token!,
      ).uploadBanner(rewardID: rewardId, imageFile: _selectedImage!);

      // Image uploaded successfully, you can store the URL if needed
      print('Image uploaded successfully: $imageUrl');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final partner = ref.read(partnerProvider);
      if (partner == null) return;

      final payload = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'points_required': int.tryParse(_pointsController.text) ?? 0,
        'reward_type': _rewardType,
        'discount_percentage': _rewardType == 'DISCOUNT_PERCENTAGE'
            ? int.tryParse(_discountPercentageController.text)
            : null,
        'discount_amount': _rewardType == 'DISCOUNT_AMOUNT'
            ? int.tryParse(_discountAmountController.text)
            : null,
        'max_discount_amount': int.tryParse(_maxDiscountController.text),
        'partner_id': partner['id'],
        'category': partner['category'],
        'is_global': _isGlobal,
        'partner_branch_id': _isGlobal ? null : _selectedBranchId,
        'valid_from': _validFrom?.toIso8601String(),
        'valid_until': _validUntil?.toIso8601String(),
        'max_redemptions': int.tryParse(_maxRedemptionsController.text) ?? 0,
        'max_per_user': int.tryParse(_maxPerUserController.text) ?? 0,
        'status': 'INACTIVE',
        'terms_conditions': _termsController.text,
      };

      try {
        setState(() => diasbleButtonsActions = true);
        final token = await LocalStorage.getToken();

        if (widget.reward != null) {
          // Update existing reward
          await RewardService(
            token!,
          ).updateReward(widget.reward!['id'], payload);

          // Upload image if selected for existing reward
          if (_selectedImage != null) {
            await _uploadImage(widget.reward!['id']);
          }

          if (mounted) {
            setState(() {
              diasbleButtonsActions = false;
            });
            Future.delayed(Duration(milliseconds: 1000), () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Campaign updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            });
          }
        } else {
          // Create new reward
          final response = await RewardService(token!).createReward(payload);

          // Extract the new reward ID from response
          if (response['success'] == true && response['reward'] != null) {
            final newRewardId = response['reward']['id'] as String;

            // Upload image if selected for new reward
            if (_selectedImage != null) {
              await _uploadImage(newRewardId);
            }

            if (mounted) {
              setState(() {
                diasbleButtonsActions = false;
              });
              Future.delayed(Duration(milliseconds: 1000), () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Campaign created successfully, wait for the admin to approve your compaign',
                    ),
                    backgroundColor: const Color.fromARGB(255, 48, 115, 50),
                  ),
                );
              });
            }
          } else {
            throw 'Failed to create campaign: ${response['error']}';
          }
        }
      } catch (e) {
        setState(() {
          diasbleButtonsActions = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider);
    final branchesAsync = partner != null
        ? ref.watch(branchesProvider(partner['id'] as String))
        : const AsyncValue<List<Branch>>.loading();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            automaticallyImplyLeading: false,
            title: Text(
              widget.reward != null ? 'Edit Campaign' : 'New Campaign',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              if (diasbleButtonsActions)
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
                  onPressed: _submitForm,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(LineIcons.times, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
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
                  // Campaign Image Section
                  _buildSection(
                    title: 'Campaign Image',
                    child: _buildImageUploadSection(),
                  ),

                  const SizedBox(height: 24),

                  // Basic Information
                  _buildSection(
                    title: 'Basic Information',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Campaign Title',
                          icon: LineIcons.tag,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: LineIcons.alignLeft,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _pointsController,
                          label: 'Points Required',
                          icon: LineIcons.award,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reward Configuration
                  _buildSection(
                    title: 'Reward Configuration',
                    child: Column(
                      children: [
                        _buildDropdown(
                          label: 'Reward Type',
                          icon: LineIcons.gift,
                          value: _rewardType,
                          items: [
                            'DISCOUNT_PERCENTAGE',
                            'DISCOUNT_AMOUNT',
                            'FREE_PRODUCT',
                          ],
                          onChanged: (value) =>
                              setState(() => _rewardType = value!),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Status',
                          icon: LineIcons.toggleOn,
                          value: _status,
                          items: ['ACTIVE', 'INACTIVE'],
                          onChanged: (value) =>
                              setState(() => _status = value!),
                        ),
                        const SizedBox(height: 16),
                        if (_rewardType == 'DISCOUNT_PERCENTAGE') ...[
                          _buildTextField(
                            controller: _discountPercentageController,
                            label: 'Discount Percentage (%)',
                            icon: LineIcons.percent,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _maxDiscountController,
                            label: 'Maximum Discount Amount',
                            icon: LineIcons.dollarSign,
                            keyboardType: TextInputType.number,
                          ),
                        ] else if (_rewardType == 'DISCOUNT_AMOUNT') ...[
                          _buildTextField(
                            controller: _discountAmountController,
                            label: 'Discount Amount',
                            icon: LineIcons.dollarSign,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Branch Assignment
                  _buildSection(
                    title: 'Branch Assignment',
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              'Global Campaign',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Available across all branches',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isGlobal,
                            onChanged: (value) =>
                                setState(() => _isGlobal = value),
                            activeColor: const Color(0xFF00D4AA),
                          ),
                        ),
                        if (!_isGlobal) ...[
                          const SizedBox(height: 16),
                          _buildBranchDropdown(),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Validity Period
                  _buildSection(
                    title: 'Validity Period',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Valid From',
                            date: _validFrom,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'Valid Until',
                            date: _validUntil,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Redemption Limits
                  _buildSection(
                    title: 'Redemption Limits',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _maxRedemptionsController,
                            label: 'Max Redemptions',
                            icon: LineIcons.hashtag,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxPerUserController,
                            label: 'Max Per User',
                            icon: LineIcons.user,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms & Conditions
                  _buildSection(
                    title: 'Terms & Conditions',
                    child: _buildTextField(
                      controller: _termsController,
                      label: 'Terms & Conditions',
                      icon: LineIcons.fileContract,
                      maxLines: 4,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
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

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        if (_selectedImage != null) ...[
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
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
                Image.file(_selectedImage!, fit: BoxFit.cover),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LineIcons.times,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: _selectedImage != null ? 60 : 180,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LineIcons.photoVideo,
                    size: _selectedImage != null ? 24 : 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedImage != null
                        ? 'Change banner'
                        : 'Tap to upload banner',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedImage == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 1200x400px',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
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
                    child: Text(item.replaceAll('_', ' ')),
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(LineIcons.calendar, color: const Color(0xFF00D4AA), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    final partner = ref.watch(partnerProvider);
    if (partner == null) {
      return const SizedBox();
    }

    final branchesAsync = ref.watch(branchesProvider(partner['id']));

    return branchesAsync.when(
      data: (branches) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<String>(
            value: _selectedBranchId,
            decoration: InputDecoration(
              labelText: 'Select Branch',
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: const Icon(
                LineIcons.store,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select a branch'),
              ),
              ...branches.map((branch) {
                return DropdownMenuItem(
                  value: branch.id,
                  child: Text('${branch.branchName}'),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedBranchId = value;
              });
            },
            validator: (value) {
              if (!_isGlobal && (value == null || value.isEmpty)) {
                return 'Please select a branch';
              }
              return null;
            },
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00D4AA),
            ),
          ),
        ),
      ),
      error: (error, stack) {
        print(partner['id']);
        print(branchesAsync);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Error loading branches: $error',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      },
    );
  }

  //now
}

/// Campaign Details Dialog
class _CampaignDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> reward;

  const _CampaignDetailsDialog({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            automaticallyImplyLeading: false,
            title: const Text(
              'Campaign Details',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LineIcons.times, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Image
                if (reward['image_url'] != null) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      reward['image_url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              LineIcons.image,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Basic Information
                _buildDetailsSection(
                  title: 'Basic Information',
                  children: [
                    _buildDetailRow('Title', reward['title']),
                    _buildDetailRow('Description', reward['description']),
                    _buildDetailRow(
                      'Points Required',
                      '${reward['points_required'] ?? 'N/A'}',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Reward Details
                _buildDetailsSection(
                  title: 'Reward Details',
                  children: [
                    _buildDetailRow(
                      'Reward Type',
                      (reward['reward_type'] as String?)?.replaceAll(
                            '_',
                            ' ',
                          ) ??
                          'N/A',
                    ),
                    if (reward['discount_percentage'] != null)
                      _buildDetailRow(
                        'Discount Percentage',
                        '${reward['discount_percentage']}%',
                      ),
                    if (reward['discount_amount'] != null)
                      _buildDetailRow(
                        'Discount Amount',
                        '\$${reward['discount_amount']}',
                      ),
                    if (reward['max_discount_amount'] != null)
                      _buildDetailRow(
                        'Max Discount',
                        '\$${reward['max_discount_amount']}',
                      ),
                    _buildDetailRow(
                      'Status',
                      reward['status'] ?? 'N/A',
                      statusColor: reward['status'] == 'ACTIVE'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Validity Period
                _buildDetailsSection(
                  title: 'Validity Period',
                  children: [
                    _buildDetailRow(
                      'Valid From',
                      _formatDate(reward['valid_from']),
                    ),
                    _buildDetailRow(
                      'Valid Until',
                      _formatDate(reward['valid_until']),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Redemption Info
                _buildDetailsSection(
                  title: 'Redemption Information',
                  children: [
                    _buildDetailRow(
                      'Current Redemptions',
                      '${reward['current_redemptions'] ?? 0}',
                    ),
                    _buildDetailRow(
                      'Max Redemptions',
                      '${reward['max_redemptions'] ?? 'Unlimited'}',
                    ),
                    _buildDetailRow(
                      'Max Per User',
                      '${reward['max_per_user'] ?? 'Unlimited'}',
                    ),
                    _buildDetailRow(
                      'Scope',
                      reward['is_global'] == true
                          ? 'Global'
                          : 'Branch Specific',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Terms & Conditions
                if (reward['terms_conditions'] != null &&
                    (reward['terms_conditions'] as String).isNotEmpty)
                  _buildDetailsSection(
                    title: 'Terms & Conditions',
                    children: [
                      Text(
                        reward['terms_conditions'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required List<Widget> children,
  }) {
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: statusColor != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  )
                : Text(
                    value ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

/// Updated Rewards Table with callbacks
class _RewardsTable extends ConsumerWidget {
  final List<Map<String, dynamic>> rewards;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onViewDetails;
  final Function(String) onDelete;

  const _RewardsTable({
    required this.rewards,
    required this.onEdit,
    required this.onViewDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rewards.isEmpty) {
      return const _EmptyRewardsState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => Colors.grey.shade50,
          ),
          headingRowHeight: 56,
          dataRowHeight: 60,
          columns: const [
            DataColumn(
              label: Text(
                'Title',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Points Required',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Reward Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Redemptions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
          rows: List.generate(rewards.length, (index) {
            final reward = rewards[index];
            return _buildRewardRow(reward);
          }),
        ),
      ),
    );
  }

  DataRow _buildRewardRow(Map<String, dynamic> reward) {
    final title = reward['title'] as String? ?? 'N/A';
    final pointsRequired = reward['points_required'] as String? ?? 0;
    final rewardType = reward['reward_type'] as String? ?? 'N/A';
    final status = reward['status'] as String? ?? 'INACTIVE';
    final currentRedemptions = reward['current_redemptions'] as int? ?? 0;
    final maxRedemptions = reward['max_redemptions'] as int? ?? 0;

    final isActive = status == 'ACTIVE';

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              '$pointsRequired',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
        DataCell(Center(child: _RewardTypeBadge(type: rewardType))),
        DataCell(
          Center(
            child: _StatusBadge(isActive: isActive, status: status),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              '$currentRedemptions / $maxRedemptions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        DataCell(
          Center(
            child: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.edit_20_filled,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      const Text('Edit'),
                    ],
                  ),
                  onTap: () => onEdit(reward),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.eye_20_filled,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      const Text('View Details'),
                    ],
                  ),
                  onTap: () => onViewDetails(reward),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.delete_20_filled,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => onDelete(reward['id']),
                ),
              ],
              child: Icon(
                FluentIcons.more_vertical_20_filled,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reward Type Badge
class _RewardTypeBadge extends StatelessWidget {
  final String type;

  const _RewardTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (type) {
      case 'DISCOUNT_PERCENTAGE':
        backgroundColor = const Color(0xFF00D4AA).withOpacity(0.2);
        textColor = const Color(0xFF00D4AA);
        displayText = 'Discount %';
        break;
      case 'DISCOUNT_AMOUNT':
        backgroundColor = const Color(0xFF4A90E2).withOpacity(0.2);
        textColor = const Color(0xFF4A90E2);
        displayText = 'Discount';
        break;
      case 'FREE_PRODUCT':
        backgroundColor = const Color(0xFFFFB020).withOpacity(0.2);
        textColor = const Color(0xFFFFB020);
        displayText = 'Free Product';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey[700]!;
        displayText = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Status Badge
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String status;

  const _StatusBadge({required this.isActive, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pending,
            size: 12,
            color: isActive ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading State Widget
class _LoadingRewardsTable extends StatelessWidget {
  const _LoadingRewardsTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ...List.generate(
            5,
            (index) => Column(
              children: [
                Row(
                  children: [
                    _ShimmerBox(height: 14, width: 110),
                    const SizedBox(width: 20),
                    _ShimmerBox(height: 14, width: 100),
                    const SizedBox(width: 20),
                    _ShimmerBox(height: 14, width: 40),
                    const SizedBox(width: 20),
                  ],
                ),
                if (index < 4) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error State Widget
class _ErrorRewardsTable extends StatelessWidget {
  final String error;

  const _ErrorRewardsTable({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              FluentIcons.warning_20_filled,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading campaigns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer Box for Loading
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double width;

  const _ShimmerBox({required this.height, required this.width});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                _animationController.value - 0.3,
                _animationController.value,
                _animationController.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Empty State Widget
class _EmptyRewardsState extends StatelessWidget {
  const _EmptyRewardsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              FluentIcons.gift_20_filled,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No campaigns found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first campaign to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
