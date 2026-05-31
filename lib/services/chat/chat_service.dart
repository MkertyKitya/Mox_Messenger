import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mox_beta/models/message.dart';

class ChatService {
  // firestore, auth, storage
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final Map<String, Map<String, dynamic>> _chatCache = {};
  final StreamController<List<Map<String, dynamic>>> _chatController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // подписки
  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;
  final Map<String, StreamSubscription<Map<String, dynamic>?>> _lastSubs = {};
  final Map<String, StreamSubscription<int>> _unreadSubs = {};

  Stream<List<Map<String, dynamic>>> get chatStream => _chatController.stream;

  String _chatRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> initChatCache(String currentUid) async {
    // отменяем старую подписку, если была
    await _usersSub?.cancel();
    for (final sub in _lastSubs.values) {
      await sub.cancel();
    }
    for (final sub in _unreadSubs.values) {
      await sub.cancel();
    }
    _lastSubs.clear();
    _unreadSubs.clear();
    _chatCache.clear();
    _emitCache();

    _usersSub = getUsersStream().listen((users) {
      for (final user in users) {
        final otherUid = user["uid"];
        if (otherUid == null || otherUid == currentUid) continue;

        // отменяем старые подписки на этого юзера
        _lastSubs[otherUid]?.cancel();
        _unreadSubs[otherUid]?.cancel();

        // слушаем последний месседж
        _lastSubs[otherUid] = getLastMessage(currentUid, otherUid).listen((
          last,
        ) async {
          if (last == null) {
            _chatCache.remove(otherUid);
            _emitCache();
            return;
          }

          final unread = await getUnreadCount(currentUid, otherUid).first;

          final timestamp = last["timestamp"] as Timestamp?;
          final isSenderCurrent = last["senderID"] == currentUid;
          final readed = isSenderCurrent ? (last["readed"] ?? false) : true;

          _chatCache[otherUid] = {
            "uid": otherUid,
            "email": user["email"],
            "nickname": user["nickname"],
            "phone": user["phone"],
            "isOnline": user["isOnline"] ?? false,
            "lastMessage": last["message"] ?? "",
            "type": last["type"] ?? "text",
            "timestamp": timestamp,
            "unreadCount": unread,
            "readed": readed,
          };

          _emitCache();
        });

        // слушаем непрочитанные
        _unreadSubs[otherUid] = getUnreadCount(currentUid, otherUid).listen((
          unread,
        ) {
          if (_chatCache.containsKey(otherUid)) {
            _chatCache[otherUid]!["unreadCount"] = unread;
            _emitCache();
          }
        });
      }
    });
  }

  void _emitCache() {
    final list = _chatCache.values.toList();
    list.sort((a, b) {
      final ta = a["timestamp"] as Timestamp?;
      final tb = b["timestamp"] as Timestamp?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    _chatController.add(list);
  }

  Future<void> disposeCache() async {
    await _usersSub?.cancel();
    for (final sub in _lastSubs.values) {
      await sub.cancel();
    }
    for (final sub in _unreadSubs.values) {
      await sub.cancel();
    }
    _lastSubs.clear();
    _unreadSubs.clear();
    _chatCache.clear();
  }

  // send text
  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    final newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      type: 'text',
      readed: false,
    );

    final chatRoomID = _chatRoomId(currentUserID, receiverID);

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  String _mediaLabel(String type, String? fallback) {
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }

    switch (type) {
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

  Future<void> sendMediaMessage({
    required String receiverID,
    required String type,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    final chatRoomID = _chatRoomId(currentUserID, receiverID);
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        'chat_media/$chatRoomID/${timestamp.millisecondsSinceEpoch}_$safeName';

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    final mediaUrl = await ref.getDownloadURL();

    final newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: _mediaLabel(type, null),
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
      mediaName: fileName,
      mediaMime: contentType,
      mediaSize: bytes.length,
      readed: false,
    );

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    final chatRoomID = _chatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Stream<Map<String, dynamic>?> getLastMessage(String uid1, String uid2) {
    final chatRoomID = _chatRoomId(uid1, uid2);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return snap.docs.first.data();
        });
  }

  Stream<int> getUnreadCount(String currentUserID, String otherUserID) {
    final chatRoomID = _chatRoomId(currentUserID, otherUserID);
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where("receiverID", isEqualTo: currentUserID)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.where((doc) {
            final data = doc.data();
            return data['readed'] != true;
          }).length,
        );
  }

  Future<void> markMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    const int batchLimit = 400;
    final now = Timestamp.now();

    for (int i = 0; i < docs.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(batchLimit);

      for (final doc in chunk) {
        batch.update(doc.reference, {'readed': true, 'readAt': now});
      }

      await batch.commit();
    }
  }
}
