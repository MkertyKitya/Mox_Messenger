// lib/pages/chat_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mox_beta/models/svg_icons.dart' as icons;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mox_beta/components/chat_bubble.dart';
import 'package:mox_beta/components/user_avatar.dart' as ua;
import 'package:mox_beta/services/auth/auth_service.dart';
import 'package:mox_beta/services/chat/chat_service.dart';

import 'package:mox_beta/pages/home_page.dart';

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

  // controller for horizontal scrolling inside the TextField
  final ScrollController _textFieldScrollController = ScrollController();

  late final String _currentUserId;

  Stream<QuerySnapshot>? _messageStream;

  bool _hasText = false;
  bool _isRecording = false;
  bool _isUploadingMedia = false;
  bool _isInitialLoad = true;

  // debounce for search (if needed elsewhere) - kept for pattern consistency
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _currentUserId = _authService.getCurrentUser()!.uid;

    _messageController.addListener(_handleTextChanged);

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        _safeScroll(force: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messageStream = _chatServiceGetMessagesSafe();
      });
    });
  }

  // Helper to call chatService.getMessages safely (keeps initState tidy)
  Stream<QuerySnapshot> _chatServiceGetMessagesSafe() {
    return _chatService.getMessages(widget.receiverID, _currentUserId);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    myFocusNode.dispose();
    _messageController.removeListener(_handleTextChanged);
    _messageController.dispose();
    _scrollControllerSafeDispose();
    _textFieldScrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollControllerSafeDispose() {
    try {
      _scrollController.dispose();
    } catch (_) {}
  }

  void _safeScroll({bool force = false}) {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    Future.microtask(() {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final max = position.maxScrollExtent;
      if (max == 0.0) return;

      if (!force && !_isInitialLoad) {
        final distanceFromBottom = max - position.pixels;
        if (distanceFromBottom > 200) return;
      }

      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // Updated: handle text changes, update _hasText and scroll the TextField to end
  void _handleTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText == _hasText) {
      // Even if state didn't change, ensure the text field scrolls to show the cursor
      _scrollTextFieldToEnd();
      return;
    }
    if (!mounted) return;

    setState(() => _hasText = hasText);

    // Scroll after rebuild so the cursor/last characters are visible
    _scrollTextFieldToEnd();
  }

  void _scrollTextFieldToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_textFieldScrollController.hasClients) return;

      try {
        final max = _textFieldScrollController.position.maxScrollExtent;
        _textFieldScrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      } catch (_) {
        // ignore: sometimes position may be unavailable during layout changes
      }
    });
  }

  Future<void> _sendMediaFile({
    required XFile file,
    required String type,
  }) async {
    if (_isUploadingMedia || !mounted) return;

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
      _safeScroll(force: true);
    } catch (_) {
      _showSnack('Не удалось отправить файл');
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
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

    _safeScroll(force: true);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBackToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
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
    // Main layout: keep build light and avoid heavy operations here.
    return WillPopScope(
      onWillPop: () async {
        // If you want custom pop handling, return false and handle navigation manually.
        _goBackToHome(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              RepaintBoundary(child: _buildPreamble(context)),
              // use cached lineInChat from SvgIcons (placeholder until ready)
              SizedBox(
                width: double.infinity,
                child: icons.SvgIcons.lineInChat,
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
              RepaintBoundary(child: _buildUserInput()),
            ],
          ),
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
            onTap: () => _goBackToHome(context),
            child: SizedBox(
              width: 24,
              height: 24,
              child: icons.SvgIcons.backButton,
            ),
          ),
          const SizedBox(width: 12),
          ua.UserAvatar(
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
            child: SizedBox(
              width: 24,
              height: 24,
              child: icons.SvgIcons.callButton,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
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

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          _isInitialLoad = false;
          return const SizedBox();
        }

        final unreadDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['receiverID'] == _currentUserId && data['readed'] != true;
        }).toList();

        if (unreadDocs.isNotEmpty) {
          _chatService.markMessagesAsRead(unreadDocs);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _safeScroll(force: _isInitialLoad);
          _isInitialLoad = false;
        });

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

    // Попытка получить время из разных форматов
    DateTime? time;
    final created = data['createdAt'];
    if (created != null) {
      if (created is Timestamp) {
        time = created.toDate();
      } else if (created is DateTime) {
        time = created;
      } else if (created is int) {
        time = DateTime.fromMillisecondsSinceEpoch(created);
      } else if (created is String) {
        try {
          time = DateTime.parse(created);
        } catch (_) {
          /* ignore */
        }
      }
    }

    return RepaintBoundary(
      child: Container(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ChatBubble(
          message: data["message"] ?? '',
          isCurrentUser: isCurrentUser,
          type: data["type"] ?? 'text',
          mediaUrl: data["mediaUrl"],
          mediaName: data["mediaName"],
          time: time, // <- передаём время сюда
        ),
      ),
    );
  }

  Widget _buildUserInput() {
    final theme = Theme.of(context);

    // Use SvgIcons.instance.iconWidget for ad-hoc icons not exposed as getters
    final Widget emojiIcon = icons.SvgIcons.instance.iconWidget(
      'assets/svg/send_emoji_button.svg',
      width: 24,
      height: 24,
      placeholder: const SizedBox(width: 24, height: 24),
    );

    final Widget pinIcon = icons.SvgIcons.instance.iconWidget(
      'assets/svg/pinning_content.svg',
      width: 24,
      height: 24,
      placeholder: const SizedBox(width: 24, height: 24),
    );

    // AnimatedSwitcher for smooth icon swap between send and voice
    final Widget sendIconSwitcher = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SizedBox(
        key: ValueKey<bool>(_hasText),
        width: 24,
        height: 24,
        child: icons.SvgIcons.instance.iconWidget(
          _hasText
              ? 'assets/svg/send_message_button.svg'
              : 'assets/svg/send_voice_message_button.svg',
          width: 24,
          height: 24,
          placeholder: const SizedBox(width: 24, height: 24),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: emojiIcon),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: myFocusNode,
                scrollController: _textFieldScrollController,
                maxLines: 1,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  hintStyle: TextStyle(color: theme.colorScheme.onPrimary),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: TextStyle(color: theme.colorScheme.inversePrimary),
                textAlignVertical: TextAlignVertical.center,
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handlePickMedia,
              child: SizedBox(width: 24, height: 24, child: pinIcon),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleVoiceTap,
              child: SizedBox(width: 24, height: 24, child: sendIconSwitcher),
            ),
          ],
        ),
      ),
    );
  }
}
