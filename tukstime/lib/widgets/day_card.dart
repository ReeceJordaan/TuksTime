// day_card.dart

import 'package:flutter/material.dart';
import 'package:tukstime/data/lecture_data.dart';

class DayCard extends StatefulWidget {
  final String day;
  final String date;
  final ScrollController controller;
  final List<LectureData>? lectures;
  final double scrollOffset;
  final Function(LectureData, List<LectureData>) onClashResolution;

  const DayCard({
    super.key,
    required this.day,
    required this.date,
    required this.controller,
    this.lectures,
    required this.scrollOffset,
    required this.onClashResolution,
  });

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  @override
  void initState() {
    super.initState();
    _syncScrollOffset();
  }

  @override
  void didUpdateWidget(DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffset != widget.scrollOffset) {
      _syncScrollOffset();
    }
  }

  void _syncScrollOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients &&
          widget.controller.offset != widget.scrollOffset) {
        widget.controller.jumpTo(widget.scrollOffset);
      }
    });
  }

  int _timeStringToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _getSlotIndex(String timeRange) {
    final times = timeRange.split('-');
    if (times.length != 2) return 0;
    final startTimeStr = times[0].trim();
    final startMinutes = _timeStringToMinutes(startTimeStr);
    return ((startMinutes - 390) / 60).floor();
  }

  int _getSlotSpan(String timeRange) {
    final times = timeRange.split('-');
    if (times.length != 2) return 1;
    final startTimeStr = times[0].trim();
    final endTimeStr = times[1].trim();
    final startMinutes = _timeStringToMinutes(startTimeStr);
    final endMinutes = _timeStringToMinutes(endTimeStr);
    final duration = endMinutes - startMinutes;
    return (duration / 60).ceil();
  }

  /// Returns the activity type based on the first letter of the activity string.
  String _activityType(String activity) {
    if (activity.isEmpty) return 'Undefined activity';
    final firstLetter = activity[0].toUpperCase();
    if (firstLetter == 'L') return 'Lecture';
    if (firstLetter == 'P') return 'Practical';
    if (firstLetter == 'T') return 'Tutorial';
    return 'Undefined activity';
  }

  void _handleClashTap(LectureData lecture) async {
    if (!lecture.hasClash) return;

    final overlapping = widget.lectures!.where((l) {
      if (!l.hasClash) return false;
      return _timesOverlap(lecture.time, l.time);
    }).toList();

    final selected = await showDialog<LectureData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Timetable Clash'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Select preferred activity:'),
              ...overlapping.map((l) => ListTile(
                    title: Text('${l.module} ${l.activity}'),
                    subtitle: Text('Group: ${l.group}\nVenue: ${l.venue}'),
                    tileColor: l.isResolved
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    onTap: () => Navigator.pop(context, l),
                  )),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      widget.onClashResolution(selected, [lecture, ...overlapping]);
    }
  }

  bool _timesOverlap(String time1, String time2) {
    final t1 =
        time1.split('-').map((t) => _timeStringToMinutes(t.trim())).toList();
    final t2 =
        time2.split('-').map((t) => _timeStringToMinutes(t.trim())).toList();
    return t1[0] < t2[1] && t1[1] > t2[0];
  }

  @override
  Widget build(BuildContext context) {
    const int numSlots = 17;
    const double slotHeight = 60.0;

    final Map<int, LectureData> lectureMap = {};
    if (widget.lectures != null) {
      for (var lecture in widget.lectures!) {
        final slotIndex = _getSlotIndex(lecture.time);
        if (slotIndex >= 0 &&
            slotIndex < numSlots &&
            !lectureMap.containsKey(slotIndex)) {
          lectureMap[slotIndex] = lecture;
        }
      }
    }

    List<Widget> timeslotWidgets = [];
    int slot = 0;
    while (slot < numSlots) {
      if (lectureMap.containsKey(slot)) {
        final lecture = lectureMap[slot]!;
        final span = _getSlotSpan(lecture.time);

        timeslotWidgets.add(
          GestureDetector(
            onTap: () => _handleClashTap(lecture),
            child: Container(
              height: (slotHeight * span) + 8 * (span - 1),
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: lecture.isResolved
                    ? Colors.blue.withOpacity(0.3)
                    : lecture.hasClash
                        ? Colors.red.withOpacity(0.4)
                        : Colors.lightBlueAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.0),
                border: lecture.hasClash
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0, vertical: 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display the module
                      Text(
                        lecture.module,
                        style: TextStyle(
                          fontSize: 12,
                          color: lecture.hasClash ? Colors.red : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Display the venue
                      Text(
                        lecture.venue,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Display the computed activity type
                      Text(
                        _activityType(lecture.activity),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        slot += span;
      } else {
        timeslotWidgets.add(
          Container(
            height: slotHeight,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
        slot += 1;
      }
    }

    return Container(
      width: 168,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outer padding reduced from 16 to 8.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.day,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.date,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.controller,
              padding: EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  ...timeslotWidgets,
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
