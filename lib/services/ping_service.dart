import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import '../models/ping_result.dart';
import '../models/settings.dart';

class PingService {
  final AppSettings settings;
  final Map<String, Ping> _activePings = {};
  final Map<String, StreamController<PingResult>> _controllers = {};
  final Map<String, List<PingResult>> _history = {};

  PingService({required this.settings}) {
    DartPingIOS.register();
  }

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
    while (!controller.isClosed) {
      try {
        final ping = Ping(ipAddress, count: 1, timeout: 5);
        _activePings[ipAddress] = ping;

        await for (final event in ping.stream) {
          PingResult result;

          if (event.response != null) {
            final time = event.response!.time?.inMilliseconds;
            result = PingResult.fromResponse(ipAddress, time);
          } else if (event.error != null) {
            result = PingResult.error(ipAddress, event.error.toString());
          } else {
            result = PingResult.timeout(ipAddress);
          }

          _addToHistory(ipAddress, result);
          if (!controller.isClosed) {
            controller.add(result);
          }
        }
      } catch (e) {
        final result = PingResult.error(ipAddress, e.toString());
        _addToHistory(ipAddress, result);
        if (!controller.isClosed) {
          controller.add(result);
        }
      }

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
    _activePings[ipAddress]?.stop();
    _activePings.remove(ipAddress);
    _controllers[ipAddress]?.close();
    _controllers.remove(ipAddress);
    _history.remove(ipAddress);
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
