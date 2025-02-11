// lecture_data.dart

class LectureData {
  final String module;
  final String offered;
  final String group;
  final String language;
  final String activity;
  final String day;
  final String time;
  final String venue;
  bool hasClash;
  final String campus;
  final String studyProg;

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

  /// Factory to parse a row from the lectures.csv file.
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

  @override
  String toString() => '$module ($activity on $day at $time)';
}
