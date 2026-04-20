import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String? imageURL;
  final String? nickname;
  final bool isOnline;
  final double size;

  const UserAvatar({
    super.key,
    this.imageURL,
    this.nickname,
    this.isOnline = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(children: [
        
      ],
    
    );
  }

  Widget _buildAvatar() {
    if (imageURL != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageURL!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green,
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(nickname ?? ""),
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getInitials(String nickname) {
    final parts = nickname.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, 0).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
