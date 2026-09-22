import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/machine.dart';
import '../models/ping_result.dart';

class ExportService {
  /// Export ping history as a timestamped CSV and share via system share sheet
  static Future<void> exportSessionLogs({
    required Machine machine,
    required Map<String, List<PingResult>> history,
  }) async {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('timestamp,endpoint,response_ms,status');
    
    // Flatten all endpoint histories into chronological rows
    final rows = <_CsvRow>[];
    history.forEach((endpoint, results) {
      for (final r in results) {
        rows.add(_CsvRow(
          timestamp: r.timestamp,
          endpoint: endpoint,
          responseMs: r.responseTimeMs,
          status: _statusName(r.status),
        ));
      }
    });
    
    // Sort by timestamp
    rows.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (final row in rows) {
      final ms = row.responseMs?.toString() ?? '';
      buffer.writeln(
        '${_formatIso(row.timestamp)},${row.endpoint},$ms,${row.status}',
      );
    }
    
    final csv = buffer.toString();
    
    // Write to temp file
    final dir = await getTemporaryDirectory();
    final safeMachineName = machine.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = _formatFileTimestamp(DateTime.now());
    final fileName = 'amleds_${safeMachineName}_$timestamp.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);
    
    // Share via system share sheet
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'AMLEDS Export: ${machine.name}',
    );
  }
  
  static String _statusName(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return 'excellent';
      case PingStatus.fair:
        return 'fair';
      case PingStatus.poor:
        return 'poor';
      case PingStatus.timeout:
        return 'timeout';
    }
  }
  
  static String _formatIso(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }
  
  static String _formatFileTimestamp(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}_${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}';
  }
  
  static String _pad(int n) => n.toString().padLeft(2, '0');
}

class _CsvRow {
  final DateTime timestamp;
  final String endpoint;
  final int? responseMs;
  final String status;
  
  _CsvRow({
    required this.timestamp,
    required this.endpoint,
    required this.responseMs,
    required this.status,
  });
}
