/// This file contains the LectureData class, which represents a single lecture in a university schedule.
///
/// The LectureData class encapsulates all the information related to a lecture, including:
/// - Module name
/// - Offering details
/// - Group
/// - Language of instruction
/// - Type of activity (e.g., lecture, practical)
/// - Day and time of the lecture
/// - Venue and campus
/// - Study program
/// - Clash status
///
/// It also provides methods for creating LectureData objects from CSV and JSON data,
/// as well as converting LectureData objects to JSON format.

/// Represents a single lecture in a university schedule.
class LectureData {
  /// The name or code of the module.
  final String module;

  /// Details about when the module is offered.
  final String offered;

  /// The group identifier for the lecture.
  final String group;

  /// The language of instruction for the lecture.
  final String language;

  /// The type of activity (e.g., lecture, practical).
  final String activity;

  /// The day of the week when the lecture takes place.
  final String day;

  /// The time of day when the lecture is scheduled.
  final String time;

  /// The venue where the lecture is held.
  final String venue;

  /// Indicates whether this lecture clashes with another in the schedule.
  bool hasClash;

  /// The campus where the lecture is held.
  final String campus;

  /// The study program associated with this lecture.
  final String studyProg;

  /// Private flag to track if a clash has been resolved.
  bool _isResolved = false;

  /// Constructs a new LectureData instance.
  LectureData({
    required this.module,
    required this.offered,
    required this.group,
    required this.language,
    required this.activity,
    required this.day,
    required this.time,
    required this.venue,
    required this.campus,
    required this.studyProg,
    this.hasClash = false,
  });

  // empty constructor for user-created events
  LectureData.empty()
    : module = '',
      offered = '',
      group = '',
      language = '',
      activity = '',
      day = '',
      time = '',
      venue = '',
      campus = '',
      studyProg = '',
      hasClash = false;

  /// Creates a LectureData instance from a CSV row.
  ///
  /// [values] is a list of strings representing a row from the lectures.csv file.
  factory LectureData.fromCsv(List<String> values) {
    return LectureData(
      module: values[0].trim(),
      offered: values[1].trim(),
      group: values[2].trim(),
      language: values[3].trim(),
      activity: values[4].trim(),
      day: values[5].trim(),
      time: values[6].trim(),
      venue: values[7].trim(),
      campus: values[8].trim(),
      studyProg: values.length > 9 ? values[9].trim() : '',
      hasClash: false,
    );
  }

  /// Creates a LectureData instance from a JSON object.
  ///
  /// [json] is a Map representing the JSON data.
  factory LectureData.fromJson(Map<String, dynamic> json) {
    return LectureData(
      module: json['module'],
      offered: json['offered'],
      group: json['group'],
      language: json['language'],
      activity: json['activity'],
      day: json['day'],
      time: json['time'],
      venue: json['venue'],
      campus: json['campus'],
      studyProg: json['studyProg'],
      hasClash: json['hasClash'] ?? false,
    );
  }

  /// Converts the LectureData instance to a JSON object.
  ///
  /// Returns a Map that can be easily converted to JSON.
  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'offered': offered,
      'group': group,
      'language': language,
      'activity': activity,
      'day': day,
      'time': time,
      'venue': venue,
      'campus': campus,
      'studyProg': studyProg,
      'hasClash': hasClash,
    };
  }

  /// Indicates whether a clash for this lecture has been resolved.
  bool get isResolved => _isResolved;

  /// Marks the lecture as resolved and removes the clash status.
  void resolve() {
    _isResolved = true;
    hasClash = false;
  }

  /// Provides a string representation of the LectureData instance.
  @override
  String toString() => '$module ($activity on $day at $time)';
}
