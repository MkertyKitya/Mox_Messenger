import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mox_beta/models/svg_icons.dart';

class UserTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool readed;
  final Widget avatar;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatar,
    this.unread = 0,
    this.readed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // ← ВАЖНО!
          children: [
            avatar,

            const SizedBox(width: 14),

            // Левая часть: имя + сообщение
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Правая часть: иконка прочтения + время + непрочитанные
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Иконка прочтения + время в одной строке
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Иконка прочтения (если нет непрочитанных)
                    if (unread == 0)
                      (readed ? SvgIcons.readTrue : SvgIcons.readFalse),

                    if (unread == 0) const SizedBox(width: 6),

                    // Время в светлом прямоугольнике
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Непрочитанные сообщения
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
