import 'package:flutter/material.dart';
import 'package:tukstime/data/lecture_data.dart';

class DayCard extends StatefulWidget {
  final String day;
  final String date;
  final ScrollController controller;
  final List<LectureData>? lectures;
  final double scrollOffset;

  const DayCard({
    super.key,
    required this.day,
    required this.date,
    required this.controller,
    this.lectures,
    required this.scrollOffset,
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

  @override
  Widget build(BuildContext context) {
    const int numSlots = 17;
    const double slotHeight = 60.0;

    final Map<int, LectureData> lectureMap = {};
    if (widget.lectures != null) {
      // Changed to widget.lectures
      for (var lecture in widget.lectures!) {
        // Changed to widget.lectures
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
          Container(
            height: (slotHeight * span) + 8 * (span - 1),
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                '${lecture.module} ${lecture.activity}\n${lecture.time}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        );
        slot += span;
      } else {
        timeslotWidgets.add(
          Container(
            height: slotHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
      width: 250,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.day, // Changed to widget.day
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.date, // Changed to widget.date
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.controller,
              padding: EdgeInsets.only(bottom: 0), // Remove bottom padding
              child: Column(
                children: [
                  ...timeslotWidgets,
                  SizedBox(height: 40), // Match TimeBar's bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
