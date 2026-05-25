import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final String type;
  final String? mediaUrl;
  final String? mediaName;
  final String? mediaMime;
  final int? mediaSize;
  final bool readed;
  final Timestamp? readAt;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.mediaName,
    this.mediaMime,
    this.mediaSize,
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
      'type': type,
      'readed': readed,
    };

    if (mediaUrl != null) {
      map['mediaUrl'] = mediaUrl;
    }
    if (mediaName != null) {
      map['mediaName'] = mediaName;
    }
    if (mediaMime != null) {
      map['mediaMime'] = mediaMime;
    }
    if (mediaSize != null) {
      map['mediaSize'] = mediaSize;
    }

    if (readAt != null) {
      map['readAt'] = readAt;
    }

    return map;
  }
}
