import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/components/my_button.dart';
import 'package:mox_beta/components/my_textfield.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  // tap to go to login page
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // email and passwd text controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();

  // register method
  Future<void> register() async {
    final auth = AuthService();

    if (_pwController.text != _confirmPwController.text) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) =>
            const AlertDialog(title: Text("Password don't match!")),
      );
      return;
    }

    try {
      await auth.signUpWithEmailPassword(
        _emailController.text.trim(),
        _pwController.text,
        _nickController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo
                SvgPicture.asset(
                  'assets/svg/Logo.svg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 50),

                // welcome back message
                Text(
                  "Let's create an accout for you!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 25),

                // nickname
                MyTextField(
                  hintText: "Nick name",
                  obscureText: false,
                  controller: _nickController,
                  backgroundSvg: 'assets/svg/Login_or_Register1.svg',
                ),

                const SizedBox(height: 10),
                // email textfield
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                  backgroundSvg: 'assets/svg/Login_or_Register2.svg',
                ),

                const SizedBox(height: 10),

                // pw textfield
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: _pwController,
                  backgroundSvg: 'assets/svg/Login_or_Register3.svg',
                ),

                const SizedBox(height: 10),

                // confirm pw textfield
                MyTextField(
                  hintText: "Confirm password",
                  obscureText: true,
                  controller: _confirmPwController,
                  backgroundSvg: 'assets/svg/Login_or_Register3.svg',
                ),

                const SizedBox(height: 25),
                // Register button
                MyButton(
                  text: "Register",
                  onTap: register,
                  width: 150,
                  height: 46,
                ),

                const SizedBox(height: 25),

                // register now
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  children: [
                    TextSpan(
                      text: "Login now!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = widget.onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
