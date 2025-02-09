import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tukstime/data/lecture_data.dart';

class TimetableStorage {
  static const String _timetableKey = 'savedTimetable';

  Future<void> saveTimetable(List<LectureData> timetable) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = timetable.map((lecture) => lecture.toJson()).toList();
    await prefs.setString(_timetableKey, jsonEncode(jsonList));
  }

  Future<List<LectureData>> loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_timetableKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((data) => LectureData.fromJson(data)).toList();
  }
}
