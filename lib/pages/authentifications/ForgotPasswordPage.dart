import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../styles/styles.dart';

import 'package:prestige_partners/app/lib/auth.dart';
import 'OTPPage.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  bool isEmailLogin = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/prestige_logo.png', width: 90, height: 30),

                const SizedBox(height: 40),

                const Text("Forgot Password", style: AppStyles.title),

                const SizedBox(height: 8),

                const Text(
                  "Enter your email to reset your password",
                  textAlign: TextAlign.center,
                  style: AppStyles.description,
                ),

                const SizedBox(height: 40),

                // Toggle
                //Container(
                //  width: width * 0.6,
                //  decoration: AppStyles.toggleContainer,
                //  padding: const EdgeInsets.all(4),
                //  child: Row(
                //    mainAxisAlignment: MainAxisAlignment.center,
                //    children: [
                //      GestureDetector(
                //        onTap: () {
                //          setState(() {
                //            isEmailLogin = true;
                //          });
                //        },
                //        child: Container(
                //          padding: const EdgeInsets.symmetric(
                //            vertical: 10,
                //            horizontal: 35,
                //          ),
                //          decoration: isEmailLogin
                //              ? AppStyles.toggleActive
                //              : const BoxDecoration(color: Colors.transparent),
                //          child: const Text("Email", style: AppStyles.subTitle),
                //        ),
                //      ),
                //      const SizedBox(width: 10),
                //      GestureDetector(
                //        onTap: () {
                //          setState(() {
                //            isEmailLogin = false;
                //          });
                //        },
                //        child: Container(
                //          padding: const EdgeInsets.symmetric(
                //            vertical: 10,
                //            horizontal: 35,
                //          ),
                //          decoration: !isEmailLogin
                //              ? AppStyles.toggleActive
                //              : const BoxDecoration(color: Colors.transparent),
                //          child: const Text("Phone", style: AppStyles.subTitle),
                //        ),
                //      ),
                //    ],
                //  ),
                //),
                //
                //const SizedBox(height: 30),

                // Email/Phone input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmailLogin ? "Email" : "Phone",
                      style: AppStyles.inputTitle,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 43,
                      decoration: AppStyles.input,
                      child: Row(
                        children: [
                          // Show flag and +1 only for phone input
                          if (!isEmailLogin) ...[
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
                            Container(
                              width: 1,
                              height: 25,
                              color: const Color(0x30000000),
                            ),
                          ],
                          Expanded(
                            child: TextField(
                              controller: isEmailLogin
                                  ? emailController
                                  : phoneController,
                              keyboardType: isEmailLogin
                                  ? TextInputType.emailAddress
                                  : TextInputType.phone,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ).copyWith(bottom: 5),
                                border: InputBorder.none,
                                hintText: isEmailLogin
                                    ? "johan@gmail.com"
                                    : "983 728 1234",
                                hintStyle: AppStyles.hintText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Continue Button
                GestureDetector(
                  onTap: isLoading ? null : _handleContinue,
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
                          : const Text(
                              "Continue",
                              style: AppStyles.buttonContent,
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Back to Login
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Back to Login",
                    style: AppStyles.textButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final email = isEmailLogin
        ? emailController.text.trim()
        : phoneController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email or phone number"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.sendPasswordResetOTP(
        isEmail: isEmailLogin,
        email: isEmailLogin ? email : null,
        phone: isEmailLogin ? null : "+1$email",
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPPage(
              email: isEmailLogin ? email : null,
              phone: isEmailLogin ? null : "+1$email",
              isEmail: isEmailLogin,
              forResetPassword: true,
            ),
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.toString())));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
