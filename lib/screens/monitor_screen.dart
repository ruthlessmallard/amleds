import 'dart:async';
import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../models/ping_result.dart';
import '../models/settings.dart';
import '../services/ping_service.dart';
import '../services/storage_service.dart';
import '../theme/retro_terminal_theme.dart';

import '../widgets/ping_history_chart.dart';
import '../widgets/aggregated_endpoint_chart.dart';

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
            // Aggregated Endpoints Chart Header
            _buildAggregatedHeader(),
            
            // All Endpoints Chart
            AggregatedEndpointChart(
              allHistory: _history,
              height: 140,
              criticalThreshold: _settings.fairThreshold, // Use fair threshold as critical ceiling
            ),
            
            // Chart Legend (replaces individual cards)
            AggregatedChartLegend(
              allHistory: _history,
              latestResults: _latestResults,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAggregatedHeader() {
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
            Icons.timeline,
            color: RetroTerminalTheme.amberColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'AGGREGATED ENDPOINTS',
            style: RetroTerminalTheme.terminalHeader.copyWith(
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.machine.ipAddresses.length} ENDPOINTS ACTIVE',
            style: RetroTerminalTheme.terminalText.copyWith(
              fontSize: 11,
              color: RetroTerminalTheme.amberDim,
            ),
          ),
        ],
      ),
    );
  }

  // _buildVitalsHeader() removed - replaced by _buildAggregatedHeader()

  // _buildVitalsSummary() removed - replaced by AggregatedEndpointChart

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

  // _buildLegend() removed - replaced by AggregatedChartLegend

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

  // _buildVitalsCard() removed - replaced by AggregatedChartLegend

  // _buildPulseIndicator() removed - replaced by AggregatedChartLegend

  // _getVitalsColor() removed - replaced by AggregatedChartLegend color logic

  // _getVitalsLabel() removed - replaced by AggregatedChartLegend

  // _formatTime() removed - unused after vitals replacement

  // _calculateAverage() moved to AggregatedChartLegend

  // _calculatePeak() moved to AggregatedChartLegend

  // _getPeakDisplay() moved to AggregatedChartLegend

  // _getPeakColor() moved to AggregatedChartLegend
}
