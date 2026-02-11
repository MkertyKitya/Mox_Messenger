import 'package:flutter/material.dart';
import 'package:mox_beta/pages/register_page.dart';
import 'package:mox_beta/themes/light_mode.dart';
import 'pages/login_page.dart';
import 'package:mox_beta/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: LoginPage(),
      theme: lightMode,
    );
  }
}
