import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String type;
  final String? mediaUrl;
  final String? mediaName;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.type = 'text',
    this.mediaUrl,
    this.mediaName,
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

    final EdgeInsets padding = type == 'image'
        ? const EdgeInsets.all(6)
        : const EdgeInsets.all(16);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: padding,
        margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
        child: _buildContent(context, contentColor),
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
        return Text(message, style: TextStyle(color: contentColor));
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
