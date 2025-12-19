import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({Key? key}) : super(key: key);

  @override
  _HelpCenterPageState createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedSubject;
  bool _isLoading = false;

  final List<String> _subjects = [
    'General Inquiry',
    'Technical Support',
    'Billing Issue',
    'Feature Request',
    'Account Management',
    'Privacy Concern',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    if (user != null && user['email'] != null) {
      _emailController.text = user['email'];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendSupportRequest() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider);
      final token = await LocalStorage.getToken();

      if (user == null || token == null) {
        throw Exception('User not authenticated');
      }

      await ApiService.contactSupport(
        token: token,
        email: _emailController.text.trim(),
        userId: user['id'],
        subject: _selectedSubject!,
        message: _messageController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Sent'),
            content: const Text(
              'Thank you for contacting us. We will get back to you shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for clean look
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Browse our FAQs or send us a message.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Frequently Asked Questions'),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'How do I redeem points?',
                    'Navigate to the "Redeem" tab and scan the customer‘s QR code. Once scanned, you can view their points and available rewards. Select a reward to redeem it instantly.',
                  ),
                  _buildFAQItem(
                    'How do I earn points for a customer?',
                    'Go to the "Earn" or "Home" tab, enter the amount spent, and scan the customer‘s QR code. Points are automatically calculated and added to their account.',
                  ),
                  _buildFAQItem(
                    'How do I change my business details?',
                    'Navigate to Settings > Business Profile. Here you can update your logo, banner, address, and contact information.',
                  ),
                  _buildFAQItem(
                    'I forgot my password, what do I do?',
                    'Log out of the application and tap on "Forgot Password?" on the login screen. Follow the instructions to reset your password via email.',
                  ),
                  _buildFAQItem(
                    'Can I manage multiple locations?',
                    'Yes, if you are an OWNER account with a qualifying plan. Go to Settings > Locations to add and manage different branches.',
                  ),
                  _buildFAQItem(
                    'Is the customer data secure?',
                    'Absolutely. We use industry-standard encryption for all data transmission and storage to ensure your business and customer data remains private and secure.',
                  ),

                  const SizedBox(height: 40),
                  _buildSectionTitle('Contact Support'),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Email Address'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            hint: 'Enter your email',
                            icon: LineIcons.envelope,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('Subject'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          icon: const Icon(LineIcons.angleDown),
                          decoration: _inputDecoration(
                            hint: 'Select a topic',
                            icon: LineIcons.tag,
                          ),
                          items: _subjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedSubject = value),
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('Message'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: _inputDecoration(
                            hint: 'Describe your issue or question...',
                            icon: LineIcons.edit,
                            isMultiLine: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendSupportRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF00D4AA,
                              ).withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LineIcons.paperPlane,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Send Message',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isMultiLine = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMultiLine ? 16 : 0,
      ),
      prefixIcon: isMultiLine
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Icon(icon, color: Colors.grey[500]),
            )
          : Icon(icon, color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF00D4AA),
          collapsedIconColor: Colors.grey[400],
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
