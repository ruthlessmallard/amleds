import 'dart:async';
import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../models/ping_result.dart';
import '../models/settings.dart';
import '../services/ping_service.dart';
import '../services/storage_service.dart';
import '../theme/retro_terminal_theme.dart';

import '../widgets/ping_history_chart.dart';

class MonitorScreen extends StatefulWidget {
  final Machine machine;

  const MonitorScreen({super.key, required this.machine});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final StorageService _storage = StorageService();
  late PingService _pingService;
  AppSettings _settings = AppSettings();

  final Map<String, PingResult> _latestResults = {};
  final Map<String, List<PingResult>> _history = {};
  final Map<String, StreamSubscription<PingResult>> _subscriptions = {};

  bool _isMonitoring = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _storage.loadSettings();
    _pingService = PingService(settings: _settings);
    _startMonitoring();
  }

  void _startMonitoring() {
    for (final ip in widget.machine.ipAddresses) {
      _subscriptions[ip] = _pingService.startMonitoring(ip).listen((result) {
        if (mounted) {
          setState(() {
            _latestResults[ip] = result;
            _history[ip] = _pingService.getHistory(ip);
          });
        }
      });
    }
  }

  void _stopMonitoring() {
    for (final ip in widget.machine.ipAddresses) {
      _subscriptions[ip]?.cancel();
    }
    _pingService.stopAll();
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
      if (_isMonitoring) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    });
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTerminalTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.machine.name.toUpperCase(),
              style: RetroTerminalTheme.terminalHeader.copyWith(
                fontSize: 16,
              ),
            ),
            Text(
              '${widget.machine.ipAddresses.length} ENDPOINT${widget.machine.ipAddresses.length == 1 ? '' : 'S'}',
              style: RetroTerminalTheme.terminalText.copyWith(
                fontSize: 11,
                color: RetroTerminalTheme.amberDim,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isMonitoring
                  ? RetroTerminalTheme.vitalsStable.withOpacity(0.1)
                  : RetroTerminalTheme.vitalsFlatline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isMonitoring
                    ? RetroTerminalTheme.vitalsStable
                    : RetroTerminalTheme.vitalsFlatline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isMonitoring
                        ? RetroTerminalTheme.vitalsStable
                        : RetroTerminalTheme.vitalsFlatline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isMonitoring ? 'ACTIVE' : 'PAUSED',
                  style: RetroTerminalTheme.terminalText.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isMonitoring
                        ? RetroTerminalTheme.vitalsStable
                        : RetroTerminalTheme.vitalsFlatline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isMonitoring ? Icons.pause : Icons.play_arrow,
              color: RetroTerminalTheme.amberColor,
            ),
            onPressed: _toggleMonitoring,
            tooltip: _isMonitoring ? 'PAUSE' : 'RESUME',
          ),
        ],
      ),
      body: CRTScanlines(
        child: Column(
          children: [
            // Vitals Monitor Header
            _buildVitalsHeader(),
            
            // Status Summary - Vitals Style
            _buildVitalsSummary(),
            
            // Legend
            _buildLegend(),

            // IP Status List - Vitals Monitor Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.machine.ipAddresses.length,
                itemBuilder: (context, index) {
                  final ip = widget.machine.ipAddresses[index];
                  return _buildVitalsCard(ip);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: RetroTerminalTheme.amberDim,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_heart,
            color: RetroTerminalTheme.amberColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'VITALS MONITOR',
            style: RetroTerminalTheme.terminalHeader.copyWith(
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            'ID: ${widget.machine.id.substring(widget.machine.id.length - 4).toUpperCase()}',
            style: RetroTerminalTheme.terminalText.copyWith(
              fontSize: 11,
              color: RetroTerminalTheme.amberDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSummary() {
    final total = widget.machine.ipAddresses.length;
    final stable = _latestResults.values
        .where((r) => r.status == PingStatus.excellent)
        .length;
    final caution = _latestResults.values
        .where((r) => r.status == PingStatus.fair)
        .length;
    final critical = _latestResults.values
        .where((r) => r.status == PingStatus.poor)
        .length;
    final flatline = _latestResults.values
        .where((r) => r.status == PingStatus.timeout)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: RetroTerminalTheme.amberDim,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitalStat('STABLE', stable, total, RetroTerminalTheme.vitalsStable),
          _buildVitalStat('CAUTION', caution, total, RetroTerminalTheme.vitalsCaution),
          _buildVitalStat('CRITICAL', critical, total, RetroTerminalTheme.vitalsCritical),
          _buildVitalStat('FLATLINE', flatline, total, RetroTerminalTheme.vitalsFlatline),
        ],
      ),
    );
  }

  Widget _buildVitalStat(String label, int count, int total, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: RetroTerminalTheme.terminalHeader.copyWith(
                  color: color,
                  fontSize: 20,
                ),
              ),
              Text(
                '/$total',
                style: RetroTerminalTheme.terminalText.copyWith(
                  color: color.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: RetroTerminalTheme.terminalText.copyWith(
            fontSize: 10,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem('STABLE (<${_settings.excellentThreshold}ms)', RetroTerminalTheme.vitalsStable),
          _buildLegendItem('CAUTION (<${_settings.fairThreshold}ms)', RetroTerminalTheme.vitalsCaution),
          _buildLegendItem('CRITICAL (>${_settings.fairThreshold}ms)', RetroTerminalTheme.vitalsCritical),
          _buildLegendItem('FLATLINE', RetroTerminalTheme.vitalsFlatline),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: RetroTerminalTheme.terminalText.copyWith(
            fontSize: 10,
            color: RetroTerminalTheme.amberDim,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsCard(String ip) {
    final result = _latestResults[ip];
    final history = _history[ip] ?? [];
    final statusColor = _getVitalsColor(result?.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with IP and Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
            child: Row(
              children: [
                // Status pulse indicator
                _buildPulseIndicator(result?.status),
                const SizedBox(width: 12),
                
                // IP Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENDPOINT',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 9,
                          color: RetroTerminalTheme.amberDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ip,
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                if (result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getVitalsLabel(result.status).toUpperCase(),
                      style: RetroTerminalTheme.terminalText.copyWith(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Response Time Display
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Large response time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESPONSE TIME',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 10,
                          color: RetroTerminalTheme.amberDim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (result != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              result.responseTimeMs != null
                                  ? '${result.responseTimeMs}'
                                  : '---',
                              style: RetroTerminalTheme.terminalHeader.copyWith(
                                fontSize: 36,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              result.responseTimeMs != null ? 'ms' : '',
                              style: RetroTerminalTheme.terminalText.copyWith(
                                color: statusColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        if (result.error != null)
                          Text(
                            result.error!.toUpperCase(),
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontSize: 11,
                              color: RetroTerminalTheme.vitalsCritical,
                            ),
                          ),
                      ] else ...[
                        Row(
                          children: [
                            const BlinkingCursor(
                              width: 12,
                              height: 24,
                              color: RetroTerminalTheme.amberDim,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ACQUIRING SIGNAL...',
                              style: RetroTerminalTheme.terminalText.copyWith(
                                color: RetroTerminalTheme.amberDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Rolling stats
                if (result != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // AVG
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AVG ',
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontSize: 9,
                              color: RetroTerminalTheme.amberDim,
                            ),
                          ),
                          Text(
                            '${_calculateAverage(history)}',
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: RetroTerminalTheme.amberColor,
                            ),
                          ),
                          Text(
                            ' ms',
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontSize: 9,
                              color: RetroTerminalTheme.amberDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // PEAK
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PEAK ',
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontSize: 9,
                              color: RetroTerminalTheme.amberDim,
                            ),
                          ),
                          Text(
                            _getPeakDisplay(history),
                            style: RetroTerminalTheme.terminalText.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _getPeakColor(history),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // History Chart
          if (history.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORY',
                    style: RetroTerminalTheme.terminalText.copyWith(
                      fontSize: 9,
                      color: RetroTerminalTheme.amberDim,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PingHistoryChart(history: history),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(PingStatus? status) {
    final color = _getVitalsColor(status);
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Color _getVitalsColor(PingStatus? status) {
    switch (status) {
      case PingStatus.excellent:
        return RetroTerminalTheme.vitalsStable;
      case PingStatus.fair:
        return RetroTerminalTheme.vitalsCaution;
      case PingStatus.poor:
        return RetroTerminalTheme.vitalsCritical;
      case PingStatus.timeout:
      case null:
        return RetroTerminalTheme.vitalsFlatline;
      default:
        return RetroTerminalTheme.vitalsFlatline;
    }
  }

  String _getVitalsLabel(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return 'STABLE';
      case PingStatus.fair:
        return 'CAUTION';
      case PingStatus.poor:
        return 'CRITICAL';
      case PingStatus.timeout:
        return 'FLATLINE';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  int _calculateAverage(List<PingResult> history) {
    final valid = history.where((r) => r.responseTimeMs != null).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<int>(0, (a, b) => a + b.responseTimeMs!);
    return (sum / valid.length).round();
  }

  int? _calculatePeak(List<PingResult> history) {
    // Check if any timeout exists - that's the "worst" peak
    final hasTimeout = history.any((r) => r.responseTimeMs == null);
    if (hasTimeout) return null; // Timeout is OL/overload
    
    // Otherwise find highest valid ping
    final valid = history.where((r) => r.responseTimeMs != null).toList();
    if (valid.isEmpty) return null; // Empty history
    return valid.map((r) => r.responseTimeMs!).reduce((a, b) => a > b ? a : b);
  }

  String _getPeakDisplay(List<PingResult> history) {
    final peak = _calculatePeak(history);
    if (peak == null) return 'OL'; // Timeout = overload/flatline like a DMM
    return '$peak ms';
  }

  Color _getPeakColor(List<PingResult> history) {
    final peak = _calculatePeak(history);
    if (peak == null) return RetroTerminalTheme.vitalsFlatline; // Timeout
    if (peak > _settings.fairThreshold) return RetroTerminalTheme.vitalsCritical;
    if (peak > _settings.excellentThreshold) return RetroTerminalTheme.vitalsCaution;
    return RetroTerminalTheme.vitalsStable;
  }
}
