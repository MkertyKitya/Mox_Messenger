import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  // get instanse of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // get message
}
