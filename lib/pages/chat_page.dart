import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mox_beta/components/chat_bubble.dart';
import 'package:mox_beta/components/user_avatar.dart';
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/services/chat/chat_service.dart';

enum _MediaPickType { image, video }

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String receiverNickname;
  final String? receiverPhone;
  final bool receiverIsOnline;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    required this.receiverNickname,
    this.receiverPhone,
    this.receiverIsOnline = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // text controller
  final TextEditingController _messageController = TextEditingController();

  // chat & auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  // for textfield focus
  FocusNode myFocusNode = FocusNode();

  // scroll controller
  final ScrollController _scrollController = ScrollController();

  late final String _currentUserId;
  late final Stream<QuerySnapshot> _messageStream;
  StreamSubscription<QuerySnapshot>? _messageSub;
  bool _hasText = false;
  bool _isRecording = false;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();

    _currentUserId = _authService.getCurrentUser()!.uid;
    _messageStream = _chatService.getMessages(
      widget.receiverID,
      _currentUserId,
    );

    _messageSub = _messageStream.listen(_handleMessageSnapshot);

    _messageController.addListener(_handleTextChanged);

    // add listener to focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        // then the amount of remaining space will be calculated,
        // then scroll down
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
      }
    });

    // wait a bit for listview to be built, then scroll to bottom
    Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
  }

  void _handleMessageSnapshot(QuerySnapshot snapshot) {
    final unreadDocs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['receiverID'] == _currentUserId && data['readed'] != true;
    }).toList();

    if (unreadDocs.isNotEmpty) {
      _chatService.markMessagesAsRead(unreadDocs);
    }
  }

  void _handleTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _hasText) return;
    setState(() {
      _hasText = hasText;
    });
  }

  String _mediaFallbackName(String type) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    switch (type) {
      case 'image':
        return 'image_$stamp.jpg';
      case 'video':
        return 'video_$stamp.mp4';
      case 'audio':
        return 'voice_$stamp.m4a';
      default:
        return 'file_$stamp';
    }
  }

  String _guessContentType(String type, String fileName) {
    final parts = fileName.toLowerCase().split('.');
    final ext = parts.length > 1 ? parts.last : '';

    switch (type) {
      case 'image':
        if (ext == 'png') return 'image/png';
        if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
        return 'image/*';
      case 'video':
        if (ext == 'mov') return 'video/quicktime';
        if (ext == 'webm') return 'video/webm';
        return 'video/mp4';
      case 'audio':
        if (ext == 'mp3') return 'audio/mpeg';
        if (ext == 'wav') return 'audio/wav';
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.removeListener(_handleTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  // send message
  void sendMessage() async {
    // if there is something inside the textfield
    if (_messageController.text.isNotEmpty) {
      // send the message
      await _chatService.sendMessage(
        widget.receiverID,
        _messageController.text,
      );
      // clear text controller
      _messageController.clear();
    }

    scrollDown();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendMediaFile({
    required XFile file,
    required String type,
  }) async {
    if (_isUploadingMedia) return;

    final fileName = file.name.isNotEmpty
        ? file.name
        : _mediaFallbackName(type);
    final contentType = _guessContentType(type, fileName);

    setState(() {
      _isUploadingMedia = true;
    });

    _showSnack('Загрузка...');

    try {
      final bytes = await file.readAsBytes();
      await _chatService.sendMediaMessage(
        receiverID: widget.receiverID,
        type: type,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      _showSnack('Отправлено');
    } catch (_) {
      _showSnack('Не удалось отправить файл');
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  Future<void> _handleCallTap() async {
    final phone = widget.receiverPhone?.trim();
    if (phone == null || phone.isEmpty) {
      _showSnack('Номер телефона не указан');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showSnack('Не удалось открыть набор номера');
    }
  }

  Future<void> _handlePickMedia() async {
    final pickedType = await showModalBottomSheet<_MediaPickType>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Фото'),
                onTap: () => Navigator.of(context).pop(_MediaPickType.image),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Видео'),
                onTap: () => Navigator.of(context).pop(_MediaPickType.video),
              ),
            ],
          ),
        );
      },
    );

    if (pickedType == null) return;

    XFile? file;
    if (pickedType == _MediaPickType.image) {
      file = await _imagePicker.pickImage(source: ImageSource.gallery);
    } else {
      file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    }

    if (file == null) return;
    final mediaType = pickedType == _MediaPickType.image ? 'image' : 'video';
    await _sendMediaFile(file: file, type: mediaType);
  }

  Future<void> _handleVoiceTap() async {
    if (_hasText) {
      sendMessage();
      return;
    }

    if (!_isRecording) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack('Нет доступа к микрофону');
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
      _showSnack('Запись началась');
    } else {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });

      if (path == null) {
        _showSnack('Не удалось сохранить запись');
        return;
      }

      await _sendMediaFile(file: XFile(path), type: 'audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildPreamble(context),
            SvgPicture.asset(
              'assets/svg/line_in_chat_room.svg',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/svg/background_chat_page.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: _buildMessageList(),
              ),
            ),
            _buildUserInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreamble(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.tertiary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset(
              'assets/svg/back_button.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          UserAvatar(
            nickname: widget.receiverNickname,
            size: 48,
            isOnline: widget.receiverIsOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.receiverNickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.inversePrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleCallTap,
            child: SvgPicture.asset(
              'assets/svg/call_button.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _messageStream,
      builder: (context, snapshot) {
        // errors
        if (snapshot.hasError) {
          return const Text("Error");
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading…");
        }

        // return list view
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: snapshot.data!.docs
              .map((doc) => _buildMessageItem(doc))
              .toList(),
        ); // ListView
      },
    ); // StreamBuilder
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // is current user
    bool isCurrentUser = data['senderID'] == _currentUserId;

    // align message to the right if sender is the current user, otherwise left
    var alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,

        children: [
          ChatBubble(
            message: data["message"] ?? '',
            isCurrentUser: isCurrentUser,
            type: data["type"] ?? 'text',
            mediaUrl: data["mediaUrl"],
            mediaName: data["mediaName"],
          ),
        ],
      ),
    );
  }

  // build message input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/svg/send_emoji_button.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handlePickMedia,
              child: SvgPicture.asset(
                'assets/svg/pinning_content.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleVoiceTap,
              child: SvgPicture.asset(
                _hasText
                    ? 'assets/svg/send_message_button.svg'
                    : 'assets/svg/send_voice_message_button.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
