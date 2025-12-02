// lib/pages/subscription_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:prestige_partners/app/providers/subscription_provider.dart';

class SubscriptionDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? subscriptionData;
  final String planName;

  const SubscriptionDetailsPage({
    Key? key,
    this.subscriptionData,
    required this.planName,
  }) : super(key: key);

  @override
  ConsumerState<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends ConsumerState<SubscriptionDetailsPage> {
  bool _isCanceling = false;

  @override
  Widget build(BuildContext context) {
    // Watch the subscription state
    final subscriptionState = ref.watch(subscriptionProvider);

    // Get the subscription data from state
    final subscription = widget.subscriptionData ?? subscriptionState.data;

    if (subscription == null && subscriptionState.hasChecked) {
      return _buildNoSubscriptionState();
    }

    if (subscriptionState.isLoading) {
      return _buildLoadingState();
    }

    final planName = subscription!['plan'] ?? widget.planName;
    final status = subscription['status'] ?? 'active';
    final subscriptionId = subscription['stripe_subscription_id'] ?? 'N/A';
    final customerId = subscription['stripe_customer_id'] ?? 'N/A';
    final createdAt = subscription['created_at'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(subscription['created_at']))
        : 'N/A';

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
        title: Text(
          'Subscription Details',
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
            _buildHeader(planName, status),
            const SizedBox(height: 24),
            _buildInfoCard(subscriptionId, customerId, createdAt),
            const SizedBox(height: 24),
            _buildPlanCard(planName),
            const SizedBox(height: 32),
            _buildActionButtons(status),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
            ),
            SizedBox(height: 20),
            Text(
              'Loading subscription...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
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
        title: Text(
          'Subscription Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LineIcons.creditCard,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'You don\'t have an active subscription yet. Choose a plan to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Plans',
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

  Widget _buildHeader(String planName, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = LineIcons.checkCircle;
        break;
      case 'trialing':
        statusColor = Colors.blue;
        statusIcon = LineIcons.clock;
        break;
      case 'past_due':
      case 'unpaid':
        statusColor = Colors.orange;
        statusIcon = LineIcons.exclamationTriangle;
        break;
      case 'canceled':
        statusColor = Colors.grey;
        statusIcon = LineIcons.timesCircle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = LineIcons.infoCircle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LineIcons.crown, color: const Color(0xFF00D4AA), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.grey, height: 1),
      ],
    );
  }

  Widget _buildInfoCard(String subscriptionId, String customerId, String createdAt) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineIcons.infoCircle, color: Colors.black54, size: 18),
              const SizedBox(width: 8),
              Text(
                'Subscription Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Subscription ID:', subscriptionId),
          const SizedBox(height: 12),
          _buildInfoRow('Customer ID:', customerId),
          const SizedBox(height: 12),
          _buildInfoRow('Created:', createdAt),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(LineIcons.copy, size: 14, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(String planName) {
    // Get plan details based on plan name
    Map<String, dynamic> planDetails = _getPlanDetails(planName);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineIcons.layerGroup, color: Colors.black54, size: 18),
              const SizedBox(width: 8),
              Text(
                'Plan Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanDetailRow('Plan Name:', planName),
          const SizedBox(height: 12),
          _buildPlanDetailRow('Price:', planDetails['price'] ?? '\$--.--'),
          const SizedBox(height: 12),
          _buildPlanDetailRow('Billing Period:', planDetails['period'] ?? 'Monthly'),
          const SizedBox(height: 12),
          _buildPlanDetailRow('Next Billing:', planDetails['nextBilling'] ?? 'N/A'),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPlanDetails(String planName) {
    // Define your plan details here
    final plans = {
      'Starter': {
        'price': '\$45/month',
        'period': 'Monthly',
        'nextBilling': 'Next month',
        'color': Color(0xFFD97706),
      },
      'Growth': {
        'price': '\$75/month',
        'period': 'Monthly',
        'nextBilling': 'Next month',
        'color': Color(0xFF64748B),
      },
      'Premier': {
        'price': '\$145/month',
        'period': 'Monthly',
        'nextBilling': 'Next month',
        'color': Color(0xFFEAB308),
      },
    };

    return plans[planName] ?? {};
  }

  Widget _buildPlanDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineIcons.creditCard, color: Colors.black54, size: 18),
              const SizedBox(width: 8),
              Text(
                'Billing Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LineIcons.creditCard, color: Colors.blue, size: 20),
            ),
            title: Text(
              'Visa ending in 4242',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Primary payment method',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            trailing: TextButton(
              onPressed: () {
                // Handle payment method update
              },
              child: Text(
                'Update',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LineIcons.fileInvoice, color: Colors.green, size: 20),
            ),
            title: Text(
              'Billing History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'View and download invoices',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            trailing: Icon(LineIcons.arrowRight, size: 16, color: Colors.black54),
            onTap: () {
              // Navigate to billing history
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    return Column(
      children: [
        if (status.toLowerCase() == '*******')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCanceling ? null : _confirmCancelSubscription,
              icon: _isCanceling
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(LineIcons.timesCircle),
              label: _isCanceling
                  ? Text('Cancelling...')
                  : Text('Cancel Subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red[100]!),
                ),
              ),
            ),
          ),
        if (status.toLowerCase() == '*******')
          const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(LineIcons.arrowLeft),
            label: Text('Back to Plans'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Color(0xFF00D4AA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmCancelSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LineIcons.exclamationTriangle, color: Colors.orange),
            SizedBox(width: 12),
            Text('Cancel Subscription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your subscription?',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'You will lose access to premium features at the end of your billing period.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Subscription', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isCanceling = true);

    try {
      // Call your API to cancel subscription
      await Future.delayed(Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCanceling = false);
    }
  }

  void _shareSubscriptionDetails() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}