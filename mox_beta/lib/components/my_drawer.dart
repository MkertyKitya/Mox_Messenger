import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // logo
          DrawerHeader(
            child: Center(child: Icon(Icons.message)),
            // DrawerHeader
            // home list tile
            //settings list tile
            // logout list tile
          ),
        ],
      ),
    );
  }
}
