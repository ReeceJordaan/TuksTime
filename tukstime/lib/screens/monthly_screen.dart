import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tukstime/data/lecture_data.dart';
import 'package:tukstime/services/timetable_storage.dart';
import 'package:tukstime/widgets/monthly_event_list_item.dart';
import 'package:tukstime/screens/generate_screen.dart'; // For drawer navigation
import 'package:tukstime/screens/weekly_screen.dart'; // For drawer navigation

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  final TimetableStorage _storage = TimetableStorage();
  List<LectureData> _allLectures = [];
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<LectureData>> _eventsByDay = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadTimetableAndProcess();
  }

  Future<void> _loadTimetableAndProcess() async {
    setState(() {
      _isLoading = true;
    });
    _allLectures = await _storage.loadTimetable();
    _eventsByDay = _groupEventsByDay(_allLectures);
    setState(() {
      _isLoading = false;
    });
  }

  Map<DateTime, List<LectureData>> _groupEventsByDay(
    List<LectureData> lectures,
  ) {
    Map<DateTime, List<LectureData>> data = {};
    // This approach assumes lectures are weekly recurring.
    // For a full calendar, one might need to iterate through all days of all visible months.
    // However, for this app, displaying weekly recurring events on their respective weekdays in the month is appropriate.
    // TableCalendar's eventLoader will call _getEventsForDay for each visible day.
    return data; // This map can be used if we want to pre-process events for specific dates.
    // For now, _getEventsForDay will handle it dynamically.
  }

  int _dayNameToWeekday(String dayName) {
    switch (dayName.trim().toLowerCase().substring(0, 3)) {
      case 'mon':
        return DateTime.monday;
      case 'tue':
        return DateTime.tuesday;
      case 'wed':
        return DateTime.wednesday;
      case 'thu':
        return DateTime.thursday;
      case 'fri':
        return DateTime.friday;
      case 'sat':
        return DateTime.saturday;
      case 'sun':
        return DateTime.sunday;
      default:
        return -1; // Should not happen with valid data
    }
  }

  List<LectureData> _getEventsForDay(DateTime day) {
    // Filter all lectures to find those that occur on this specific weekday
    final dayOfWeek = day.weekday;
    return _allLectures.where((lecture) {
        return _dayNameToWeekday(lecture.day) == dayOfWeek;
      }).toList()
      ..sort((a, b) {
        // Sort by time
        final aStartTime = a.time.split('-')[0].trim();
        final bStartTime = b.time.split('-')[0].trim();
        return aStartTime.compareTo(bStartTime);
      });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Widget _buildAppBarBackground(BuildContext context, String titleText) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: Text(
            titleText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = DateFormat.yMMMM().format(_focusedDay);
    final selectedDayEvents =
        _selectedDay != null
            ? _getEventsForDay(_selectedDay!)
            : <LectureData>[];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: kToolbarHeight, // Standard height
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: _buildAppBarBackground(context, appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: 'Go to Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      drawer: _buildAppDrawer(context),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
              )
              : Column(
                children: [
                  TableCalendar<LectureData>(
                    firstDay: DateTime.utc(
                      DateTime.now().year - 1,
                      1,
                      1,
                    ), // Show previous year
                    lastDay: DateTime.utc(
                      DateTime.now().year + 1,
                      12,
                      31,
                    ), // Show next year
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A90E2),
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF4A90E2),
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF4A90E2),
                      ),
                      headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: const Color(
                          0xFF50E3C2,
                        ).withOpacity(0.8), // Teal for today
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: const Color(0xFF4A90E2), // Blue for selected
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Colors.redAccent.shade100,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF50E3C2), // Teal markers
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount:
                          1, // Show one dot even if multiple events, or adjust as needed
                      markerSize: 5.0,
                      markerMargin: const EdgeInsets.symmetric(
                        horizontal: 0.5,
                      ).copyWith(top: 4.0),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF50E3C2,
                                ).withOpacity(0.9), // Teal markers
                              ),
                              width: 7.0,
                              height: 7.0,
                              margin: const EdgeInsets.all(4.0),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _selectedDay != null
                          ? 'Events for ${DateFormat.yMMMMd().format(_selectedDay!)}'
                          : 'Select a day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        selectedDayEvents.isNotEmpty
                            ? ListView.builder(
                              itemCount: selectedDayEvents.length,
                              itemBuilder: (context, index) {
                                return MonthlyEventListItem(
                                  lecture: selectedDayEvents[index],
                                );
                              },
                            )
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events scheduled for this day.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'TuksTime',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Menu',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.build_circle_outlined,
              color: Color(0xFF4A90E2),
            ),
            title: const Text('Generate Timetable'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GenerateScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.calendar_view_week_outlined,
              color: Color(0xFF4A90E2),
            ),
            title: const Text('Weekly Calendar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WeeklyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF50E3C2),
            ),
            title: const Text('Monthly Calendar'),
            tileColor: Colors.teal.withOpacity(
              0.05,
            ), // Highlight current screen
            onTap: () {
              Navigator.pop(context);
              // If already on MonthlyScreen, optionally refresh or do nothing
              // For simplicity, pushReplacement reloads it.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MonthlyScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Settings Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings screen not implemented yet.'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.grey),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Help Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support screen not implemented yet.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
