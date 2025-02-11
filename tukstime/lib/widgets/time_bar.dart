// time_bar.dart

import 'package:flutter/material.dart';

class TimeBar extends StatelessWidget {
  final ScrollController controller;
  const TimeBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: Colors.grey[200],
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.only(top: 63.0, bottom: 40.0),
        child: Column(
          children: List.generate(17, (i) => _buildTimeLabel(6 + i)),
        ),
      ),
    );
  }

  Widget _buildTimeLabel(int hour) {
    return SizedBox(
      height: 68,
      child: Center(
        child: Text(
          '${hour.toString().padLeft(2, '0')}:30',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
