// lib/models/svg_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SvgIcons manager — безопасная и совместимая версия
/// - НЕ кеширует экземпляры Widget (чтобы избежать reparenting)
/// - кеширует только факт "загружено" (loaded keys)
/// - возвращает стабильный контейнер (_SvgIconHolder), который обновляет внутренний child
/// - все уведомления об обновлении откладываются на следующий кадр, чтобы избежать setState во время build
class SvgIcons extends ChangeNotifier {
  SvgIcons._internal();
  static final SvgIcons instance = SvgIcons._internal();

  final Set<String> _loadedKeys = {};
  final Set<String> _loading = {};

  String _key(String path, double? w, double? h, BoxFit fit) =>
      '$path|w:${w ?? "n"}|h:${h ?? "n"}|fit:${fit.index}';

  /// Проверка, помечен ли ключ как загруженный
  bool hasLoaded(String key) => _loadedKeys.contains(key);

  /// Пометка ключа как загруженного (без кеширования виджета).
  /// notifyListeners вызывается отложенно через addPostFrameCallback.
  Future<void> preload(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool force = false,
  }) async {
    final key = _key(assetPath, width, height, fit);
    if (_loadedKeys.contains(key) && !force) return;
    if (_loading.contains(key)) return;

    _loading.add(key);
    try {
      // Создаём локальный SvgPicture, чтобы flutter_svg начал подготовку (парсинг).
      // Мы не сохраняем этот экземпляр глобально.
      SvgPicture.asset(assetPath, width: width, height: height, fit: fit);

      // Помечаем как загруженное и откладываем уведомление слушателей на следующий кадр.
      _loadedKeys.add(key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_loadedKeys.contains(key)) {
          try {
            notifyListeners();
          } catch (_) {
            // защитный catch — если слушатели уже удалены или произошла другая ошибка
          }
        }
      });
    } catch (e) {
      // Игнорируем ошибки при подготовке; fallback покажет placeholder.
    } finally {
      _loading.remove(key);
    }
  }

  /// Возвращает стабильный контейнер (_SvgIconHolder).
  /// Не даёт ключа holder'у (чтобы избежать reparenting).
  Widget iconWidget(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
  }) {
    final key = _key(assetPath, width, height, fit);

    final initialChild = hasLoaded(key)
        ? SvgPicture.asset(assetPath, width: width, height: height, fit: fit)
        : (placeholder ?? SizedBox(width: width ?? 24, height: height ?? 24));

    return _SvgIconHolder(
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      initialChild: initialChild,
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

/// Stateful wrapper that keeps the same RenderObject parent in the tree.
/// It updates its inner child when SvgIcons notifies that the icon is ready.
class _SvgIconHolder extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? initialChild;

  const _SvgIconHolder({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.initialChild,
  });

  @override
  State<_SvgIconHolder> createState() => _SvgIconHolderState();
}

class _SvgIconHolderState extends State<_SvgIconHolder> {
  late Widget _child;
  late final String _keyStr;

  @override
  void initState() {
    super.initState();
    _keyStr = SvgIcons.instance._key(
      widget.assetPath,
      widget.width,
      widget.height,
      widget.fit,
    );
    _child =
        widget.initialChild ??
        widget.placeholder ??
        SizedBox(width: widget.width ?? 24, height: widget.height ?? 24);

    // Подписываемся до вызова preload, чтобы не пропустить уведомление.
    SvgIcons.instance.addListener(_onIconsUpdated);

    if (!SvgIcons.instance.hasLoaded(_keyStr)) {
      // fire-and-forget
      SvgIcons.instance.preload(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
  }

  @override
  void dispose() {
    SvgIcons.instance.removeListener(_onIconsUpdated);
    super.dispose();
  }

  void _onIconsUpdated() {
    if (!mounted) return;
    if (!SvgIcons.instance.hasLoaded(_keyStr)) return;

    // Всегда откладываем обновление на следующий кадр — безопасно в любой фазе.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!SvgIcons.instance.hasLoaded(_keyStr)) return;

      // Создаём НОВЫЙ экземпляр SvgPicture.asset локально (не общий).
      setState(() {
        // Если высота не задана и ширина бесконечна (например, линия), ставим разумную высоту.
        final double finalHeight =
            widget.height ?? (widget.width == double.infinity ? 2.0 : 24.0);

        _child = SvgPicture.asset(
          widget.assetPath,
          width: widget.width,
          height: finalHeight,
          fit: widget.fit,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Гарантируем конечную высоту контейнера — если height не задана, ставим 24 (или 2 для "линий")
    final double finalHeight =
        widget.height ?? (widget.width == double.infinity ? 2.0 : 24.0);

    return SizedBox(width: widget.width, height: finalHeight, child: _child);
  }
}
