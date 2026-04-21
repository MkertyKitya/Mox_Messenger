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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            //если svg background передан
            if (backgroundSvg != null)
              SizedBox(
                width: 320,
                height: 70,
                child: SvgPicture.asset(backgroundSvg!, fit: BoxFit.contain),
              ),

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
                  //enabledBorder: OutlineInputBorder(
                  //borderSide: BorderSide(
                  //  color: Theme.of(context).colorScheme.tertiary,
                  //),
                  //),
                  //focusedBorder: OutlineInputBorder(
                  // borderSide: BorderSide(
                  // color: Theme.of(context).colorScheme.onPrimary,
                  //),
                  // ),
                  //fillColor: Theme.of(context).colorScheme.primary,
                  //filled: true,
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
