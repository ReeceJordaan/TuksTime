import 'package:flutter/material.dart';

/// A widget that displays a vertical time bar with hour labels.
///
/// The TimeBar widget shows a scrollable column of time labels,
/// typically used in scheduling or calendar applications to indicate
/// time slots.
class TimeBar extends StatelessWidget {
  /// The scroll controller for synchronizing scrolling with other widgets.
  final ScrollController controller;

  /// Creates a TimeBar widget.
  ///
  /// The [controller] parameter is required and should be used to
  /// synchronize scrolling with other widgets in the parent layout.
  const TimeBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      color: Colors.grey[200],
      child: SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.only(
          top: 40.0 + MediaQuery.of(context).padding.top, // Match headerOffset
          bottom: 45.0,
        ),
        child: Column(
          children: List.generate(17, (i) => _buildTimeLabel(6 + i, context)),
        ),
      ),
    );
  }

  /// Builds a single time label widget.
  ///
  /// [hour] is the hour to display, ranging from 6 to 22 (6 AM to 10 PM).
  /// The label shows the time in "HH:30" format.
  Widget _buildTimeLabel(int hour, BuildContext context) {
    return SizedBox(
      // Each hour = 64px, so 30-minute slots = 32px
      height: 64, // Changed from 63.25 to match 64px/hour ratio
      child: Center(
        child: Text(
          '${hour.toString().padLeft(2, '0')}:30',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
