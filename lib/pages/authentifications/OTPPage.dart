import 'package:flutter/material.dart';
import 'package:prestige_partners/app/lib/auth.dart';

import 'SignInPage.dart';

class OTPPage extends StatefulWidget {
  final String? email;
  final bool? isEmail;
  final String? phone;

  const OTPPage({
    super.key,
    this.email,
    this.isEmail,
    this.phone,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final List<TextEditingController> _controllers =
  List.generate(6, (index) => TextEditingController());

  bool _loading = false;
  int _seconds = 45;
  late final _focusNodes =
  List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    print(widget.phone?.length); // crash if email is null
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (_seconds == 0) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _seconds--;
        });
      }
      return true;
    });
  }

  void _onOtpChange(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get code {
    return _controllers.map((c) => c.text).join();
  }

  void _resendOTP() async {
  }

  void _submit() async {
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 6-digit code")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔹 Call OTP verify API
      await ApiService.verifyEmailOTP(email: widget.email!, otp: code);
      // 🔹 Go to home page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInPage()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your account is successfully verified , Log in to access to your account!")),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.isEmail == true ? widget.email : widget.phone;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustration
                Image.asset(
                  "assets/prestige_logo.png",
                  height: 45,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Verify Your Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the 6-digit code sent to\n$contact",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0x70000000),
                  ),
                ),

                const SizedBox(height: 35),

                // OTP fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 45,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x30000000),
                          width: 0.9,
                        ),
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        onChanged: (v) => _onOtpChange(v, index),
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // Continue button
                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: AnimatedOpacity(
                    opacity: _loading ? 0.6 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004F54),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Verify",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Resend section
                TextButton(
                  onPressed: _seconds == 0 ? () {
                    _resendOTP();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Your New code has been resend!")),
                    );
                  } : null,
                  child: Text(
                    _seconds == 0
                        ? "Resend Code"
                        : "Resend in $_seconds s",
                    style: TextStyle(
                      fontSize: 14,
                      color: _seconds == 0
                          ? const Color(0xFF004F54)
                          : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
