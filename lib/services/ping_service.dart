import 'dart:async';
import 'dart:io';
import '../models/ping_result.dart';
import '../models/settings.dart';

/// Shell ping result parser
class PingParser {
  // Parse lines like: "64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=1.23 ms"
  // Or: "time=1 ms" (integers)
  // Or timeout with no matching line
  static int? parseTime(String output) {
    final timeRegex = RegExp(r'time=([0-9.]+)\s*ms');
    final match = timeRegex.firstMatch(output);
    if (match != null) {
      try {
        return (double.parse(match.group(1)!) * 1000).toInt(); // Convert to microseconds if needed, but usually ms
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool isUnreachable(String output) {
    return output.toLowerCase().contains('unreachable') ||
           output.toLowerCase().contains('timed out') ||
           output.toLowerCase().contains('100% packet loss') ||
           output.toLowerCase().contains('0 received');
  }

  static bool isSuccess(String output) {
    return output.toLowerCase().contains('bytes from');
  }
}

class PingService {
  final AppSettings settings;
  final Map<String, Process> _activePings = {};
  final Map<String, StreamController<PingResult>> _controllers = {};
  final Map<String, List<PingResult>> _history = {};
  final Map<String, bool> _stopFlags = {};

  PingService({required this.settings});

  Stream<PingResult> startMonitoring(String ipAddress) {
    if (_controllers.containsKey(ipAddress)) {
      return _controllers[ipAddress]!.stream;
    }

    final controller = StreamController<PingResult>.broadcast();
    _controllers[ipAddress] = controller;
    _history[ipAddress] = [];

    _startPing(ipAddress, controller);

    return controller.stream;
  }

  void _startPing(String ipAddress, StreamController<PingResult> controller) async {
    _stopFlags[ipAddress] = false;
    
    while (!controller.isClosed && !_stopFlags[ipAddress]!) {
      try {
        // Use system ping binary - works without root on most Android
        // -c 1 = 1 packet
        // -W 5 = 5 second timeout  
        // -n = no DNS lookup (faster)
        final process = await Process.start(
          '/system/bin/ping',
          ['-c', '1', '-W', '5', '-n', ipAddress],
        );
        _activePings[ipAddress] = process;

        // Collect all output
        final output = await process.stdout.transform(const SystemEncoding().decoder).join();
        final error = await process.stderr.transform(const SystemEncoding().decoder).join();
        final exitCode = await process.exitCode;

        PingResult result;
        
        if (exitCode == 0 && PingParser.isSuccess(output)) {
          // Successful ping
          final timeMs = PingParser.parseTime(output);
          result = PingResult.fromResponse(ipAddress, timeMs);
        } else if (PingParser.isUnreachable(output) || PingParser.isUnreachable(error)) {
          // Host unreachable or timeout
          result = PingResult.timeout(ipAddress);
        } else if (error.isNotEmpty) {
          // Other error
          result = PingResult.error(ipAddress, error.trim());
        } else {
          // Assume timeout
          result = PingResult.timeout(ipAddress);
        }

        _addToHistory(ipAddress, result);
        if (!controller.isClosed) {
          controller.add(result);
        }
      } catch (e) {
        // Process start failed - maybe ping binary not available
        final result = PingResult.error(ipAddress, 'Ping failed: $e');
        _addToHistory(ipAddress, result);
        if (!controller.isClosed) {
          controller.add(result);
        }
      } finally {
        _activePings.remove(ipAddress);
      }

      // Wait for next ping cycle
      await Future.delayed(Duration(milliseconds: settings.pingIntervalMs));
    }
  }

  void _addToHistory(String ipAddress, PingResult result) {
    _history[ipAddress] ??= [];
    _history[ipAddress]!.add(result);
    
    // Keep only last N results
    while (_history[ipAddress]!.length > settings.maxHistorySize) {
      _history[ipAddress]!.removeAt(0);
    }
  }

  List<PingResult> getHistory(String ipAddress) {
    return List.unmodifiable(_history[ipAddress] ?? []);
  }

  void stopMonitoring(String ipAddress) {
    _stopFlags[ipAddress] = true;
    _activePings[ipAddress]?.kill();
    _activePings.remove(ipAddress);
    _controllers[ipAddress]?.close();
    _controllers.remove(ipAddress);
    _history.remove(ipAddress);
    _stopFlags.remove(ipAddress);
  }

  void stopAll() {
    for (final ip in _activePings.keys.toList()) {
      stopMonitoring(ip);
    }
  }

  void updateSettings(AppSettings newSettings) {
    // Settings will take effect on next ping cycle
  }
}
