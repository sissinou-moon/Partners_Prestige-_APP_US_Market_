import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

import '../../app/lib/stripe.dart';
import '../../app/providers/subscription_provider.dart';
import '../../components/PaymentBottomSheet.dart';
import 'SubscriptionDetailsPage.dart';

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  bool isAnnual = false;

  @override
  Widget build(BuildContext context) {

    final partner = ref.read(partnerProvider);

    return Consumer(
        builder: (context, ref, child) {
          // This will cause rebuild when subscription changes
          final subscriptionState = ref.watch(subscriptionProvider);
          print("Subscription state updated: ${subscriptionState.hasSubscription}");


          final subscription = ref.watch(subscriptionProvider);
          final isLoading = subscription.isLoading;
          final hasSubscription = subscription.hasSubscription;
          final currentPlan = subscription.plan;

          print("Button state - hasSubscription: $hasSubscription, currentPlan: $currentPlan");

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
              'Choose Your Plan',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPricingCards(partner!['email']),
                const SizedBox(height: 32),
                _buildComparisonTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Select the perfect tier for your business',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Monthly', !isAnnual),
                _buildToggleButton('Annual (Save 15%)', isAnnual),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => isAnnual = !isAnnual);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4AA) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCards(String partnerEmail) {
    final tiers = [
      _TierData(
        name: 'Starter',
        subtitle: 'Entry Level',
        icon: LineIcons.lightningBolt,
        color: const Color(0xFFD97706),
        monthlyPrice: 45,
        annualPrice: 290,
        earnFee: '1.5%',
        redeemFee: '1.5%',
        settlement: 'Monthly',
        speed: 'Net 30 days',
        features: [
          _Feature('Basic transaction list (30 days)', true),
          _Feature('Basic dashboard summary', true),
          _Feature('Simple daily reports', true),
          _Feature('POS integration', true),
          _Feature('1 location only', true),
          _Feature('Analytics', false),
          _Feature('Custom branding', false),
          _Feature('API access', false),
        ],
        priceId: 'price_1SZqIl2fFh79gGsXOtDzRPfX'
      ),
      _TierData(
        name: 'Growth',
        priceId: 'price_1SZqJb2fFh79gGsXLCbvfwpl',
        subtitle: 'Most Popular',
        icon: LineIcons.lineChart,
        color: const Color(0xFF64748B),
        monthlyPrice: 75,
        annualPrice: 990,
        earnFee: '1.4%',
        redeemFee: '1.25%',
        settlement: 'Daily',
        speed: 'Next business day',
        isPopular: true,
        features: [
          _Feature('Full history (12 months)', true),
          _Feature('Enhanced dashboard', true),
          _Feature('Weekly & monthly reports', true),
          _Feature('Customer insights', true),
          _Feature('Up to 5 locations', true),
          _Feature('Custom rates', true),
          _Feature('Staff management', true),
          _Feature('API access', false),
        ],
      ),
      _TierData(
        name: 'Premier',
        priceId: 'price_1SZqJy2fFh79gGsXbseFSWzN',
        subtitle: 'Enterprise',
        icon: LineIcons.crown,
        color: const Color(0xFFEAB308),
        monthlyPrice: 145,
        annualPrice: 2490,
        earnFee: '1.2%',
        redeemFee: '1.0%',
        settlement: 'Daily + Real-time',
        speed: 'Same-day / Instant',
        features: [
          _Feature('Unlimited history', true),
          _Feature('Predictive analytics', true),
          _Feature('All reports + API', true),
          _Feature('Customer segmentation', true),
          _Feature('Unlimited locations', true),
          _Feature('Full customization', true),
          _Feature('Custom branding', true),
          _Feature('Account manager', true),
        ],
      ),
    ];

    return SizedBox(
      height: 520,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tiers.length,
        itemBuilder: (context, index) => _buildTierCard(tiers[index], partnerEmail),
      ),
    );
  }

  Widget _buildTierCard(_TierData tier, String partnerEmail) {
    final price = isAnnual ? tier.annualPrice : tier.monthlyPrice;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: tier.isPopular
            ? Border.all(color: const Color(0xFF00D4AA), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: tier.isPopular
                ? const Color(0xFF00D4AA).withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: tier.isPopular ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tier.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tier.icon, color: tier.color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tier.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    tier.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$$price',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '/${isAnnual ? 'yr' : 'mo'}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildFeeRow('Earn Fee:', tier.earnFee),
                        const SizedBox(height: 8),
                        _buildFeeRow('Redeem:', tier.redeemFee),
                        const SizedBox(height: 8),
                        _buildFeeRow('Settlement:', tier.settlement),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final subscription = ref.watch(subscriptionProvider);
                        final isLoading = subscription.isLoading;
                        final hasSubscription = subscription.hasSubscription;
                        final currentPlan = subscription.plan;

                        final isCurrentPlan = hasSubscription && currentPlan == tier.name;

                        return ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                            if (isCurrentPlan) {
                              // Navigate to subscription details
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubscriptionDetailsPage(
                                    subscriptionData: subscription.data,
                                    planName: tier.name,
                                  ),
                                ),
                              );
                            } else {
                              final token = await LocalStorage.getToken();
                              showSubscriptionSheet(context, token!, partnerEmail, tier);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentPlan
                                ? Colors.green[50]
                                : tier.isPopular
                                ? const Color(0xFF00D4AA)
                                : Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCurrentPlan ? Colors.green[700]! : Colors.white,
                              ),
                            ),
                          )
                              : Text(
                            isCurrentPlan ? 'Manage Subscription' : 'Get Started',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCurrentPlan ? Colors.green[700] : Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tier.features.length,
                      itemBuilder: (context, index) {
                        final feature = tier.features[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                feature.included
                                    ? LineIcons.checkCircle
                                    : LineIcons.timesCircle,
                                size: 16,
                                color: feature.included
                                    ? const Color(0xFF00D4AA)
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feature.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: feature.included
                                        ? Colors.black87
                                        : Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LineIcons.thList,
                color: Color(0xFF00D4AA),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Feature Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            children: [
              _buildTableHeader(),
              ..._buildTableRows(),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      children: [
        _tableCell('Feature', isHeader: true),
        _tableCell('Bronze', isHeader: true, color: const Color(0xFFD97706)),
        _tableCell('Silver', isHeader: true, color: const Color(0xFF64748B)),
        _tableCell('Gold', isHeader: true, color: const Color(0xFFEAB308)),
      ],
    );
  }

  List<TableRow> _buildTableRows() {
    final data = [
      ['Data Access', '30 days', '12 months', 'Unlimited'],
      ['Dashboard', 'Basic', 'Enhanced', 'Advanced'],
      ['Analytics', 'None', 'Basic', 'Predictive'],
      ['Locations', '1', 'Up to 5', 'Unlimited'],
      ['Customization', 'None', 'Limited', 'Full'],
      ['API Access', 'No', 'No', 'Yes'],
      ['Support', 'Standard', 'Priority', 'Dedicated'],
    ];

    return data.map((row) {
      return TableRow(
        children: row.map((cell) => _tableCell(cell)).toList(),
      );
    }).toList();
  }

  Widget _tableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Text(
        text,
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: color ?? (isHeader ? const Color(0xFF1A1A1A) : Colors.black87),
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          fontSize: isHeader ? 13 : 13,
        ),
      ),
    );
  }

  // Show subscription bottom sheet
  void showSubscriptionSheet(BuildContext context, String token, String partnerEmail, _TierData tier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionBottomSheet(
        planId: tier.name,
        planName: tier.name,
        price: tier.priceId,
        subscriptionService: SubscriptionService(token),
        partnerEmail: partnerEmail,
        token: token,
      ),
    );
  }

}

class _TierData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int monthlyPrice;
  final int annualPrice;
  final String earnFee;
  final String redeemFee;
  final String settlement;
  final String speed;
  final bool isPopular;
  final List<_Feature> features;
  final String priceId;

  _TierData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.earnFee,
    required this.redeemFee,
    required this.settlement,
    required this.speed,
    this.isPopular = false,
    required this.features,
    required this.priceId,
  });
}

class _Feature {
  final String text;
  final bool included;

  _Feature(this.text, this.included);
}