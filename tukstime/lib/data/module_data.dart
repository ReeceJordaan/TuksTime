class ModuleData {
  final String module;
  final String venues; // Semicolon-separated list.
  final String campuses; // Semicolon-separated list.
  final String offered; // Semicolon-separated list (e.g. "S1; Y")

  ModuleData({
    required this.module,
    required this.venues,
    required this.campuses,
    required this.offered,
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

  /// JSON serialization methods.
  factory ModuleData.fromJson(Map<String, dynamic> json) {
    return ModuleData(
      module: json['module'],
      venues: json['venues'],
      campuses: json['campuses'],
      offered: json['offered'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'venues': venues,
      'campuses': campuses,
      'offered': offered,
    };
  }

  @override
  String toString() =>
      '$module (Venues: $venues, Campuses: $campuses, Offered: $offered)';
}
