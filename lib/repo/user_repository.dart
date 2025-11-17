import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository _instance = UserRepository._();
  static UserRepository get instance {
    return _instance;
  }

  final user = FirebaseAuth.instance.currentUser;
  final users = FirebaseFirestore.instance.collection('users');

  Stream<List<DocumentSnapshot>> getFriends() {
    // 1. Listen to current user document
    return users.doc(user!.uid).snapshots().asyncExpand((userDoc) {
      final data = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(data['friends'] ?? []);

      if (friendIds.isEmpty) {
        return Stream.value([]); // no friends
      }

      // 2. Query all friend documents using whereIn
      return users
          .where(FieldPath.documentId, whereIn: friendIds)
          .snapshots()
          .map((querySnap) => querySnap.docs);
    });
  }

  Stream<int> getTotalStudyTime(String userId) {
    final collection = FirebaseFirestore.instance.collection('studyTimes');

    return collection.where('userID', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      int totalSeconds = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final start = (data['started'] as Timestamp).toDate();
        final end = (data['finished'] as Timestamp).toDate();

        totalSeconds += end.difference(start).inSeconds;
      }

      return totalSeconds;
    });
  }
}
