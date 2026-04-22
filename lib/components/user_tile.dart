import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final Widget? avatar;

  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          //color: Theme.of(context).colorScheme.secondary,
          //borderRadius: BorderRadius.circular(12),
        ),
        //margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            // icon
            avatar ?? const Icon(Icons.person),
            const SizedBox(width: 20),
            // user name
            Text(text),
          ],
        ),
      ),
    );
  }
}
