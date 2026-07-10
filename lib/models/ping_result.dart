enum PingStatus {
  excellent,  // < 50ms
  fair,       // 50-200ms
  poor,       // > 200ms
  timeout,    // no response
}

class PingResult {
  final String ipAddress;
  final int? responseTimeMs;
  final PingStatus status;
  final DateTime timestamp;
  final String? error;

  PingResult({
    required this.ipAddress,
    this.responseTimeMs,
    required this.status,
    required this.timestamp,
    this.error,
  });

  factory PingResult.fromResponse(String ip, int? responseTime) {
    PingStatus status;
    if (responseTime == null) {
      status = PingStatus.timeout;
    } else if (responseTime < 50) {
      status = PingStatus.excellent;
    } else if (responseTime < 200) {
      status = PingStatus.fair;
    } else {
      status = PingStatus.poor;
    }

    return PingResult(
      ipAddress: ip,
      responseTimeMs: responseTime,
      status: status,
      timestamp: DateTime.now(),
    );
  }

  factory PingResult.timeout(String ip) {
    return PingResult(
      ipAddress: ip,
      responseTimeMs: null,
      status: PingStatus.timeout,
      timestamp: DateTime.now(),
      error: 'Timeout',
    );
  }

  factory PingResult.error(String ip, String errorMessage) {
    return PingResult(
      ipAddress: ip,
      responseTimeMs: null,
      status: PingStatus.timeout,
      timestamp: DateTime.now(),
      error: errorMessage,
    );
  }
}
