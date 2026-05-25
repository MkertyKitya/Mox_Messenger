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
    final bubbleColor = isCurrentUser
        ? Colors.green.shade600
        : theme.colorScheme.tertiary;
    final contentColor = isCurrentUser
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);

    final content = _buildContent(context, isDarkMode, contentColor);
    final padding = type == 'image'
        ? const EdgeInsets.all(6)
        : const EdgeInsets.all(16);

    return Container(
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
      ), // BoxDecoration
      padding: padding,
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
      child: content,
    ); // Container
  }

  Widget _buildContent(
    BuildContext context,
    bool isDarkMode,
    Color contentColor,
  ) {
    switch (type) {
      case 'image':
        return _buildImage();
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

  Widget _buildImage() {
    if (mediaUrl == null || mediaUrl!.isEmpty) {
      return const Text('Изображение недоступно');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        mediaUrl!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
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
