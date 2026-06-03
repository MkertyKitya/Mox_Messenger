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

  /// СТАРЫЙ параметр — SVG фон (оставляем для совместимости)
  final String? backgroundSvg;

  /// НОВЫЙ параметр — PNG фон (Widget)
  final Widget? backgroundImage;

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
    this.backgroundImage, // ← добавили
  });

  // Кэш SVG
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
    final bgSvg = _getCachedSvg(backgroundSvg);

    return Center(
      child: SizedBox(
        width: 320,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// 1. PNG фон (если есть)
            if (backgroundImage != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 320,
                    height: 70,
                    child: backgroundImage,
                  ),
                ),
              ),

            /// 2. SVG фон (если PNG нет)
            if (backgroundImage == null && bgSvg != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: 320, height: 70, child: bgSvg),
                ),
              ),

            /// 3. Само поле ввода
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
