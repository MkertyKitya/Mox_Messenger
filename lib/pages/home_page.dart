import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:mox_beta/components/my_drawer.dart';
import 'package:mox_beta/components/user_tile.dart';
import 'package:mox_beta/components/user_avatar.dart';

import 'package:mox_beta/pages/chat_page.dart';

import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/services/chat/chat_service.dart';
import 'package:mox_beta/models/svg_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  late final String _currentUid;
  late final Stream<List<Map<String, dynamic>>> _chatStream;

  @override
  void initState() {
    super.initState();
    _currentUid = _authService.getCurrentUser()!.uid;
    _chatService.initChatCache(_currentUid);
    _chatStream = _chatService.chatStream;
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatPage(
          receiverEmail: chat["email"],
          receiverID: chat["uid"],
          receiverNickname: chat["nickname"],
          receiverPhone: chat["phone"],
          receiverIsOnline: chat["isOnline"] ?? false,
        ),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _HomeAppBar(),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          RepaintBoundary(
            child: SizedBox(width: double.infinity, child: SvgIcons.lineHome),
          ),
          Expanded(child: RepaintBoundary(child: _buildChatList())),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Ошибка"));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final chats = snapshot.data!;
        if (chats.isEmpty) {
          return const Center(child: Text("Нет чатов"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          physics: const BouncingScrollPhysics(),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];

            final String name = chat["nickname"] ?? '';
            final String lastMessage = chat["lastMessage"] ?? "";
            final int unread = chat["unreadCount"] ?? 0;
            final bool readed = chat["readed"] ?? true;

            final timestamp = chat["timestamp"] as Timestamp?;
            final String time = timestamp != null
                ? _formatTime(timestamp.toDate())
                : "00:00";

            return RepaintBoundary(
              child: UserTile(
                key: ValueKey(chat["uid"]),
                name: name,
                lastMessage: lastMessage,
                time: time,
                unread: unread,
                readed: readed,
                avatar: UserAvatar(
                  nickname: name,
                  isOnline: chat["isOnline"] ?? false,
                ),
                onTap: () => _openChat(chat),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const _HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<_HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<_HomeAppBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground.withOpacity(0.7),
        centerTitle: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              cursorWidth: 1.4,
              style: const TextStyle(fontSize: 14, height: 1.2),
              decoration: const InputDecoration(
                hintText: 'Поиск чатов',
                hintStyle: TextStyle(fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ),
        leadingWidth: 52,
        leading: Builder(
          builder: (context) => IconButton(
            iconSize: 24,
            padding: const EdgeInsets.only(left: 8),
            icon: SvgIcons.menuButton,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            iconSize: 24,
            padding: const EdgeInsets.only(right: 8),
            icon: SvgIcons.searchButton,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
