import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/machine.dart';
import '../services/storage_service.dart';
import '../theme/retro_terminal_theme.dart';

class MachineEditScreen extends StatefulWidget {
  final Machine? machine;

  const MachineEditScreen({super.key, this.machine});

  @override
  State<MachineEditScreen> createState() => _MachineEditScreenState();
}

class _MachineEditScreenState extends State<MachineEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final StorageService _storage = StorageService();

  late String _machineId;
  final List<String> _ipAddresses = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.machine != null) {
      _machineId = widget.machine!.id;
      _nameController.text = widget.machine!.name;
      _ipAddresses.addAll(widget.machine!.ipAddresses);
    } else {
      _machineId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _addIpAddress() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    // Basic IP validation
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipRegex.hasMatch(ip)) {
      _showMessage('ERROR: INVALID IP ADDRESS FORMAT', RetroTerminalTheme.vitalsCritical);
      return;
    }

    if (_ipAddresses.contains(ip)) {
      _showMessage('ERROR: IP ADDRESS ALREADY EXISTS', RetroTerminalTheme.vitalsCaution);
      return;
    }

    setState(() {
      _ipAddresses.add(ip);
      _ipController.clear();
    });
  }

  void _removeIpAddress(String ip) {
    setState(() {
      _ipAddresses.remove(ip);
    });
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: RetroTerminalTheme.terminalText.copyWith(
            color: RetroTerminalTheme.backgroundColor,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ipAddresses.isEmpty) {
      _showMessage('ERROR: ADD AT LEAST ONE IP ADDRESS', RetroTerminalTheme.vitalsCritical);
      return;
    }

    setState(() => _isSaving = true);

    final machine = Machine(
      id: _machineId,
      name: _nameController.text.trim(),
      ipAddresses: List.from(_ipAddresses),
    );

    if (widget.machine != null) {
      await _storage.updateMachine(machine);
    } else {
      await _storage.addMachine(machine);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.machine != null;

    return Scaffold(
      backgroundColor: RetroTerminalTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'EDIT MACHINE' : 'ADD MACHINE',
          style: RetroTerminalTheme.terminalHeader.copyWith(
            letterSpacing: 2,
          ),
        ),
      ),
      body: CRTScanlines(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Machine ID display
              Container(
                padding: const EdgeInsets.all(12),
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
                    Text(
                      'MACHINE ID:',
                      style: RetroTerminalTheme.terminalText.copyWith(
                        color: RetroTerminalTheme.amberDim,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _machineId.substring(_machineId.length - 8).toUpperCase(),
                      style: RetroTerminalTheme.terminalText.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Machine Name Section
              TerminalHeader(
                title: 'MACHINE NAME',
                icon: Icons.computer,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameController,
                style: RetroTerminalTheme.terminalText,
                decoration: InputDecoration(
                  hintText: 'e.g., SERVER RACK 1',
                  hintStyle: RetroTerminalTheme.terminalText.copyWith(
                    color: RetroTerminalTheme.amberDim.withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.terminal,
                    color: RetroTerminalTheme.amberColor,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ENTER MACHINE NAME';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 32),

              // IP Addresses Section
              TerminalHeader(
                title: 'IP ADDRESSES',
                subtitle: 'ADD ALL ENDPOINTS TO MONITOR',
                icon: Icons.network_check,
              ),
              const SizedBox(height: 16),

              // Add IP Address
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      style: RetroTerminalTheme.terminalText,
                      decoration: InputDecoration(
                        hintText: '192.168.1.1',
                        hintStyle: RetroTerminalTheme.terminalText.copyWith(
                          color: RetroTerminalTheme.amberDim.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.router,
                          color: RetroTerminalTheme.amberColor,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onSubmitted: (_) => _addIpAddress(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _addIpAddress,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'ADD',
                      style: RetroTerminalTheme.terminalText.copyWith(
                        color: RetroTerminalTheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // IP Address List
              if (_ipAddresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RetroTerminalTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: RetroTerminalTheme.amberDim.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.network_check,
                          size: 32,
                          color: RetroTerminalTheme.amberDim.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NO IP ADDRESSES CONFIGURED',
                          style: RetroTerminalTheme.terminalText.copyWith(
                            color: RetroTerminalTheme.amberDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _ipAddresses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ip = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: RetroTerminalTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: RetroTerminalTheme.amberDim,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: RetroTerminalTheme.amberColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: RetroTerminalTheme.terminalText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          ip,
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: RetroTerminalTheme.vitalsCritical,
                            size: 20,
                          ),
                          onPressed: () => _removeIpAddress(ip),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(
                        'CANCEL',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveMachine,
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
                          _isSaving ? 'SAVING...' : 'SAVE MACHINE',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
            ],
          ),
        ),
      ),
    );
  }
}
