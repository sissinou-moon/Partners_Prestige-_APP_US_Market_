import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:prestige_partners/app/lib/supabase.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/pages/authentifications/SignUpPage.dart';

import '../../Root.dart';
import '../../app/providers/user_provider.dart';
import '../../app/storage/local_storage.dart';
import '../../styles/styles.dart';
class SignInPage extends ConsumerStatefulWidget  {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isEmailLogin = true;
  bool showPassword = false;

  void SignIn () async {
    final email = emailController.text.trim();

    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.signIn(password: passwordController.text.trim(), isEmail: true, email: emailController.text.trim());

      if(data['user']['role'] != "CASHIER") {
        print("HE IS REALLY AN OWNER OR MANAGER ✅");
        final partnerOf = await PartnerService.getPartnerByOwner(data['user']['id']);

        // SAVE PARTNER
        ref.read(partnerProvider.notifier).state = partnerOf.toJson();
      } else {
        print("HE IS CASHIER WORKER 🎟️💯");
        final partnerANDbranch = await PartnerService.getCashierBranch(data['user']['partner_branch_id']);
        ref.read(partnerProvider.notifier).state = partnerANDbranch;
        print(partnerANDbranch);
      }

      // SAVE TOKEN
      await LocalStorage.setToken(data['token']);

      // SAVE USER
      ref.read(userProvider.notifier).state = data['user'];

      // NAVIGATE TO HOME
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootLayout()),
        );
      }

    } catch (err) {
      final msg = err.toString();

      // 🔥 حالة عدم التحقق

      // أي خطأ آخر
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Image.asset(
                  'assets/prestige_logo.png',
                  width: 90,
                  height: 30,
                ),

                const SizedBox(height: 40),

                const Text(
                  "Welcome Back!",
                  style: AppStyles.title,
                ),

                const SizedBox(height: 8),

                const Text(
                  "We are excited to see you again",
                  textAlign: TextAlign.center,
                  style: AppStyles.description,
                ),

                const SizedBox(height: 40),

                // Toggle
                Container(
                  width: width * 0.6,
                  decoration: AppStyles.toggleContainer,
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isEmailLogin = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 35),
                          decoration: isEmailLogin
                              ? AppStyles.toggleActive
                              : const BoxDecoration(color: Colors.transparent),
                          child: const Text(
                            "Email",
                            style: AppStyles.subTitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isEmailLogin = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 35),
                          decoration: !isEmailLogin
                              ? AppStyles.toggleActive
                              : const BoxDecoration(color: Colors.transparent),
                          child: const Text(
                            "Phone",
                            style: AppStyles.subTitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Email/Phone input
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
                            const Text(
                              "🇺🇸",
                              style: TextStyle(fontSize: 20),
                            ),
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
                              controller: isEmailLogin ? emailController : phoneController,
                              keyboardType: isEmailLogin
                                  ? TextInputType.emailAddress
                                  : TextInputType.phone,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15)
                                    .copyWith(bottom: 5),
                                border: InputBorder.none,
                                hintText: isEmailLogin ? "johan@gmail.com" : "983 728 1234",
                                hintStyle: AppStyles.hintText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Password input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Password",
                      style: AppStyles.inputTitle,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 43,
                      decoration: AppStyles.input,
                      child: TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15)
                              .copyWith(top: 7),
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

                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      // Handle forgot password
                    },
                    child: Text(
                      "Forgot password?",
                      style: AppStyles.textButton,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Continue Button
                GestureDetector(
                  onTap: isLoading ? null : () {
                      SignIn();
                  },
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

                const SizedBox(height: 5),

                // Signup
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "You don't have an account? SignUp",
                      style: AppStyles.textButton,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 1,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    const Text("Or", style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 10),
                    Container(
                      width: 90,
                      height: 1,
                      color: Colors.black,
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Google & Facebook
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: const Color(0x30000000), width: 0.7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/google.png",
                                height: 20, width: 25),
                            const SizedBox(width: 6),
                            const Text(
                              "Google",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: const Color(0x30000000), width: 0.7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/facebook_logo.png",
                                height: 20, width: 25),
                            const SizedBox(width: 6),
                            const Text(
                              "Facebook",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
}