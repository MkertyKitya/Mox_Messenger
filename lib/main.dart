import 'package:flutter/material.dart';
import 'package:mox_beta/services/auth/auth_gate.dart';
import 'package:mox_beta/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mox_beta/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mox_beta/models/svg_icons.dart'; // <- импорт для preload

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SvgIcons.instance.preload(
      'assets/svg/Menu_Button.svg',
      width: 24,
      height: 24,
    );
    SvgIcons.instance.preload('assets/svg/Search.svg', width: 24, height: 24);
    SvgIcons.instance.preload(
      'assets/svg/Line.svg',
      width: double.infinity,
      height: 2,
      fit: BoxFit.cover,
    );
    SvgIcons.instance.preload('assets/svg/ReadTrue.svg', width: 16, height: 16);
    SvgIcons.instance.preload(
      'assets/svg/ReadFalse.svg',
      width: 16,
      height: 16,
    );
    SvgIcons.instance.preload('assets/svg/OnlineTrue.svg', height: 28);
    SvgIcons.instance.preload('assets/svg/OnlineFalse.svg', height: 28);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
