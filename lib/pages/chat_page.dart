import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mox_beta/models/svg_icons.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final FocusNode myFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final String _currentUserId;

  Stream<QuerySnapshot>? _messageStream; // <--- теперь nullable

  bool _hasText = false;
  bool _isRecording = false;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();

    _currentUserId = _authService.getCurrentUser()!.uid;

    _messageController.addListener(_handleTextChanged);

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
      }
    });

    // 🔥 Подключаем Firestore ТОЛЬКО после первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messageStream = _chatService.getMessages(
          widget.receiverID,
          _currentUserId,
        );
      });
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.removeListener(_handleTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollDown() {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;
    if (target == 0.0) return;

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _hasText) return;
    setState(() => _hasText = hasText);
  }

  Future<void> _sendMediaFile({
    required XFile file,
    required String type,
  }) async {
    if (_isUploadingMedia) return;

    final fileName = file.name.isNotEmpty
        ? file.name
        : 'file_${DateTime.now().millisecondsSinceEpoch}';

    final contentType = _guessContentType(type, fileName);

    setState(() => _isUploadingMedia = true);
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
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  String _guessContentType(String type, String fileName) {
    final ext = fileName.toLowerCase().split('.').last;

    switch (type) {
      case 'image':
        return ext == 'png' ? 'image/png' : 'image/jpeg';
      case 'video':
        return ext == 'mov' ? 'video/quicktime' : 'video/mp4';
      case 'audio':
        return ext == 'wav' ? 'audio/wav' : 'audio/mp4';
      default:
        return 'application/octet-stream';
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
    if (!launched) _showSnack('Не удалось открыть набор номера');
  }

  Future<void> _handlePickMedia() async {
    final pickedType = await showModalBottomSheet<_MediaPickType>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Фото'),
              onTap: () => Navigator.pop(context, _MediaPickType.image),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Видео'),
              onTap: () => Navigator.pop(context, _MediaPickType.video),
            ),
          ],
        ),
      ),
    );

    if (pickedType == null) return;

    final file = pickedType == _MediaPickType.image
        ? await _imagePicker.pickImage(source: ImageSource.gallery)
        : await _imagePicker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    await _sendMediaFile(
      file: file,
      type: pickedType == _MediaPickType.image ? 'image' : 'video',
    );
  }

  Future<void> _handleVoiceTap() async {
    if (_hasText) {
      _sendTextMessage();
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
      setState(() => _isRecording = true);
      _showSnack('Запись началась');
    } else {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);

      if (path == null) {
        _showSnack('Не удалось сохранить запись');
        return;
      }

      await _sendMediaFile(file: XFile(path), type: 'audio');
    }
  }

  void _sendTextMessage() async {
    if (_messageController.text.isEmpty) return;

    await _chatService.sendMessage(widget.receiverID, _messageController.text);

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildPreamble(context),

            SizedBox(width: double.infinity, child: SvgIcons.lineInChat),

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
            onTap: () => Navigator.pop(context),
            child: SvgIcons.backButton,
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
          GestureDetector(onTap: _handleCallTap, child: SvgIcons.callButton),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    // 🔥 Firestore ещё не подключён → показываем лёгкий лоадер
    if (_messageStream == null) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Ошибка"));
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // помечаем непрочитанные как прочитанные
        final unreadDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['receiverID'] == _currentUserId && data['readed'] != true;
        }).toList();

        if (unreadDocs.isNotEmpty) {
          _chatService.markMessagesAsRead(unreadDocs);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());

        if (docs.isEmpty) return const SizedBox();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildMessageItem(docs[index]),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isCurrentUser = data['senderID'] == _currentUserId;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ChatBubble(
        message: data["message"] ?? '',
        isCurrentUser: isCurrentUser,
        type: data["type"] ?? 'text',
        mediaUrl: data["mediaUrl"],
        mediaName: data["mediaName"],
      ),
    );
  }

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
