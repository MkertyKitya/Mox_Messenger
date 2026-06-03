// lib/models/svg_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SvgIcons manager
class SvgIcons {
  static final SvgIcons instance = SvgIcons._internal();
  SvgIcons._internal();

  /// Возвращает виджет иконки.
  /// flutter_svg самостоятельно кеширует распарсенные данные.
  Widget iconWidget(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
  }) {
    // Если высота не задана и ширина "бесконечна" (например, линия), ставим высоту по умолчанию
    final double? finalHeight =
        height ?? (width == double.infinity ? 2.0 : null);

    final bool isSvg = assetPath.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: finalHeight,
        fit: fit,
        placeholderBuilder: placeholder != null
            ? (context) => placeholder
            : null,
      );
    } else {
      return Image.asset(
        assetPath,
        width: width,
        height: finalHeight,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      );
    }
  }

  // ----------------- Геттеры для иконок (использовать без скобок) -----------------

  static Widget get readTrue =>
      instance.iconWidget('assets/images/ReadTrue.png', width: 16, height: 16);

  static Widget get readFalse =>
      instance.iconWidget('assets/images/ReadFalse.png', width: 16, height: 16);

  static Widget get onlineTrue =>
      instance.iconWidget('assets/images/OnlineTrue.png', height: 28);

  static Widget get onlineFalse =>
      instance.iconWidget('assets/images/OnlineFalse.png', height: 28);

  static Widget get backButton => instance.iconWidget(
    'assets/images/back_button.png',
    width: 24,
    height: 24,
  );

  static Widget get callButton => instance.iconWidget(
    'assets/images/call_button.png',
    width: 24,
    height: 24,
  );

  static Widget get lineInChat => instance.iconWidget(
    'assets/images/line_in_chat_room.png',
    width: double.infinity,
    height: 2,
    fit: BoxFit.cover,
  );

  static Widget get menuButton => instance.iconWidget(
    'assets/images/Menu_Button.png',
    width: 24,
    height: 24,
    placeholder: const Icon(Icons.menu),
  );

  static Widget get searchButton => instance.iconWidget(
    'assets/images/Search.png',
    width: 24,
    height: 24,
    placeholder: const Icon(Icons.search),
  );

  static Widget get lineHome => instance.iconWidget(
    'assets/images/Line.png',
    width: double.infinity,
    height: 2,
    fit: BoxFit.cover,
    placeholder: const SizedBox(height: 2),
  );
}
