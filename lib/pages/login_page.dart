import 'package:mox_beta/models/svg_icons.dart' as icons;
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mox_beta/components/my_button.dart';
import 'package:mox_beta/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

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
      } else if (e.code == 'user-not-found') {
        message = 'Пользователь не найден';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Неверный пароль или почта';
      }

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
    } catch (_) {
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
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Прокручиваемая часть
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  SizedBox(width: 200, height: 200, child: icons.SvgIcons.logo),
                  const SizedBox(height: 50),
                  Text(
                    "Welcome back!",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 25),
                  MyTextField(
                    hintText: "Email",
                    obscureText: false,
                    controller: _emailController,
                    backgroundImage: icons.SvgIcons.loginField1,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    hintText: "Password",
                    obscureText: true,
                    controller: _pwController,
                    backgroundImage: icons.SvgIcons.loginField3,
                  ),
                  const SizedBox(height: 25),
                  MyButton(text: "Login", onTap: login, width: 150, height: 46),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Фиксированный текст снизу
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
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
