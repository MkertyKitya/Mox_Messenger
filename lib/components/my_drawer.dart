import 'package:flutter/material.dart';
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/pages/setting_page.dart';
import 'package:mox_beta/pages/login_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // ЛОГИКА logout — внутри build, чтобы иметь доступ к context
    Future<void> logout() async {
      final auth = AuthService();

      // 1. Закрываем Drawer
      Navigator.of(context).pop();

      // 2. Выходим из аккаунта
      await auth.signOut();

      if (!context.mounted) return;

      // 3. Переходим на LoginPage с обязательным параметром onTap
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onTap: () {
              // переход на регистрацию (если есть RegisterPage)
              // если нет — оставляем пустым
            },
          ),
        ),
        (route) => false,
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Icon(
                    Icons.message,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
              ),

              // HOME
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: ListTile(
                  title: const Text("H O M E"),
                  leading: const Icon(Icons.home),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              // SETTINGS
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: ListTile(
                  title: const Text("S E T T I N G S"),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // LOGOUT
          Padding(
            padding: const EdgeInsets.only(left: 5.0, bottom: 5.0),
            child: ListTile(
              title: const Text("L O G   O U T"),
              leading: const Icon(Icons.logout),
              onTap: logout,
            ),
          ),
        ],
      ),
    );
  }
}
