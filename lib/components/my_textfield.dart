import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final String? backgroundSvg;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.backgroundSvg,
  });

  //оптимизация
  static final Map<String, Widget> _svgCache = {};

  Widget? _getCachedSvg(String? path) {
    if (path == null) return null;
    return _svgCache.putIfAbsent(
      path,
      () => SvgPicture.asset(path, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _getCachedSvg(backgroundSvg);

    return Center(
      child: SizedBox(
        width: 320,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (bg != null) SizedBox(width: 320, height: 70, child: bg),

            Positioned.fill(
              child: TextField(
                cursorColor: Theme.of(context).colorScheme.onPrimary,
                obscureText: obscureText,
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                decoration: InputDecoration(
                  prefixIcon: prefixIcon,
                  suffixIcon: suffixIcon,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
