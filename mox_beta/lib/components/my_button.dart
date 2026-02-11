import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;

  const MyButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(80),
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 65),
        child: Center(child: Text(text)),
      ),
    );
  }
}
