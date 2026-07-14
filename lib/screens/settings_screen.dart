import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../theme/retro_terminal_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late AppSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  final _excellentController = TextEditingController();
  final _fairController = TextEditingController();
  final _intervalController = TextEditingController();
  final _historyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _excellentController.dispose();
    _fairController.dispose();
    _intervalController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _settings = await _storage.loadSettings();
    
    _excellentController.text = _settings.excellentThreshold.toString();
    _fairController.text = _settings.fairThreshold.toString();
    _intervalController.text = _settings.pingIntervalMs.toString();
    _historyController.text = _settings.maxHistorySize.toString();
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final newSettings = AppSettings(
      excellentThreshold: int.tryParse(_excellentController.text) ?? 50,
      fairThreshold: int.tryParse(_fairController.text) ?? 200,
      pingIntervalMs: int.tryParse(_intervalController.text) ?? 1000,
      maxHistorySize: int.tryParse(_historyController.text) ?? 10,
    );

    await _storage.saveSettings(newSettings);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SETTINGS SAVED SUCCESSFULLY',
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.backgroundColor,
            ),
          ),
          backgroundColor: RetroTerminalTheme.vitalsStable,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _resetToDefaults() {
    setState(() {
      _excellentController.text = '50';
      _fairController.text = '200';
      _intervalController.text = '1000';
      _historyController.text = '10';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'DEFAULTS RESTORED - SAVE TO APPLY',
          style: RetroTerminalTheme.terminalText.copyWith(
            color: RetroTerminalTheme.backgroundColor,
          ),
        ),
        backgroundColor: RetroTerminalTheme.vitalsCaution,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTerminalTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'SYSTEM CONFIGURATION',
          style: RetroTerminalTheme.terminalHeader.copyWith(
            letterSpacing: 2,
          ),
        ),
      ),
      body: CRTScanlines(
        child: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RetroTerminalTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: RetroTerminalTheme.amberDim,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_applications,
                            color: RetroTerminalTheme.amberColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AMLEDS CONFIGURATION',
                                  style: RetroTerminalTheme.terminalHeader,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MODIFY SYSTEM PARAMETERS AND THRESHOLDS',
                                  style: RetroTerminalTheme.terminalText.copyWith(
                                    fontSize: 11,
                                    color: RetroTerminalTheme.amberDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Threshold Settings Section
                    TerminalHeader(
                      title: 'LATENCY THRESHOLDS',
                      subtitle: 'CONFIGURE VITALS MONITOR COLOR CODING',
                      icon: Icons.speed,
                    ),
                    const SizedBox(height: 20),

                    // Excellent Threshold - STABLE
                    _buildThresholdField(
                      controller: _excellentController,
                      label: 'STABLE THRESHOLD',
                      hint: '50',
                      suffix: 'ms',
                      icon: Icons.check_circle,
                      color: RetroTerminalTheme.vitalsStable,
                      description: 'RESPONSE TIMES BELOW THIS SHOW AS STABLE (GREEN)',
                    ),
                    const SizedBox(height: 20),

                    // Fair Threshold - CAUTION
                    _buildThresholdField(
                      controller: _fairController,
                      label: 'CAUTION THRESHOLD',
                      hint: '200',
                      suffix: 'ms',
                      icon: Icons.warning,
                      color: RetroTerminalTheme.vitalsCaution,
                      description: 'RESPONSE TIMES BETWEEN STABLE AND THIS SHOW AS CAUTION (YELLOW)',
                    ),
                    const SizedBox(height: 20),

                    // Poor indicator - CRITICAL (read-only)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RetroTerminalTheme.vitalsCritical.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: RetroTerminalTheme.vitalsCritical.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: RetroTerminalTheme.vitalsCritical,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CRITICAL THRESHOLD',
                                  style: RetroTerminalTheme.terminalText.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: RetroTerminalTheme.vitalsCritical,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ANYTHING ABOVE CAUTION THRESHOLD SHOWS AS CRITICAL (RED)',
                                  style: RetroTerminalTheme.terminalText.copyWith(
                                    fontSize: 11,
                                    color: RetroTerminalTheme.amberDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),

                    // Monitoring Settings Section
                    TerminalHeader(
                      title: 'MONITORING PARAMETERS',
                      subtitle: 'CONFIGURE PING INTERVAL AND DATA RETENTION',
                      icon: Icons.timer,
                    ),
                    const SizedBox(height: 20),

                    // Ping Interval
                    _buildThresholdField(
                      controller: _intervalController,
                      label: 'PING INTERVAL',
                      hint: '1000',
                      suffix: 'ms',
                      icon: Icons.schedule,
                      color: RetroTerminalTheme.amberColor,
                      description: 'TIME BETWEEN PINGS TO EACH ENDPOINT',
                    ),
                    const SizedBox(height: 20),

                    // Max History
                    _buildThresholdField(
                      controller: _historyController,
                      label: 'MAX HISTORY SIZE',
                      hint: '10',
                      suffix: 'READINGS',
                      icon: Icons.history,
                      color: RetroTerminalTheme.amberColor,
                      description: 'NUMBER OF RECENT READINGS TO DISPLAY PER ENDPOINT',
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetToDefaults,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text(
                              'RESET',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveSettings,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: RetroTerminalTheme.backgroundColor,
                                      ),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(
                                _isSaving ? 'SAVING...' : 'SAVE',
                                overflow: TextOverflow.ellipsis,
                                style: RetroTerminalTheme.terminalText.copyWith(
                                  color: RetroTerminalTheme.backgroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Version info footer
                    Center(
                      child: Text(
                        'AMLEDS v1.0.0 // TERMINAL INTERFACE',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 10,
                          color: RetroTerminalTheme.amberDim.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BlinkingCursor(
            width: 16,
            height: 24,
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING CONFIGURATION...',
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: RetroTerminalTheme.terminalText.copyWith(
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: RetroTerminalTheme.terminalText.copyWith(
              color: color,
            ),
            hintStyle: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, color: color),
            suffixText: suffix,
            suffixStyle: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim,
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            description,
            style: RetroTerminalTheme.terminalText.copyWith(
              fontSize: 10,
              color: RetroTerminalTheme.amberDim,
            ),
          ),
        ),
      ],
    );
  }
}
