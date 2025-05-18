// weekly_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tukstime/data/lecture_data.dart';
import 'package:tukstime/services/timetable_storage.dart';
import 'package:tukstime/widgets/time_bar.dart';
import 'package:tukstime/widgets/weekly_scroll_view.dart';
import 'package:tukstime/screens/generate_screen.dart';
import 'package:tukstime/screens/monthly_screen.dart';

class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  late Future<List<LectureData>> _timetableFuture;
  final TimetableStorage _storage = TimetableStorage();
  late ScrollController timeBarController;
  late List<ScrollController> dayControllers;
  double currentTimeIndicatorTop = 0.0;
  double scrollOffset = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<double> _indicatorPosition = ValueNotifier(0);
  final List<String> eventTypes = [
    'Lecture',
    'Practical',
    'Tutorial',
    'Meeting',
    'Other',
  ];
  final List<Map<String, String>> days = [
    {'abbrev': 'Mon', 'full': 'Monday'},
    {'abbrev': 'Tue', 'full': 'Tuesday'},
    {'abbrev': 'Wed', 'full': 'Wednesday'},
    {'abbrev': 'Thu', 'full': 'Thursday'},
    {'abbrev': 'Fri', 'full': 'Friday'},
    {'abbrev': 'Sat', 'full': 'Saturday'},
    {'abbrev': 'Sun', 'full': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    timeBarController = ScrollController();
    dayControllers = List.generate(7, (_) => ScrollController());

    _timetableFuture = _storage.loadTimetable().then((timetable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupScrollSync();
        _updateIndicatorPosition();
      });
      return timetable;
    });
  }

  void _setupScrollSync() {
    void syncControllers(ScrollController source) {
      if (!source.hasClients) return;
      final sourceOffset = source.offset;

      setState(() {
        scrollOffset = sourceOffset;
        final now = DateTime.now();
        final startTime = DateTime(now.year, now.month, now.day, 6, 30);
        final headerOffset = 40 + MediaQuery.of(context).padding.top;
        double newIndicatorPos;

        if (now.isBefore(startTime)) {
          newIndicatorPos = headerOffset - scrollOffset;
        } else {
          final duration = now.difference(startTime);
          final totalMinutes =
              duration.inMinutes + (duration.inSeconds % 60) / 60;
          final contentPos = headerOffset + (totalMinutes * 64 / 60);
          newIndicatorPos = contentPos - scrollOffset;
        }

        _indicatorPosition.value = newIndicatorPos;
      });

      void sync(ScrollController target) {
        if (target == source) return;
        if (target.hasClients && target.offset != sourceOffset) {
          target.jumpTo(sourceOffset);
        }
      }

      sync(timeBarController);
      for (final controller in dayControllers) {
        sync(controller);
      }
    }

    timeBarController.addListener(() => syncControllers(timeBarController));

    for (final controller in dayControllers) {
      controller.addListener(() => syncControllers(controller));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.hasClients && controller.offset != scrollOffset) {
          controller.jumpTo(scrollOffset);
        }
      });
    }
  }

  void _updateIndicatorPosition() {
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 6, 30);
    final headerOffset = 40 + MediaQuery.of(context).padding.top;

    if (now.isBefore(startTime)) {
      _indicatorPosition.value = headerOffset - scrollOffset;
    } else {
      final duration = now.difference(startTime);
      final totalMinutes = duration.inMinutes + (duration.inSeconds % 60) / 60;
      final contentPos = headerOffset + (totalMinutes * 64 / 60);
      _indicatorPosition.value = contentPos - scrollOffset;
    }
  }

  void _scrollToCurrentTime() {
    if (!timeBarController.hasClients) return;
    final viewportHeight = timeBarController.position.viewportDimension;
    final maxOffset = timeBarController.position.maxScrollExtent;
    double desiredOffset = currentTimeIndicatorTop - (viewportHeight / 2);
    desiredOffset = desiredOffset.clamp(0, maxOffset);
    timeBarController.jumpTo(desiredOffset);
  }

  @override
  void dispose() {
    timeBarController.dispose();
    for (final c in dayControllers) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime _getMondayOfCurrentWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  Widget _buildAppBarBackground(BuildContext context, String weekText) {
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
            weekText,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: _indicatorPosition,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Container(height: 2, color: const Color(0xFF50E3C2)),
        );
      },
    );
  }

  Future<void> _handleClashResolution(
    LectureData selected,
    List<LectureData> clashes,
    List<LectureData> timetable,
  ) async {
    final updated =
        timetable
            .map((l) {
              if (l == selected) return l..resolve();
              if (clashes.contains(l)) return null;
              return l;
            })
            .whereType<LectureData>()
            .toList();

    await _storage.saveTimetable(updated);
    _refreshTimetable();
  }

  void _detectClashes(List<LectureData> lectures) {
    final Map<String, List<LectureData>> dayLectures = {};
    for (final lecture in lectures) {
      lecture.hasClash = false;
    }

    for (final lecture in lectures) {
      dayLectures.putIfAbsent(lecture.day, () => []).add(lecture);
    }

    for (final day in dayLectures.keys) {
      final dailyLectures =
          dayLectures[day]!..sort(
            (a, b) => _timeToMinutes(
              a.time.split('-')[0].trim(),
            ).compareTo(_timeToMinutes(b.time.split('-')[0].trim())),
          );

      for (int i = 0; i < dailyLectures.length; i++) {
        for (int j = i + 1; j < dailyLectures.length; j++) {
          final lectureA = dailyLectures[i];
          final lectureB = dailyLectures[j];

          final aStart = _timeToMinutes(lectureA.time.split('-')[0].trim());
          final aEnd = _timeToMinutes(lectureA.time.split('-')[1].trim());
          final bStart = _timeToMinutes(lectureB.time.split('-')[0].trim());
          final bEnd = _timeToMinutes(lectureB.time.split('-')[1].trim());

          if (aStart < bEnd && aEnd > bStart) {
            lectureA.hasClash = true;
            lectureB.hasClash = true;
          } else {
            break;
          }
        }
      }
    }
  }

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _refreshTimetable() {
    setState(() {
      _timetableFuture = _storage.loadTimetable().then((t) {
        _detectClashes(t);
        return t;
      });
    });
  }

  List<String> getStartTimes() {
    return List.generate(17, (i) {
      final hour = 6 + i;
      return '${hour.toString().padLeft(2, '0')}:30';
    });
  }

  List<String> getEndTimes() {
    return List.generate(17, (i) {
      final hour = 7 + i;
      return '${hour.toString().padLeft(2, '0')}:30';
    });
  }

  void _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();
    String? eventName;
    String? venue;
    String? selectedType = eventTypes.first;
    String? startTime = getStartTimes().first;
    String? endTime = getEndTimes().first;
    String? selectedDay = DateFormat('EEEE').format(DateTime.now());

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Event'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => eventName = v,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Venue'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => venue = v,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items:
                          eventTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => selectedType = v,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      items:
                          days
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day['full'],
                                  child: Text(day['abbrev']!),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => selectedDay = v,
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                    DropdownButtonFormField<String>(
                      value: startTime,
                      items:
                          getStartTimes()
                              .map(
                                (time) => DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => startTime = v,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: endTime,
                      items:
                          getEndTimes()
                              .map(
                                (time) => DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => endTime = v,
                      decoration: const InputDecoration(labelText: 'End Time'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final newEvent = LectureData(
                      module: eventName!,
                      offered: '',
                      group: '',
                      language: '',
                      activity: selectedType!,
                      day: selectedDay!,
                      time: '$startTime - $endTime',
                      venue: venue!,
                      campus: '',
                      studyProg: '',
                    );

                    final timetable = await _timetableFuture;
                    timetable.add(newEvent);
                    await _storage.saveTimetable(timetable);
                    _refreshTimetable();

                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monday = _getMondayOfCurrentWeek(DateTime.now());
    final weekText =
        'Week of ${DateFormat('MMM dd').format(monday)}, ${DateTime.now().year}';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 40,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: _buildAppBarBackground(context, weekText),
      ),
      drawer: _buildAppDrawer(context),
      body: FutureBuilder<List<LectureData>>(
        future: _timetableFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final timetable = snapshot.data ?? [];

          return Stack(
            children: [
              Row(
                key: const Key('timetableRow'),
                children: [
                  TimeBar(controller: timeBarController),
                  Expanded(
                    child: WeeklyScrollView(
                      controllers: dayControllers,
                      timetable: timetable,
                      scrollOffset: scrollOffset,
                      onClashResolution:
                          (selected, clashes) => _handleClashResolution(
                            selected,
                            clashes,
                            timetable,
                          ),
                    ),
                  ),
                ],
              ),
              _buildCurrentTimeIndicator(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF50E3C2),
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
            leading: const Icon(Icons.build),
            title: const Text('Generate'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GenerateScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
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
              color: Color(0xFF4A90E2),
            ), // Use one of the app's theme colors
            title: const Text('Monthly Calendar'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MonthlyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
