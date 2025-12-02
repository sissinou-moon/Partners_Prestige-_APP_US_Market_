import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';
import '../app/lib/stripe.dart';
import '../app/providers/subscription_provider.dart';
import '../pages/Settings/SubscriptionDetailsPage.dart';

class SubscriptionBottomSheet extends ConsumerStatefulWidget {
  final String planId;
  final String planName;
  final String price;
  final SubscriptionService subscriptionService;
  final String partnerEmail;
  final String token;

  const SubscriptionBottomSheet({
    required this.planId,
    required this.planName,
    required this.price,
    required this.subscriptionService,
    required this.partnerEmail,
    required this.token,
    super.key,
  });

  @override
  ConsumerState<SubscriptionBottomSheet> createState() => _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends ConsumerState<SubscriptionBottomSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGooglePay(Map<String, dynamic> user) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscriptionResult = await directStripeSubscription().makePayment(
          user,
          widget.planName,
          widget.token,
          widget.price
      );

      if (subscriptionResult != null) {
        // Save to provider (which will also cache it)
        await ref.read(subscriptionProvider.notifier).setSubscription(subscriptionResult);

        Navigator.pop(context, true);
        _showSuccessDialog();
      } else {
        setState(() {
          _error = 'Payment failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApplePay() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create payment intent
      final paymentData = await widget.subscriptionService
          .createPaymentIntent(widget.planId);

      // Initialize payment sheet with Apple Pay
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Your App Name',
          customerId: paymentData['customer_id'],
          customerEphemeralKeySecret: paymentData['ephemeral_key'],
          setupIntentClientSecret: paymentData['client_secret'],
          applePay: PaymentSheetApplePay(
            merchantCountryCode: 'US',
          ),
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Get payment method ID
      final setupIntent = await Stripe.instance.retrieveSetupIntent(
        paymentData['client_secret'],
      );

      if (setupIntent.paymentMethodId != null) {
        // Confirm subscription
        final result = await widget.subscriptionService.confirmSubscription(
          widget.planId,
          setupIntent.paymentMethodId!,
        );

        if (result['success'] == true) {
          Navigator.pop(context, true);
          _showSuccessDialog();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCardPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create payment intent
      final paymentData = await widget.subscriptionService
          .createPaymentIntent(widget.planId);

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Your App Name',
          customerId: paymentData['customer_id'],
          customerEphemeralKeySecret: paymentData['ephemeral_key'],
          setupIntentClientSecret: paymentData['client_secret'],
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Get payment method ID
      final setupIntent = await Stripe.instance.retrieveSetupIntent(
        paymentData['client_secret'],
      );

      if (setupIntent.paymentMethodId != null) {
        // Confirm subscription
        final result = await widget.subscriptionService.confirmSubscription(
          widget.planId,
          setupIntent.paymentMethodId!,
        );

        if (result['success'] == true) {
          Navigator.pop(context, true);
          _showSuccessDialog();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success!'),
        content: Text('Your subscription has been activated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = ref.read(userProvider);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subscribe to ${widget.planName}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            widget.planName,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          if (_error != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),

          // Google Pay Button
          if (Theme.of(context).platform == TargetPlatform.android)
            Consumer(
              builder: (context, ref, child) {
                final subscription = ref.watch(subscriptionProvider);

                // If subscription exists, show different button
                if (subscription != null && subscription.plan == widget.planName) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to subscription details page
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionDetailsPage(
                            subscriptionData: subscription.toJSON(),
                            planName: widget.planName,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.done, color: Colors.green),
                    label: Text('View Subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                      foregroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                }

                // Show regular payment button
                return ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    _handleGooglePay(user!);
                  },
                  icon: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(Icons.payment),
                  label: _isLoading
                      ? Text('Processing...')
                      : Text('Pay with Google Pay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              },
            ),

          // Apple Pay Button
          if (Theme.of(context).platform == TargetPlatform.iOS)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleApplePay,
              icon: Icon(Icons.apple),
              label: Text('Pay with Apple Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

          SizedBox(height: 12),

          // Card Payment Button
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleCardPayment,
            icon: Icon(Icons.credit_card),
            label: Text('Pay with Card'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),

          SizedBox(height: 16),
          Text(
            'Cancel anytime. Secure payment powered by Stripe.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}