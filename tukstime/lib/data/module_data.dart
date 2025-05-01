/// Represents the data structure for a module in the TuksTime application.
///
/// This class encapsulates all the relevant information about a module,
/// including its code, venues, campuses, and offering periods. It also
/// includes user-selected data for specific groups and periods.
class ModuleData {
  /// The unique identifier for the module.
  final String module;

  /// A semicolon-separated list of venues where the module is taught.
  final String venues;

  /// A semicolon-separated list of campuses where the module is offered.
  final String campuses;

  /// A semicolon-separated list of periods when the module is offered (e.g., "S1; Y").
  final String offered;

  /// The user-selected study period for this module.
  String? selectedPeriod;

  /// The user-selected lecture group for this module.
  String? selectedLectureGroup;

  /// The user-selected tutorial group for this module.
  String? selectedTutorialGroup;

  /// The user-selected practical group for this module.
  String? selectedPracticalGroup;

  /// Constructs a [ModuleData] instance with the given parameters.
  ///
  /// The [module], [venues], [campuses], and [offered] parameters are required.
  /// The selected groups and period are optional.
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

  /// Creates a [ModuleData] instance from a CSV row.
  ///
  /// This factory method parses a row from the modules.csv file and creates
  /// a [ModuleData] instance. It assumes the CSV order is:
  /// Module, Venues, Campuses, Offered.
  ///
  /// The method also removes any spaces from the module code.
  factory ModuleData.fromModulesCsv(List<String> values) {
    return ModuleData(
      module: values[0].replaceAll(' ', '').trim(),
      venues: values[1].trim(),
      campuses: values[2].trim(),
      offered: values[3].trim(),
    );
  }

  /// Creates a [ModuleData] instance from a JSON map.
  ///
  /// This factory method deserializes a JSON object into a [ModuleData] instance.
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

  /// Converts this [ModuleData] instance to a JSON map.
  ///
  /// This method serializes the [ModuleData] instance into a JSON object.
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

  /// Returns a string representation of this [ModuleData] instance.
  @override
  String toString() =>
      '$module (Venues: $venues, Campuses: $campuses, Offered: $offered)';
}
