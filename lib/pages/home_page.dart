import 'package:flutter/material.dart';
import 'package:mox_beta/components/my_drawer.dart';
import 'package:mox_beta/components/user_tile.dart';
import 'package:mox_beta/pages/chat_page.dart';
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/services/chat/chat_service.dart';
import 'package:mox_beta/services/search/search_state.dart';
import 'package:mox_beta/components/user_avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

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
            decoration: InputDecoration(
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

        //_buildUserList(),
      ),
    );
  }

  // build a list of users except for the current logged in user
  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        // error
        if (snapshot.hasError) {
          return const Text("Error");
        }

        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }

        // return list view
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

  // build individual list tile for user
  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    // display all users except current user
    if (userData["email"] != _authService.getCurrentUser()!.email) {
      return UserTile(
        text: userData["nickname"],
        avatar: UserAvatar(
          isOnline: true,
          nickname: userData["nickname"],
          size: 48,
        ),
        onTap: () {
          // tapped on a user -> go to chat page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData["email"],
                receiverID: userData["uid"],
                receiverNickname: userData["nickname"],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}
