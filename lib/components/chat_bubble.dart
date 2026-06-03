import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String type;
  final String? mediaUrl;
  final String? mediaName;
  final DateTime? time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.type = 'text',
    this.mediaUrl,
    this.mediaName,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color bubbleColor = isCurrentUser
        ? Colors.green.shade600
        : theme.colorScheme.tertiary;
    final Color contentColor = isCurrentUser
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);

    // base padding for content
    final EdgeInsets basePadding = type == 'image'
        ? const EdgeInsets.all(6)
        : const EdgeInsets.all(12);

    // if we have time, reserve extra bottom space inside bubble so the badge fits
    final bool hasTime = time != null;
    final EdgeInsets finalPadding = basePadding.copyWith(
      bottom: basePadding.bottom + (hasTime ? 18.0 : 0.0),
    );

    // formatted time string HH:mm
    final String timeText = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : '';

    // bubble max width
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stack so the time badge can be placed inside the bubble
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Bubble background + content
                Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: finalPadding,
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: _buildContent(context, contentColor),
                ),

                // Time badge inside bubble (bottom-right for current user, bottom-left otherwise)
                if (timeText.isNotEmpty)
                  Positioned(
                    right: isCurrentUser ? 8 : null,
                    left: isCurrentUser ? null : 8,
                    bottom: 6,
                    child: _buildTimeBadge(timeText, isCurrentUser),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String timeText, bool isCurrentUser) {
    // Choose badge background and text color to contrast with bubble
    final Color bg = isCurrentUser ? Colors.black26 : Colors.white70;
    final Color textColor = isCurrentUser ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        timeText,
        style: TextStyle(fontSize: 11, color: textColor, height: 1),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color contentColor) {
    switch (type) {
      case 'image':
        return _buildImage(contentColor);
      case 'video':
        return _buildMediaTile(
          context,
          icon: Icons.play_circle_fill,
          label: message.isNotEmpty ? message : (mediaName ?? 'Видео'),
          color: contentColor,
        );
      case 'audio':
        return _buildMediaTile(
          context,
          icon: Icons.mic,
          label: message.isNotEmpty
              ? message
              : (mediaName ?? 'Голосовое сообщение'),
          color: contentColor,
        );
      default:
        return Text(
          message,
          style: TextStyle(color: contentColor, fontSize: 15),
        );
    }
  }

  Widget _buildImage(Color contentColor) {
    if (mediaUrl == null || mediaUrl!.isEmpty) {
      return Text(
        'Изображение недоступно',
        style: TextStyle(color: contentColor),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        mediaUrl!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 220,
            height: 220,
            color: Colors.black12,
            alignment: Alignment.center,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 220,
            height: 220,
            color: Colors.black12,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image, color: contentColor),
          );
        },
      ),
    );
  }

  Widget _buildMediaTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: _openMedia,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMedia() async {
    if (mediaUrl == null || mediaUrl!.isEmpty) return;
    final uri = Uri.tryParse(mediaUrl!);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
