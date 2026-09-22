import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../services/storage_service.dart';
import '../services/machine_share_service.dart';
import '../theme/retro_terminal_theme.dart';
import 'machine_edit_screen.dart';
import 'monitor_screen.dart';
import 'settings_screen.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  final StorageService _storage = StorageService();
  List<Machine> _machines = [];
  final Map<String, bool> _expandedGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _shareAllMachines() async {
    if (_machines.isEmpty) {
      _showSnack('NO MACHINES TO EXPORT', RetroTerminalTheme.vitalsCaution);
      return;
    }
    await MachineShareService.shareAllMachines(_machines);
  }

  Future<void> _importMachines() async {
    final result = await MachineShareService.importFromClipboard();
    _showSnack(result.message.toUpperCase(), 
      result.success ? RetroTerminalTheme.vitalsStable : RetroTerminalTheme.vitalsCritical);
    if (result.success) {
      _loadMachines();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: RetroTerminalTheme.terminalText.copyWith(
            color: RetroTerminalTheme.backgroundColor,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadMachines() async {
    setState(() => _isLoading = true);
    final machines = await _storage.loadMachines();
    _initExpandedGroups(machines);
    setState(() {
      _machines = machines;
      _isLoading = false;
    });
  }

  void _initExpandedGroups(List<Machine> machines) {
    final groups = machines.map((m) => m.displayGroup).toSet();
    for (final g in groups) {
      _expandedGroups.putIfAbsent(g, () => true);
    }
  }

  Map<String, List<Machine>> get _groupedMachines {
    final map = <String, List<Machine>>{};
    for (final m in _machines) {
      final g = m.displayGroup;
      map.putIfAbsent(g, () => []).add(m);
    }
    return map;
  }

  List<String> get _sortedGroups {
    final groups = _groupedMachines.keys.toList();
    groups.sort((a, b) {
      if (a == 'UNGROUPED') return 1;
      if (b == 'UNGROUPED') return -1;
      return a.compareTo(b);
    });
    return groups;
  }

  Future<void> _deleteMachine(Machine machine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'DELETE MACHINE',
          style: RetroTerminalTheme.terminalHeader,
        ),
        content: Text(
          'CONFIRM DELETION OF "${machine.name.toUpperCase()}"?',
          style: RetroTerminalTheme.terminalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '[CANCEL]',
              style: RetroTerminalTheme.terminalText.copyWith(
                color: RetroTerminalTheme.amberDim,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '[DELETE]',
              style: RetroTerminalTheme.terminalText.copyWith(
                color: RetroTerminalTheme.vitalsCritical,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteMachine(machine.id);
      _loadMachines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTerminalTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.terminal,
              color: RetroTerminalTheme.amberColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'AMLEDS',
              style: RetroTerminalTheme.terminalHeader.copyWith(
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.ios_share,
              color: RetroTerminalTheme.amberColor,
            ),
            onPressed: _shareAllMachines,
            tooltip: 'SHARE ALL',
          ),
          IconButton(
            icon: const Icon(
              Icons.download,
              color: RetroTerminalTheme.amberColor,
            ),
            onPressed: _importMachines,
            tooltip: 'IMPORT',
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: RetroTerminalTheme.amberColor,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: CRTScanlines(
        child: _isLoading
            ? _buildLoadingState()
            : _machines.isEmpty
                ? _buildEmptyState()
                : _buildMachineList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MachineEditScreen(),
            ),
          );
          _loadMachines();
        },
        icon: const Icon(Icons.add),
        label: Text(
          'ADD MACHINE',
          style: RetroTerminalTheme.terminalText.copyWith(
            color: RetroTerminalTheme.backgroundColor,
            fontWeight: FontWeight.bold,
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
            'INITIALIZING...',
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.computer_outlined,
            size: 64,
            color: RetroTerminalTheme.amberDim.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'NO MACHINES CONFIGURED',
            style: RetroTerminalTheme.terminalHeader.copyWith(
              color: RetroTerminalTheme.amberDim,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ADD YOUR FIRST MACHINE TO BEGIN MONITORING',
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineList() {
    final grouped = _groupedMachines;
    final groups = _sortedGroups;
    final items = <Widget>[];
    for (final groupName in groups) {
      final machines = grouped[groupName]!;
      items.add(_buildGroupHeader(groupName, machines.length));
      if (_expandedGroups[groupName] ?? true) {
        for (final machine in machines) {
          items.add(_buildMachineCard(machine));
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildGroupHeader(String groupName, int count) {
    final isExpanded = _expandedGroups[groupName] ?? true;
    return InkWell(
      onTap: () {
        setState(() {
          _expandedGroups[groupName] = !isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: RetroTerminalTheme.surfaceColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: RetroTerminalTheme.amberColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.folder_open : Icons.folder,
              color: RetroTerminalTheme.amberColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                groupName.toUpperCase(),
                style: RetroTerminalTheme.terminalHeader.copyWith(
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            Text(
              '[$count]',
              style: RetroTerminalTheme.terminalText.copyWith(
                color: RetroTerminalTheme.amberDim,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: RetroTerminalTheme.amberDim,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineCard(Machine machine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: RetroTerminalTheme.amberDim,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitorScreen(machine: machine),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and actions
              Row(
                children: [
                  // Machine ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RetroTerminalTheme.amberColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: RetroTerminalTheme.amberDim,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.computer,
                          size: 14,
                          color: RetroTerminalTheme.amberColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${machine.id.substring(machine.id.length - 4)}',
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Edit button
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: RetroTerminalTheme.amberColor,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MachineEditScreen(machine: machine),
                        ),
                      );
                      _loadMachines();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: RetroTerminalTheme.vitalsCritical,
                    ),
                    onPressed: () => _deleteMachine(machine),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Machine name
              Text(
                machine.name.toUpperCase(),
                style: RetroTerminalTheme.terminalHeader.copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // IP count
              Row(
                children: [
                  Text(
                    'ENDPOINTS:',
                    style: RetroTerminalTheme.terminalText.copyWith(
                      color: RetroTerminalTheme.amberDim,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${machine.ipAddresses.length}',
                    style: RetroTerminalTheme.terminalText.copyWith(
                      color: RetroTerminalTheme.vitalsStable,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // IP addresses
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RetroTerminalTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  machine.ipAddresses.join('  |  '),
                  style: RetroTerminalTheme.terminalText.copyWith(
                    fontSize: 12,
                    color: RetroTerminalTheme.amberDim,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Monitor button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: RetroTerminalTheme.amberColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: RetroTerminalTheme.amberColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monitor_heart,
                          size: 14,
                          color: RetroTerminalTheme.amberColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MONITOR >_',
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
