import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'SignInPage.dart';
import '../../styles/styles.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String? phone;
  final bool isEmail;

  const ResetPasswordPage({
    super.key,
    required this.email,
    this.phone,
    required this.isEmail,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

                const Text("Reset Password", style: AppStyles.title),

                const SizedBox(height: 8),

                const Text(
                  "Enter your new password",
                  textAlign: TextAlign.center,
                  style: AppStyles.description,
                ),

                const SizedBox(height: 40),

                // New Password input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("New Password", style: AppStyles.inputTitle),
                    const SizedBox(height: 6),
                    Container(
                      height: 43,
                      decoration: AppStyles.input,
                      child: TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ).copyWith(top: 7),
                          border: InputBorder.none,
                          hintText: "•••••••••••",
                          hintStyle: AppStyles.hintText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Confirm Password input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Confirm Password", style: AppStyles.inputTitle),
                    const SizedBox(height: 6),
                    Container(
                      height: 43,
                      decoration: AppStyles.input,
                      child: TextField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ).copyWith(top: 7),
                          border: InputBorder.none,
                          hintText: "•••••••••••",
                          hintStyle: AppStyles.hintText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Password validation items
                _buildCheckItem(
                  "At least 6 characters",
                  passwordController.text.length >= 6,
                ),
                _buildCheckItem(
                  "Contains a letter",
                  RegExp(r'[a-zA-Z]').hasMatch(passwordController.text),
                ),
                _buildCheckItem(
                  "Contains a capital letter",
                  RegExp(r'[A-Z]').hasMatch(passwordController.text),
                ),
                _buildCheckItem(
                  "Contains a number",
                  RegExp(r'[0-9]').hasMatch(passwordController.text),
                ),
                _buildCheckItem(
                  "Contains a special character",
                  RegExp(
                    r'[!@#\$%\^&\*\(\)\-\+\=_\.,;:{}\[\]]',
                  ).hasMatch(passwordController.text),
                ),
                _buildCheckItem(
                  "Passwords match",
                  passwordController.text.isNotEmpty &&
                      passwordController.text == confirmPasswordController.text,
                ),

                const SizedBox(height: 40),

                // Reset Password Button
                GestureDetector(
                  onTap: isLoading ? null : _handleResetPassword,
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
                              "Reset Password",
                              style: AppStyles.buttonContent,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Future<void> _handleResetPassword() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    // Password validation
    final bool hasMinLength = password.length >= 6;
    final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final bool hasCapital = RegExp(r'[A-Z]').hasMatch(password);
    final bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final bool hasSpecial = RegExp(
      r'[!@#\$%\^&\*\(\)\-\+\=_\.,;:{}\[\]]',
    ).hasMatch(password);

    if (!hasMinLength ||
        !hasLetter ||
        !hasCapital ||
        !hasNumber ||
        !hasSpecial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password does not meet all requirements"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.resetPassword(widget.email, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset successfully! Please login."),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
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
