import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool readed;
  final Timestamp? readAt;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.readed = false,
    this.readAt,
  });

  // convert to a map
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'readed': readed,
    };

    if (readAt != null) {
      map['readAt'] = readAt;
    }

    return map;
  }
}
