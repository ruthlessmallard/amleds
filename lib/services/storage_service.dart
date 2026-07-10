import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/machine.dart';
import '../models/settings.dart';

class StorageService {
  static const String _machinesFileName = 'machines.json';
  static const String _settingsFileName = 'settings.json';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _machinesFile async {
    final path = await _localPath;
    return File('$path/$_machinesFileName');
  }

  Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/$_settingsFileName');
  }

  // Machines
  Future<List<Machine>> loadMachines() async {
    try {
      final file = await _machinesFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => Machine.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMachines(List<Machine> machines) async {
    final file = await _machinesFile;
    final jsonList = machines.map((m) => m.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<void> addMachine(Machine machine) async {
    final machines = await loadMachines();
    machines.add(machine);
    await saveMachines(machines);
  }

  Future<void> updateMachine(Machine updatedMachine) async {
    final machines = await loadMachines();
    final index = machines.indexWhere((m) => m.id == updatedMachine.id);
    if (index != -1) {
      machines[index] = updatedMachine;
      await saveMachines(machines);
    }
  }

  Future<void> deleteMachine(String id) async {
    final machines = await loadMachines();
    machines.removeWhere((m) => m.id == id);
    await saveMachines(machines);
  }

  // Settings
  Future<AppSettings> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (!await file.exists()) {
        return AppSettings();
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      return AppSettings.fromJson(json);
    } catch (e) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final file = await _settingsFile;
    await file.writeAsString(jsonEncode(settings.toJson()));
  }
}
