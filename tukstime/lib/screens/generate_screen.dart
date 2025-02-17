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

  // Store all lectures loaded from CSV.
  List<LectureData> _allLectures = [];

  static const String _customModulesKey = 'customModules';

  @override
  void initState() {
    super.initState();
    _loadModuleCsv();
    _loadCustomModules();
    _loadLecturesCsv().then((lectures) {
      setState(() {
        _allLectures = lectures;
      });
    });
  }

  /// Helper function to format group codes.
  String formatGroupCode(String code) {
    // Return unchanged if it's one of our extra options.
    if (code == "Any group" || code == "Dont need") return code;
    // Get first character and number part (removing any leading zeros).
    final letter = code[0].toUpperCase();
    final numberPart = code.substring(1).replaceFirst(RegExp(r'^0+'), '');
    switch (letter) {
      case 'L':
      case 'G':
        return "Group $numberPart";
      case 'T':
        return "Tutorial $numberPart";
      case 'P':
        return "Practical $numberPart";
      default:
        return code;
    }
  }

  /// Loads the modules CSV from assets.
  Future<bool> _loadModuleCsv() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final csvString = await rootBundle.loadString('assets/modules.csv');
      final lines = csvString.split('\n');
      final List<ModuleData> modules = [];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
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

  /// Shows a custom snack bar.
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

  // Builds the global refresh button.
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

  /// Builds a gradient button.
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
                  fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  /// When a semester or quarter button is tapped.
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

    for (final lecture in lectures) {
      lecture.hasClash = false;
    }

    for (final lecture in lectures) {
      dayLectures.putIfAbsent(lecture.day, () => []).add(lecture);
    }

    for (final day in dayLectures.keys) {
      final dailyLectures = dayLectures[day]!
        ..sort((a, b) => _timeToMinutes(a.time.split('-')[0].trim())
            .compareTo(_timeToMinutes(b.time.split('-')[0].trim())));

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

  @override
  Widget build(BuildContext context) {
    // (Timetable buttons and autocomplete code omitted for brevity.)
    final List<Widget> timetableButtons = <Widget>[];
    // ... (build timetable buttons as before) ...

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
                    ...timetableButtons,
                    const SizedBox(height: 20),
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
                        FocusScope.of(context).requestFocus(FocusNode());
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

                              // Extract real data from lectures for this module.
                              final moduleLectures = _allLectures
                                  .where((lecture) =>
                                      lecture.module.toLowerCase() ==
                                      module.module.toLowerCase())
                                  .toList();

                              // Unique period options (trimmed & sorted).
                              final periodOptions = moduleLectures
                                  .map((l) => l.offered.trim())
                                  .toSet()
                                  .toList();
                              periodOptions.sort();

                              // Unique groups per activity type (trimmed & sorted).
                              final lectureGroups = moduleLectures
                                  .where((l) =>
                                      l.activity.toUpperCase().startsWith("L"))
                                  .map((l) => l.group.trim())
                                  .toSet()
                                  .toList();
                              lectureGroups.sort();
                              lectureGroups.removeWhere((g) =>
                                  g.toLowerCase() == "any group" ||
                                  g.toLowerCase() == "dont need");

                              final tutorialGroups = moduleLectures
                                  .where((l) =>
                                      l.activity.toUpperCase().startsWith("T"))
                                  .map((l) => l.group.trim())
                                  .toSet()
                                  .toList();
                              tutorialGroups.sort();
                              tutorialGroups.removeWhere((g) =>
                                  g.toLowerCase() == "any group" ||
                                  g.toLowerCase() == "dont need");

                              final practicalGroups = moduleLectures
                                  .where((l) =>
                                      l.activity.toUpperCase().startsWith("P"))
                                  .map((l) => l.group.trim())
                                  .toSet()
                                  .toList();
                              practicalGroups.sort();
                              practicalGroups.removeWhere((g) =>
                                  g.toLowerCase() == "any group" ||
                                  g.toLowerCase() == "dont need");

                              // For group dropdowns, add extra options if data exists.
                              final List<String> lectureGroupOptions =
                                  lectureGroups.isNotEmpty
                                      ? ["Any group", "Dont need"] +
                                          lectureGroups
                                      : [];
                              final List<String> tutorialGroupOptions =
                                  tutorialGroups.isNotEmpty
                                      ? ["Any group", "Dont need"] +
                                          tutorialGroups
                                      : [];
                              final List<String> practicalGroupOptions =
                                  practicalGroups.isNotEmpty
                                      ? ["Any group", "Dont need"] +
                                          practicalGroups
                                      : [];

                              // Validate stored values.
                              String lectureGroupValue =
                                  module.selectedLectureGroup ?? "Any group";
                              if (!lectureGroupOptions
                                  .contains(lectureGroupValue)) {
                                lectureGroupValue = "Any group";
                              }
                              String tutorialGroupValue =
                                  module.selectedTutorialGroup ?? "Any group";
                              if (!tutorialGroupOptions
                                  .contains(tutorialGroupValue)) {
                                tutorialGroupValue = "Any group";
                              }
                              String practicalGroupValue =
                                  module.selectedPracticalGroup ?? "Any group";
                              if (!practicalGroupOptions
                                  .contains(practicalGroupValue)) {
                                practicalGroupValue = "Any group";
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            module.module,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
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
                                              onPressed: () =>
                                                  _removeModule(module),
                                              tooltip: 'Remove Module',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Period dropdown with title.
                                      if (periodOptions.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Period"),
                                            DropdownButton<String>(
                                              isExpanded: true,
                                              value: module.selectedPeriod ??
                                                  periodOptions.first,
                                              items: periodOptions
                                                  .map((option) =>
                                                      DropdownMenuItem<String>(
                                                        value: option,
                                                        child: Text(option),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  module.selectedPeriod = value;
                                                  _saveCustomModules();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      // Lecture group dropdown with title.
                                      if (lectureGroupOptions.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Lecture Group"),
                                            DropdownButton<String>(
                                              isExpanded: true,
                                              value: lectureGroupValue,
                                              items: lectureGroupOptions
                                                  .map((option) =>
                                                      DropdownMenuItem<String>(
                                                        value: option,
                                                        child: Text(
                                                            formatGroupCode(
                                                                option)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  module.selectedLectureGroup =
                                                      value;
                                                  _saveCustomModules();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      // Tutorial group dropdown with title.
                                      if (tutorialGroupOptions.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Tutorial Group"),
                                            DropdownButton<String>(
                                              isExpanded: true,
                                              value: tutorialGroupValue,
                                              items: tutorialGroupOptions
                                                  .map((option) =>
                                                      DropdownMenuItem<String>(
                                                        value: option,
                                                        child: Text(
                                                            formatGroupCode(
                                                                option)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  module.selectedTutorialGroup =
                                                      value;
                                                  _saveCustomModules();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      // Practical group dropdown with title.
                                      if (practicalGroupOptions.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Practical Group"),
                                            DropdownButton<String>(
                                              isExpanded: true,
                                              value: practicalGroupValue,
                                              items: practicalGroupOptions
                                                  .map((option) =>
                                                      DropdownMenuItem<String>(
                                                        value: option,
                                                        child: Text(
                                                            formatGroupCode(
                                                                option)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  module.selectedPracticalGroup =
                                                      value;
                                                  _saveCustomModules();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
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
