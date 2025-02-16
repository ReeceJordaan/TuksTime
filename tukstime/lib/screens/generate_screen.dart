// generate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tukstime/data/module_data.dart';
import 'package:tukstime/data/lecture_data.dart';
import 'package:tukstime/services/timetable_storage.dart';
import 'package:tukstime/screens/weekly_screen.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen>
    with TickerProviderStateMixin {
  final TimetableStorage _storage = TimetableStorage();
  List<ModuleData> _allModules = [];
  final List<ModuleData> _customModules = [];
  bool _isLoading = true;
  TextEditingController? _searchController;

  static const String _customModulesKey = 'customModules';

  @override
  void initState() {
    super.initState();
    _loadModuleCsv();
    _loadCustomModules();
  }

  /// Loads the modules CSV from assets using the new layout.
  /// Returns true if the update was successful, false otherwise.
  Future<bool> _loadModuleCsv() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final csvString = await rootBundle.loadString('assets/modules.csv');
      final lines = csvString.split('\n');
      // Assume the first line is the header.
      final List<ModuleData> modules = [];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        // Split by comma. (Adjust if your CSV has commas within quotes.)
        final values = line.split(',');
        if (values.length >= 3) {
          modules.add(ModuleData.fromModulesCsv(values));
        }
      }
      setState(() {
        _allModules = modules;
        _isLoading = false;
      });
      return true;
    } catch (e) {
      debugPrint('Error loading modules CSV: $e');
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  /// Loads the lectures CSV from assets.
  Future<List<LectureData>> _loadLecturesCsv() async {
    final csvString = await rootBundle.loadString('assets/lectures.csv');
    final lines = csvString.split('\n');
    final List<LectureData> lectures = [];
    // Assume the first line is header.
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final values = line.split(',');
      if (values.length >= 9) {
        lectures.add(LectureData.fromCsv(values));
      }
    }
    return lectures;
  }

  /// Saves the custom modules list locally as JSON.
  Future<void> _saveCustomModules() async {
    final prefs = await SharedPreferences.getInstance();
    final modulesJson = _customModules.map((m) => m.toJson()).toList();
    await prefs.setString(_customModulesKey, jsonEncode(modulesJson));
  }

  /// Loads the custom modules list from local storage.
  Future<void> _loadCustomModules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customModulesKey);
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        _customModules.clear();
        _customModules
            .addAll(jsonData.map((data) => ModuleData.fromJson(data)).toList());
      });
    }
  }

  /// Global refresh button handler.
  Future<void> _handleRefresh() async {
    final success = await _loadModuleCsv();
    _showCustomSnackBar(
      success ? 'Modules updated successfully!' : 'Modules update failed!',
      success,
    );
  }

  /// Shows a custom snack bar that slides up from the bottom with a bounce,
  /// stays for a short duration, then slides down.
  void _showCustomSnackBar(String message, bool success) {
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      ),
    );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: offsetAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 16.0),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      animationController.reverse().then((value) {
        overlayEntry.remove();
        animationController.dispose();
      });
    });
  }

  // When a module is selected from the autocomplete, add it to custom modules.
  void _onModuleSelected(ModuleData selection) {
    if (!_customModules.any((m) =>
        m.module.trim().toLowerCase() ==
        selection.module.trim().toLowerCase())) {
      setState(() {
        _customModules.add(selection);
      });
      _saveCustomModules();
    }
  }

  // Removes a module from the custom modules list.
  void _removeModule(ModuleData module) {
    setState(() {
      _customModules.removeWhere((m) =>
          m.module.trim().toLowerCase() == module.module.trim().toLowerCase());
    });
    _saveCustomModules();
  }

  // Builds the global refresh (update) button with a gradient style.
  Widget _buildGlobalRefreshButton() {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _handleRefresh,
        tooltip: 'Refresh Modules',
      ),
    );
  }

  /// Builds a gradient button with the given text and onTap handler.
  Widget _buildSemesterButton(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// When a semester or quarter button is tapped, generate a timetable for that period.
  ///
  /// For Semester 1: modules with offered == "S1" or "Y"
  /// For Semester 2: modules with offered == "S2" or "Y"
  /// For Quarter 1: modules with offered == "Q1", "S1" or "Y"
  /// For Quarter 2: modules with offered == "Q2", "S1" or "Y"
  /// For Quarter 3: modules with offered == "Q3", "S2" or "Y"
  /// For Quarter 4: modules with offered == "Q4", "S2" or "Y"
  Future<void> _generateTimetable(String period) async {
    List<LectureData> lectures = await _loadLecturesCsv();
    List<String> selectedModules = _customModules.map((m) => m.module).toList();

    // 1. FILTER LECTURES FIRST
    List<String> validOfferings = _getValidOfferings(period);
    List<LectureData> filteredLectures = lectures.where((lecture) {
      return selectedModules.contains(lecture.module) &&
          validOfferings.contains(lecture.offered);
    }).toList();

    // 2. DETECT CLASHES IN FILTERED LECTURES
    _detectClashes(filteredLectures);

    await _storage.saveTimetable(filteredLectures);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WeeklyScreen()),
    );
  }

  List<String> _getValidOfferings(String period) {
    switch (period) {
      case "S1":
        return ["S1", "Y"];
      case "S2":
        return ["S2", "Y"];
      case "Q1":
        return ["Q1", "S1", "Y"];
      case "Q2":
        return ["Q2", "S1", "Y"];
      case "Q3":
        return ["Q3", "S2", "Y"];
      case "Q4":
        return ["Q4", "S2", "Y"];
      default:
        return [];
    }
  }

  void _detectClashes(List<LectureData> lectures) {
    final Map<String, List<LectureData>> dayLectures = {};

    // Reset clash status
    for (final lecture in lectures) {
      lecture.hasClash = false;
    }

    // Group lectures by day
    for (final lecture in lectures) {
      dayLectures.putIfAbsent(lecture.day, () => []).add(lecture);
    }

    // Check for overlaps within each day
    for (final day in dayLectures.keys) {
      final dailyLectures = dayLectures[day]!
        ..sort((a, b) => _timeToMinutes(a.time.split('-')[0].trim())
            .compareTo(_timeToMinutes(b.time.split('-')[0].trim())));

      // Check all pairs of lectures for overlap
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
            // Since lectures are sorted, no need to check further once no overlap
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

  @override
  Widget build(BuildContext context) {
    // Determine which offerings are present in the custom modules.
    bool hasS1 = _customModules
        .any((m) => m.offered.contains("S1") || m.offered.contains("Y"));
    bool hasQ1 = _customModules.any((m) => m.offered.contains("Q1"));
    bool hasQ2 = _customModules.any((m) => m.offered.contains("Q2"));

    bool hasS2 = _customModules
        .any((m) => m.offered.contains("S2") || m.offered.contains("Y"));
    bool hasQ3 = _customModules.any((m) => m.offered.contains("Q3"));
    bool hasQ4 = _customModules.any((m) => m.offered.contains("Q4"));

    // For each semester, if there are no quarter modules then show the semester button.
    // Otherwise, show the quarter buttons.
    bool showSemester1Button = hasS1 && !(hasQ1 || hasQ2);
    bool showSemester2Button = hasS2 && !(hasQ3 || hasQ4);

    // For quarter buttons we want to show the individual quarter buttons if quarter modules exist.
    // But if a semester module is also present (i.e. hasS1 or hasS2 is true), we “upgrade” to showing
    // both quarter buttons even if one quarter had no module explicitly selected.
    bool showQuarter1Button;
    bool showQuarter2Button;
    if (hasQ1 || hasQ2) {
      if (hasS1) {
        // With a semester module present, show the full quarter breakdown.
        showQuarter1Button = true;
        showQuarter2Button = true;
      } else {
        // Without a semester module, only show the quarter buttons that actually have quarter modules.
        showQuarter1Button = hasQ1;
        showQuarter2Button = hasQ2;
      }
    } else {
      showQuarter1Button = false;
      showQuarter2Button = false;
    }

    bool showQuarter3Button;
    bool showQuarter4Button;
    if (hasQ3 || hasQ4) {
      if (hasS2) {
        showQuarter3Button = true;
        showQuarter4Button = true;
      } else {
        showQuarter3Button = hasQ3;
        showQuarter4Button = hasQ4;
      }
    } else {
      showQuarter3Button = false;
      showQuarter4Button = false;
    }

    // Build a list of timetable buttons. The semester buttons are added only if their
    // corresponding conditions are met.
    final List<Widget> timetableButtons = <Widget>[];
    if (showSemester1Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Semester 1", () {
        _generateTimetable("S1");
      }));
    }
    if (showSemester2Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Semester 2", () {
        _generateTimetable("S2");
      }));
    }
    if (showQuarter1Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Quarter 1", () {
        _generateTimetable("Q1");
      }));
    }
    if (showQuarter2Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Quarter 2", () {
        _generateTimetable("Q2");
      }));
    }
    if (showQuarter3Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Quarter 3", () {
        _generateTimetable("Q3");
      }));
    }
    if (showQuarter4Button) {
      timetableButtons.add(_buildSemesterButton("Generate for Quarter 4", () {
        _generateTimetable("Q4");
      }));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Modules'),
        actions: [_buildGlobalRefreshButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display timetable buttons conditionally.
                    ...timetableButtons,
                    const SizedBox(height: 20),
                    // Autocomplete search bar.
                    Autocomplete<ModuleData>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<ModuleData>.empty();
                        }
                        final searchText =
                            textEditingValue.text.trim().toLowerCase();
                        return _allModules.where((ModuleData module) {
                          final moduleCode = module.module.trim().toLowerCase();
                          return !_customModules.any((custom) =>
                                  custom.module.trim().toLowerCase() ==
                                  moduleCode) &&
                              moduleCode.contains(searchText);
                        });
                      },
                      displayStringForOption: (ModuleData module) =>
                          module.module,
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        _searchController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search for modules',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              final searchText = value.trim().toLowerCase();
                              final matches = _allModules.where((module) {
                                final moduleCode =
                                    module.module.trim().toLowerCase();
                                return !_customModules.any((custom) =>
                                        custom.module.trim().toLowerCase() ==
                                        moduleCode) &&
                                    moduleCode.contains(searchText);
                              }).toList();
                              if (matches.isNotEmpty) {
                                _onModuleSelected(matches.first);
                                controller.clear();
                                focusNode.requestFocus();
                              }
                            }
                          },
                        );
                      },
                      onSelected: (ModuleData selection) {
                        _onModuleSelected(selection);
                        _searchController?.clear();
                        // Keep the field in focus.
                        FocusScope.of(context).requestFocus(FocusNode());
                        // Immediately re-request focus on the text field.
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Custom Modules',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _customModules.isEmpty
                        ? const Text(
                            'No custom modules selected.',
                            style: TextStyle(color: Colors.grey),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _customModules.length,
                            itemBuilder: (context, index) {
                              final module = _customModules[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(module.module),
                                  subtitle: Text(
                                      'Venues: ${module.venues}\nCampuses: ${module.campuses}'),
                                  trailing: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5F6D),
                                          Color(0xFFFFC371)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () => _removeModule(module),
                                      tooltip: 'Remove Module',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
