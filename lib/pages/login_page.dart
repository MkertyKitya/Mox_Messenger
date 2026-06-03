import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mox_beta/components/my_button.dart';
import 'package:mox_beta/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatefulWidget {
  // tap to go to register page
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // email and passwd text controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  // login method
  Future<void> login() async {
    final authService = AuthService();

    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _pwController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Произошла ошибка авторизации';
      if (e.code == 'invalid-email') {
        message = 'Некорректный формат почты';
      } else if (e.code == 'user-not-found')
        message = 'Пользователь не найден';
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential')
        message = 'Неверный пароль или почта';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Неизвестная ошибка',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
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
                  "Welcome back!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 25),

                // email textfield
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                  backgroundSvg: 'assets/svg/Login_or_Register1.svg',
                ),

                const SizedBox(height: 10),

                // pw textfield
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: _pwController,
                  backgroundSvg: 'assets/svg/Login_or_Register3.svg',
                ),

                const SizedBox(height: 25),
                // login button
                MyButton(text: "Login", onTap: login, width: 150, height: 46),

                const SizedBox(height: 25),
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: RichText(
                text: TextSpan(
                  text: "Not a member? ",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  children: [
                    TextSpan(
                      text: "Register now!",
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
