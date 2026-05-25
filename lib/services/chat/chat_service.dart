import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mox_beta/models/message.dart';

class ChatService {
  // get instanse of firestore & auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _chatRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  // get user stream
  /*
  List<Map<String,dynamic> =
  [
  {
  'email': test@gmail.com ,
  'id': …
  }.
  {
  'email': mitch@gmail.com ,
  'id':
  },
  ]
  */
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each individual user
        final user = doc.data();

        // return user
        return user;
      }).toList();
    });
  }
  // get user stream

  // send message
  Future<void> sendMessage(String receiverID, String message) async {
    // get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      readed: false,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    String chatRoomID = _chatRoomId(currentUserID, receiverID);

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    // construct a chatroom ID for the two users
    String chatRoomID = _chatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Stream<Map<String, dynamic>?> getLastMessage(String uid1, String uid2) {
    // создаём chatRoomID так же, как в sendMessage
    String chatRoomID = _chatRoomId(uid1, uid2);

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
