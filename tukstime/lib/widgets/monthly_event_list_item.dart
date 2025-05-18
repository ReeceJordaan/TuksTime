import 'package:flutter/material.dart';
import 'package:tukstime/data/lecture_data.dart'; // Assuming this path is correct

class MonthlyEventListItem extends StatelessWidget {
  final LectureData lecture;

  const MonthlyEventListItem({super.key, required this.lecture});

  Color _getActivityColor() {
    final activityLower = lecture.activity.toLowerCase();
    if (activityLower.contains('lecture'))
      return const Color(0xFF4A90E2); // App's primary blue
    if (activityLower.contains('practical'))
      return const Color(0xFF50E3C2); // App's primary teal
    if (activityLower.contains('tutorial')) return Colors.orange.shade400;
    if (activityLower.contains('meeting')) return Colors.purple.shade300;
    return Colors.grey.shade500;
  }

  IconData _getActivityIcon() {
    final activityLower = lecture.activity.toLowerCase();
    if (activityLower.contains('lecture')) return Icons.school_outlined;
    if (activityLower.contains('practical')) return Icons.science_outlined;
    if (activityLower.contains('tutorial')) return Icons.group_work_outlined;
    if (activityLower.contains('meeting')) return Icons.people_alt_outlined;
    return Icons.event_note_outlined;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final Color activityColor = _getActivityColor();
    final IconData activityIcon = _getActivityIcon();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: activityColor.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 16.0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: activityColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(activityIcon, color: activityColor, size: 24),
        ),
        title: Text(
          lecture.module,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color:
                Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.85) ??
                Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  lecture.time,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lecture.venue,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _capitalize(lecture.activity),
              style: TextStyle(
                fontSize: 13,
                color: activityColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (lecture.hasClash)
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clash Detected!',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
