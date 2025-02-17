class ModuleData {
  final String module;
  final String venues; // Semicolon-separated list.
  final String campuses; // Semicolon-separated list.
  final String offered; // Semicolon-separated list (e.g. "S1; Y")

  // New mutable fields for user selections.
  String? selectedPeriod;
  String? selectedLectureGroup;
  String? selectedTutorialGroup;
  String? selectedPracticalGroup;

  ModuleData({
    required this.module,
    required this.venues,
    required this.campuses,
    required this.offered,
    this.selectedPeriod,
    this.selectedLectureGroup,
    this.selectedTutorialGroup,
    this.selectedPracticalGroup,
  });

  /// Parses a row from modules.csv and removes any spaces from the module code.
  /// Assumes CSV order: Module, Venues, Campuses, Offered.
  factory ModuleData.fromModulesCsv(List<String> values) {
    return ModuleData(
      module: values[0].replaceAll(' ', '').trim(),
      venues: values[1].trim(),
      campuses: values[2].trim(),
      offered: values[3].trim(),
    );
  }

  /// JSON deserialization.
  factory ModuleData.fromJson(Map<String, dynamic> json) {
    return ModuleData(
      module: json['module'],
      venues: json['venues'],
      campuses: json['campuses'],
      offered: json['offered'],
      selectedPeriod: json['selectedPeriod'],
      selectedLectureGroup: json['selectedLectureGroup'],
      selectedTutorialGroup: json['selectedTutorialGroup'],
      selectedPracticalGroup: json['selectedPracticalGroup'],
    );
  }

  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'venues': venues,
      'campuses': campuses,
      'offered': offered,
      'selectedPeriod': selectedPeriod,
      'selectedLectureGroup': selectedLectureGroup,
      'selectedTutorialGroup': selectedTutorialGroup,
      'selectedPracticalGroup': selectedPracticalGroup,
    };
  }

  @override
  String toString() =>
      '$module (Venues: $venues, Campuses: $campuses, Offered: $offered)';
}
