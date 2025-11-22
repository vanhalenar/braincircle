import 'package:cloud_firestore/cloud_firestore.dart';

class StudyTimesRepository {
  StudyTimesRepository._();
  static final _instance = StudyTimesRepository._();
  static StudyTimesRepository get instance {
    return _instance;
  }

  final studyTimes = FirebaseFirestore.instance.collection('studyTimes');

  void uploadSession(String userID, DateTime started, DateTime finished) {
    final session = {
      "userID": userID,
      "started": started,
      "finished": finished
    };

    studyTimes.add(session);
  }
}