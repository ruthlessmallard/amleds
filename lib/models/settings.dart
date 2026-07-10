class AppSettings {
  int excellentThreshold;
  int fairThreshold;
  int pingIntervalMs;
  int maxHistorySize;

  AppSettings({
    this.excellentThreshold = 50,
    this.fairThreshold = 200,
    this.pingIntervalMs = 1000,
    this.maxHistorySize = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'excellentThreshold': excellentThreshold,
      'fairThreshold': fairThreshold,
      'pingIntervalMs': pingIntervalMs,
      'maxHistorySize': maxHistorySize,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      excellentThreshold: json['excellentThreshold'] as int? ?? 50,
      fairThreshold: json['fairThreshold'] as int? ?? 200,
      pingIntervalMs: json['pingIntervalMs'] as int? ?? 1000,
      maxHistorySize: json['maxHistorySize'] as int? ?? 10,
    );
  }

  AppSettings copyWith({
    int? excellentThreshold,
    int? fairThreshold,
    int? pingIntervalMs,
    int? maxHistorySize,
  }) {
    return AppSettings(
      excellentThreshold: excellentThreshold ?? this.excellentThreshold,
      fairThreshold: fairThreshold ?? this.fairThreshold,
      pingIntervalMs: pingIntervalMs ?? this.pingIntervalMs,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
    );
  }
}
