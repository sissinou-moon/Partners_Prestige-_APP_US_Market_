import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/lib/supabase.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/providers/pos_provider.dart';
import '../../app/lib/pos.dart';
import '../../app/storage/local_storage.dart';

class LocationsPage extends ConsumerStatefulWidget {
  const LocationsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends ConsumerState<LocationsPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStatus = 'ALL';
  late AnimationController _refreshAnimationController;
  bool _isLoadingIntegration = true;
  String _integrationType = 'NONE'; // 'SQUARE', 'CLOVER', 'NONE'

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkIntegrationStatus();
  }

  Future<void> _checkIntegrationStatus() async {
    try {
      final partner = ref.read(partnerProvider);
      final token = await LocalStorage.getToken();
      if (partner != null && token != null) {
        final connection = await POSIntegrationService.getPOSConnection(
          partnerId: partner['id'],
          token: token,
        );
        if (connection != null && connection['connection'] != null) {
          setState(() {
            _integrationType = connection['connection']['provider'] ?? 'NONE';
          });
        }
      }
    } catch (e) {
      print('Integration check error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingIntegration = false);
    }
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  void _refresh() {
    HapticFeedback.mediumImpact();
    _refreshAnimationController.repeat();
    ref.invalidate(locationsProvider);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _refreshAnimationController.stop();
    });
  }

  List<SquareLocation> _filterLocations(List<SquareLocation> locations) {
    var filtered = locations;

    // Status filter
    if (_filterStatus != 'ALL') {
      filtered = filtered.where((loc) => loc.status == _filterStatus).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((loc) {
        final query = _searchQuery.toLowerCase();
        return loc.name.toLowerCase().contains(query) ||
            (loc.businessName?.toLowerCase().contains(query) ?? false) ||
            (loc.address?.fullAddress.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

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
          'POS Locations',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          RotationTransition(
            turns: _refreshAnimationController,
            child: IconButton(
              icon: const Icon(LineIcons.syncIcon, color: Color(0xFF00D4AA)),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      floatingActionButton: _integrationType == 'SQUARE'
          ? FloatingActionButton.extended(
              onPressed: () => _showAddLocationDialog(),
              backgroundColor: const Color(0xFF00D4AA),
              icon: const Icon(LineIcons.plus, color: Colors.white),
              label: const Text(
                'Add Location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: _isLoadingIntegration
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            )
          : _integrationType == 'CLOVER'
          ? _buildCloverMessage()
          : _integrationType == 'NONE'
          ? _buildNoIntegrationMessage()
          : Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: locationsAsync.when(
                    data: (locations) {
                      final filteredLocations = _filterLocations(locations);

                      if (filteredLocations.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        color: const Color(0xFF00D4AA),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLocations.length,
                          itemBuilder: (context, index) {
                            return _buildLocationCard(filteredLocations[index]);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                    error: (error, stack) => _buildErrorState(error.toString()),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                HapticFeedback.selectionClick();
              },
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search locations...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                prefixIcon: const Icon(
                  LineIcons.search,
                  color: Color(0xFF00D4AA),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LineIcons.times,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          HapticFeedback.selectionClick();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Active'),
                const SizedBox(width: 8),
                _buildFilterChip('INACTIVE', 'Inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
        HapticFeedback.selectionClick();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF00D4AA),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF00D4AA) : Colors.grey[300]!,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildLocationCard(SquareLocation location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showLocationDetails(location);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LineIcons.store,
                        color: Color(0xFF00D4AA),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (location.businessName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              location.businessName!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusBadge(location.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (location.address != null) ...[
                  _buildInfoRow(
                    LineIcons.mapMarker,
                    location.address!.fullAddress,
                  ),
                  const SizedBox(height: 12),
                ],
                if (location.phoneNumber != null) ...[
                  _buildInfoRow(LineIcons.phone, location.phoneNumber!),
                  const SizedBox(height: 12),
                ],
                if (location.currency != null || location.country != null) ...[
                  Row(
                    children: [
                      if (location.currency != null)
                        Expanded(
                          child: _buildInfoRow(
                            LineIcons.dollarSign,
                            location.currency!,
                          ),
                        ),
                      if (location.country != null)
                        Expanded(
                          child: _buildInfoRow(
                            LineIcons.globe,
                            location.country!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (location.capabilities != null &&
                    location.capabilities!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: location.capabilities!.take(3).map((capability) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatCapability(capability),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00D4AA),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(LineIcons.store, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'No locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'No locations available',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LineIcons.exclamationTriangle,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                LineIcons.syncIcon,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloverMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF26AA2D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LineIcons.leaf,
                size: 64,
                color: Color(0xFF26AA2D),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Clover Integration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You can't create multi-locations when you use CLOVER because every partner is a branch. Please create an owner account for each of your locations.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIntegrationMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LineIcons.plug, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Integration Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You need to connect your account with SQUARE or CLOVER to manage locations.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(SquareLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationDetailsSheet(location: location),
    );
  }

  String _formatCapability(String capability) {
    return capability
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  void _showAddLocationDialog() {
    final branchNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final sublocalityCtrl = TextEditingController();
    final postalCodeCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'US');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LineIcons.plus, color: Color(0xFF00D4AA)),
            SizedBox(width: 12),
            Text('Add New Location', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(branchNameCtrl, 'Branch Name', LineIcons.store),
              const SizedBox(height: 12),
              _buildTextField(emailCtrl, 'Business Email', LineIcons.envelope),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      firstNameCtrl,
                      'First Name',
                      LineIcons.user,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      lastNameCtrl,
                      'Last Name',
                      LineIcons.user,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                addressCtrl,
                'Address Line 1',
                LineIcons.mapMarker,
              ),
              const SizedBox(height: 12),
              _buildTextField(cityCtrl, 'City (Locality)', LineIcons.city),
              const SizedBox(height: 12),
              _buildTextField(sublocalityCtrl, 'Sublocality', LineIcons.mapPin),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      postalCodeCtrl,
                      'Postal Code',
                      LineIcons.mailBulk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      countryCtrl,
                      'Country',
                      LineIcons.globe,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _createLocation(
                branchName: branchNameCtrl.text,
                email: emailCtrl.text,
                firstName: firstNameCtrl.text,
                lastName: lastNameCtrl.text,
                address: addressCtrl.text,
                city: cityCtrl.text,
                sublocality: sublocalityCtrl.text,
                postalCode: postalCodeCtrl.text,
                country: countryCtrl.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Create Location',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 18),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Future<void> _createLocation({
    required String branchName,
    required String email,
    required String firstName,
    required String lastName,
    required String address,
    required String city,
    required String sublocality,
    required String postalCode,
    required String country,
  }) async {
    try {
      HapticFeedback.mediumImpact();

      final partner = ref.read(partnerProvider);
      final user = ref.read(userProvider);
      final locations = ref.read(locationsProvider);
      final partnerId = partner!['id'];

      final response = await PartnerService.createSquareLocation(
        branchName: branchName,
        businessEmail: email,
        firstName: firstName,
        lastName: lastName,
        addressLine1: address,
        locality: city,
        sublocality: sublocality,
        postalCode: postalCode,
        country: country,
        partnerId: partnerId,
        tier: user!['tier'],
        howMuch: locations.value!.length,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location created successfully!'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );
        _refresh();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Location Details Bottom Sheet
class LocationDetailsSheet extends StatelessWidget {
  final SquareLocation location;

  const LocationDetailsSheet({Key? key, required this.location})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LineIcons.store,
                            color: Color(0xFF00D4AA),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (location.businessName != null)
                                Text(
                                  location.businessName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildDetailSection(
                      'Location ID',
                      location.id,
                      LineIcons.fingerprint,
                    ),
                    _buildDetailSection(
                      'Status',
                      location.status,
                      LineIcons.infoCircle,
                    ),
                    if (location.address != null)
                      _buildDetailSection(
                        'Address',
                        location.address!.fullAddress,
                        LineIcons.mapMarker,
                      ),
                    if (location.phoneNumber != null)
                      _buildDetailSection(
                        'Phone',
                        location.phoneNumber!,
                        LineIcons.phone,
                      ),
                    if (location.websiteUrl != null)
                      _buildDetailSection(
                        'Website',
                        location.websiteUrl!,
                        LineIcons.globe,
                      ),
                    if (location.currency != null)
                      _buildDetailSection(
                        'Currency',
                        location.currency!,
                        LineIcons.dollarSign,
                      ),
                    if (location.timezone != null)
                      _buildDetailSection(
                        'Timezone',
                        location.timezone!,
                        LineIcons.clock,
                      ),
                    if (location.capabilities != null &&
                        location.capabilities!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Capabilities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: location.capabilities!.map((cap) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatCapability(cap),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00D4AA),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00D4AA), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCapability(String capability) {
    return capability
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
