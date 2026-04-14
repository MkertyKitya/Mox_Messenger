import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  final double? width;
  final double? height;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFixedSize = width != null || height != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(80),
        ),
        padding: isFixedSize
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.all(20),
        margin: isFixedSize
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 65),
        child: Center(child: Text(text)),
      ),
    );
  }
}
