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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildAvatar(),

        Positioned(
          left: -size * 0.05,
          top: (size - size * 0.6) / 2,
          child: SvgPicture.asset(
            isOnline
                ? 'assets/svg/OnlineTrue.svg'
                : 'assets/svg/OnlineFalse.svg',
            height: size * 0.6,
          ),
        ),
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
        color: Color.fromARGB(254, 81, 181, 21),
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
      return (parts[0][0]).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
