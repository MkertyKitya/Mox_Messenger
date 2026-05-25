import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mox_beta/components/my_drawer.dart';
import 'package:mox_beta/components/user_tile.dart';
import 'package:mox_beta/components/user_avatar.dart';

import 'package:mox_beta/pages/chat_page.dart';

import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/services/chat/chat_service.dart';
import 'package:mox_beta/services/search/search_state.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _lastMessageLabel(Map<String, dynamic>? last) {
    if (last == null) return '';
    final message = (last['message'] ?? '').toString();
    if (message.trim().isNotEmpty) return message;

    switch (last['type']) {
      case 'image':
        return 'Фото';
      case 'video':
        return 'Видео';
      case 'audio':
        return 'Голосовое сообщение';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(50),
          ),
          child: TextField(
            cursorColor: Theme.of(context).colorScheme.onPrimary,
            decoration: const InputDecoration(
              hintText: 'Search chats',
              border: InputBorder.none,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgPicture.asset('assets/svg/Menu_Button.svg'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/svg/Search.svg'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => _buildSearch(context)),
              );
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          SvgPicture.asset('assets/svg/Line.svg'),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: UserInformation(),
    );
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    final currentUid = _authService.getCurrentUser()!.uid;
    final otherUid = userData["uid"];

    if (userData["email"] == _authService.getCurrentUser()!.email) {
      return Container();
    }

    return StreamBuilder(
      stream: _chatService.getLastMessage(currentUid, otherUid),
      builder: (context, snapshot) {
        return StreamBuilder<int>(
          stream: _chatService.getUnreadCount(currentUid, otherUid),
          builder: (context, unreadSnapshot) {
            final last = snapshot.data;

            final lastMessage = _lastMessageLabel(last);
            final timestamp = last?["timestamp"];
            final time = timestamp != null ? _formatTime(timestamp) : "00:00";

            final readed = last?["senderID"] == currentUid
                ? (last?["readed"] ?? false)
                : true;

            final unread = unreadSnapshot.data ?? 0;

            return UserTile(
              name: userData["nickname"],
              lastMessage: lastMessage,
              time: time,
              unread: unread,
              readed: readed,
              avatar: UserAvatar(
                nickname: userData["nickname"],
                isOnline: userData["isOnline"] ?? false,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverEmail: userData["email"],
                      receiverID: userData["uid"],
                      receiverNickname: userData["nickname"],
                      receiverPhone: userData["phone"],
                      receiverIsOnline: userData["isOnline"] ?? false,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
