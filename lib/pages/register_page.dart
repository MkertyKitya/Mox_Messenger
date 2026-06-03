import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mox_beta/models/svg_icons.dart' as icons;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Пароли не совпадают',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      await auth.signUpWithEmailPassword(
        _emailController.text.trim(),
        _pwController.text,
        _nickController.text.trim(),
      );

      // Нет необходимости делать .pop() здесь, AuthGate автоматом перебросит,
      // если только это не было модальным окном.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Ошибка регистрации';
      if (e.code == 'weak-password') {
        message = 'Слишком слабый пароль';
      } else if (e.code == 'email-already-in-use')
        message = 'Почта уже используется';
      else if (e.code == 'invalid-email')
        message = 'Некорректный формат почты';

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
    _confirmPwController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Прокручиваемая часть
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboardOpen ? 0 : 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  // PNG логотип
                  SizedBox(width: 200, height: 200, child: icons.SvgIcons.logo),

                  const SizedBox(height: 50),

                  Text(
                    "Let's create an account for you!",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Nickname
                  MyTextField(
                    hintText: "Nick name",
                    obscureText: false,
                    controller: _nickController,
                    backgroundImage: icons.SvgIcons.loginField1,
                  ),

                  const SizedBox(height: 10),

                  // Email
                  MyTextField(
                    hintText: "Email",
                    obscureText: false,
                    controller: _emailController,
                    backgroundImage: icons.SvgIcons.loginField1,
                  ),

                  const SizedBox(height: 10),

                  // Password
                  MyTextField(
                    hintText: "Password",
                    obscureText: true,
                    controller: _pwController,
                    backgroundImage: icons.SvgIcons.loginField3,
                  ),

                  const SizedBox(height: 10),

                  // Confirm password
                  MyTextField(
                    hintText: "Confirm password",
                    obscureText: true,
                    controller: _confirmPwController,
                    backgroundImage: icons.SvgIcons.loginField3,
                  ),

                  const SizedBox(height: 25),

                  MyButton(
                    text: "Register",
                    onTap: register,
                    width: 150,
                    height: 46,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Нижний текст — скрывается при клавиатуре
          if (!keyboardOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
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
                        recognizer: TapGestureRecognizer()
                          ..onTap = widget.onTap,
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
