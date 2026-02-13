import 'package:flutter/material.dart';
import 'package:mox_beta/auth/auth_service.dart';
import 'package:mox_beta/components/my_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout() {
    //get auth service
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          // logout button
          IconButton(onPressed: logout, icon: Icon(Icons.logout)),
        ],
      ),
      drawer: MyDrawer(),
    );
  }
}
