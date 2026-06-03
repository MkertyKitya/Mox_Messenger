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

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: finalHeight,
      fit: fit,
      placeholderBuilder: placeholder != null ? (context) => placeholder : null,
    );
  }

  // ----------------- Геттеры для иконок (использовать без скобок) -----------------

  static Widget get readTrue =>
      instance.iconWidget('assets/svg/ReadTrue.svg', width: 16, height: 16);

  static Widget get readFalse =>
      instance.iconWidget('assets/svg/ReadFalse.svg', width: 16, height: 16);

  static Widget get onlineTrue =>
      instance.iconWidget('assets/svg/OnlineTrue.svg', height: 28);

  static Widget get onlineFalse =>
      instance.iconWidget('assets/svg/OnlineFalse.svg', height: 28);

  static Widget get backButton =>
      instance.iconWidget('assets/svg/back_button.svg', width: 24, height: 24);

  static Widget get callButton =>
      instance.iconWidget('assets/svg/call_button.svg', width: 24, height: 24);

  static Widget get lineInChat => instance.iconWidget(
    'assets/svg/line_in_chat_room.svg',
    width: double.infinity,
    height: 2,
    fit: BoxFit.cover,
  );

  static Widget get menuButton => instance.iconWidget(
    'assets/svg/Menu_Button.svg',
    width: 24,
    height: 24,
    placeholder: const Icon(Icons.menu),
  );

  static Widget get searchButton => instance.iconWidget(
    'assets/svg/Search.svg',
    width: 24,
    height: 24,
    placeholder: const Icon(Icons.search),
  );

  static Widget get lineHome => instance.iconWidget(
    'assets/svg/Line.svg',
    width: double.infinity,
    height: 2,
    fit: BoxFit.cover,
    placeholder: const SizedBox(height: 2),
  );
}
