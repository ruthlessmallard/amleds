class AppSettings {
  int excellentThreshold;
  int fairThreshold;
  int pingIntervalMs;
  int maxHistorySize;

  AppSettings({
    this.excellentThreshold = 30,  // < 30ms = excellent (green)
    this.fairThreshold = 50,       // < 50ms = caution (yellow), >= 50ms = critical (red)
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
      excellentThreshold: json['excellentThreshold'] as int? ?? 30,
      fairThreshold: json['fairThreshold'] as int? ?? 50,
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
