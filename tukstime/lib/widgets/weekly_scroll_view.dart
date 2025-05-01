/// A widget that displays a horizontally scrollable weekly view of lectures.
///
/// This widget creates a horizontal list of [DayCard] widgets, each representing
/// a day of the week. It uses the provided [timetable] to populate each day with
/// the corresponding lectures.
///
/// The [WeeklyScrollView] takes the following parameters:
/// * [controllers]: A list of [ScrollController]s for each day's vertical scroll.
/// * [timetable]: An optional list of [LectureData] objects representing the week's lectures.
/// * [scrollOffset]: The vertical scroll offset to apply to each day's view.
/// * [onClashResolution]: A callback function to handle lecture time clashes.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tukstime/widgets/day_card.dart';
import 'package:tukstime/data/lecture_data.dart';

class WeeklyScrollView extends StatelessWidget {
  /// The list of scroll controllers for each day's vertical scroll.
  final List<ScrollController> controllers;

  /// The list of lectures for the week.
  final List<LectureData>? timetable;

  /// The vertical scroll offset to apply to each day's view.
  final double scrollOffset;

  /// A callback function to handle lecture time clashes.
  final Function(LectureData, List<LectureData>) onClashResolution;

  /// Creates a [WeeklyScrollView] widget.
  ///
  /// The [controllers], [scrollOffset], and [onClashResolution] parameters are required.
  /// The [timetable] parameter is optional.
  const WeeklyScrollView({
    super.key,
    required this.controllers,
    this.timetable,
    required this.scrollOffset,
    required this.onClashResolution,
  });

  /// Abbreviates the given day name to a three-letter format.
  ///
  /// Returns the abbreviated day name (e.g., 'Mon' for 'Monday').
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
          dayLectures =
              timetable!
                  .where(
                    (lecture) =>
                        _abbreviateDay(lecture.day) == days[i] ||
                        lecture.day.toLowerCase().startsWith(
                          days[i].toLowerCase(),
                        ),
                  )
                  .toList();
        }

        return SizedBox(
          height: max(0, MediaQuery.of(context).size.height - 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
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
