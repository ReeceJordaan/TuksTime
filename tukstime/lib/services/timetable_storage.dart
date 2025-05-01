/// A utility class for storing and retrieving timetable data using SharedPreferences.
///
/// This class provides methods to save and load timetable data in JSON format.

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tukstime/data/lecture_data.dart';

/// TimetableStorage class handles the persistence of timetable data.
class TimetableStorage {
  /// The key used to store the timetable data in SharedPreferences.
  static const String _timetableKey = 'savedTimetable';

  /// Saves the given timetable to SharedPreferences.
  ///
  /// This method converts the list of [LectureData] objects to JSON format
  /// and stores it using the [_timetableKey].
  ///
  /// [timetable] is the list of [LectureData] objects to be saved.
  Future<void> saveTimetable(List<LectureData> timetable) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = timetable.map((lecture) => lecture.toJson()).toList();
    await prefs.setString(_timetableKey, jsonEncode(jsonList));
  }

  /// Loads the timetable from SharedPreferences.
  ///
  /// This method retrieves the JSON string stored using the [_timetableKey],
  /// decodes it, and converts it back to a list of [LectureData] objects.
  ///
  /// Returns an empty list if no data is found.
  Future<List<LectureData>> loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_timetableKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((data) => LectureData.fromJson(data)).toList();
  }
}
