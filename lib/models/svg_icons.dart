import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcons {
  static final Map<String, Widget> _cache = {};

  static Widget _load(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    final key = '$path-$width-$height-$fit';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final widget = FutureBuilder<String>(
      future: rootBundle.loadString(path).then((raw) {
        return raw
            .replaceAll(RegExp(r'<filter[\s\S]*?<\/filter>'), '')
            .replaceAll(RegExp(r'<filter[^>]*\/>'), '')
            .replaceAll(RegExp(r'<feGaussianBlur[\s\S]*?\/>'), '')
            .replaceAll(RegExp(r'<feDropShadow[\s\S]*?\/>'), '')
            .replaceAll(RegExp(r'<feColorMatrix[\s\S]*?\/>'), '')
            .replaceAll(RegExp(r'<feBlend[\s\S]*?\/>'), '')
            .replaceAll(RegExp(r'<feOffset[\s\S]*?\/>'), '');
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: width, height: height);
        }

        return SvgPicture.string(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );

    _cache[key] = widget;
    return widget;
  }

  // ---------------- EXISTING ICONS ----------------

  static final readTrue = _load(
    'assets/svg/ReadTrue.svg',
    width: 16,
    height: 16,
  );

  static final readFalse = _load(
    'assets/svg/ReadFalse.svg',
    width: 16,
    height: 16,
  );

  static final onlineTrue = _load('assets/svg/OnlineTrue.svg', height: 28);

  static final onlineFalse = _load('assets/svg/OnlineFalse.svg', height: 28);

  static final backButton = _load(
    'assets/svg/back_button.svg',
    width: 24,
    height: 24,
  );

  static final callButton = _load(
    'assets/svg/call_button.svg',
    width: 24,
    height: 24,
  );

  static final lineInChat = _load(
    'assets/svg/line_in_chat_room.svg',
    width: double.infinity,
  );

  // ---------------- NEW ICONS FOR HOMEPAGE ----------------

  static final menuButton = _load(
    'assets/svg/Menu_Button.svg',
    width: 24,
    height: 24,
  );

  static final searchButton = _load(
    'assets/svg/Search.svg',
    width: 24,
    height: 24,
  );

  static final lineHome = _load(
    'assets/svg/Line.svg',
    width: double.infinity,
    height: 2,
    fit: BoxFit.cover,
  );
}
