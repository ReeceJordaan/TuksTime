// weekly_scroll_view.dart

import 'package:flutter/material.dart';
import 'package:tukstime/widgets/day_card.dart';
import 'package:tukstime/data/lecture_data.dart';

class WeeklyScrollView extends StatelessWidget {
  final List<ScrollController> controllers;
  final List<LectureData>? timetable;
  final double scrollOffset;
  final Function(LectureData, List<LectureData>) onClashResolution;

  const WeeklyScrollView({
    super.key,
    required this.controllers,
    this.timetable,
    required this.scrollOffset,
    required this.onClashResolution,
  });

  String _abbreviateDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dates = List.generate(7, (i) => (20 + i).toString());

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: days.length,
      itemBuilder: (context, i) {
        List<LectureData> dayLectures = [];
        if (timetable != null) {
          dayLectures = timetable!
              .where((lecture) =>
                  _abbreviateDay(lecture.day) == days[i] ||
                  lecture.day.toLowerCase().startsWith(days[i].toLowerCase()))
              .toList();
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: DayCard(
              day: days[i],
              date: dates[i],
              controller: controllers[i],
              lectures: dayLectures,
              scrollOffset: scrollOffset,
              onClashResolution: onClashResolution,
            ),
          ),
        );
      },
    );
  }
}
