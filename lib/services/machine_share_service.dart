import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/machine.dart';
import 'storage_service.dart';

/// Compact machine config format for sharing via text/SMS/email
/// {
///   "amleds_v1": {
///     "machines": [
///       {"id":"...","name":"...","group":"...","ipAddresses":["..."]}
///     ]
///   }
/// }
class MachineShareService {
  static const String _versionKey = 'amleds_v1';

  /// Export a single machine as shareable text
  static Future<void> shareMachine(Machine machine) async {
    final payload = _buildPayload([machine]);
    final jsonStr = jsonEncode(payload);
    await Share.share(
      jsonStr,
      subject: 'AMLEDS: ${machine.name}',
    );
  }

  /// Export all machines as shareable text
  static Future<void> shareAllMachines(List<Machine> machines) async {
    final payload = _buildPayload(machines);
    final jsonStr = jsonEncode(payload);
    await Share.share(
      jsonStr,
      subject: 'AMLEDS: ${machines.length} machine configs',
    );
  }

  /// Copy single machine to clipboard
  static Future<void> copyMachineToClipboard(Machine machine) async {
    final payload = _buildPayload([machine]);
    final jsonStr = jsonEncode(payload);
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  /// Import from clipboard string. Returns result with status and info.
  static Future<ImportResult> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) {
      return ImportResult(
        success: false,
        message: 'Clipboard empty',
      );
    }
    return _importFromJson(data.text!.trim());
  }

  /// Import from raw JSON string (for testing or file import)
  static Future<ImportResult> importFromJson(String jsonStr) async {
    return _importFromJson(jsonStr.trim());
  }

  static Map<String, dynamic> _buildPayload(List<Machine> machines) {
    return {
      _versionKey: {
        'machines': machines.map((m) => m.toJson()).toList(),
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
  }

  static Future<ImportResult> _importFromJson(String text) async {
    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map) {
        return ImportResult(
          success: false,
          message: 'Invalid format: expected JSON object',
        );
      }

      // Check versioned wrapper
      final payload = decoded[_versionKey];
      if (payload == null) {
        return ImportResult(
          success: false,
          message: 'Unrecognized format: missing amleds_v1 key',
        );
      }

      final machinesJson = payload['machines'];
      if (machinesJson is! List || machinesJson.isEmpty) {
        return ImportResult(
          success: false,
          message: 'No machines found in payload',
        );
      }

      final storage = StorageService();
      final existing = await storage.loadMachines();
      final existingIds = existing.map((m) => m.id).toSet();

      int imported = 0;
      int updated = 0;
      int skipped = 0;
      final List<String> details = [];

      for (final mJson in machinesJson) {
        try {
          final machine = Machine.fromJson(mJson);

          if (existingIds.contains(machine.id)) {
            // Same ID exists — update it
            await storage.updateMachine(machine);
            updated++;
            details.add('Updated: ${machine.name}');
          } else {
            await storage.addMachine(machine);
            imported++;
            existingIds.add(machine.id);
            details.add('Imported: ${machine.name}');
          }
        } catch (e) {
          skipped++;
          details.add('Skipped invalid entry: $e');
        }
      }

      return ImportResult(
        success: true,
        imported: imported,
        updated: updated,
        skipped: skipped,
        message: 'Imported $imported, updated $updated, skipped $skipped',
        details: details,
      );
    } on FormatException catch (e) {
      return ImportResult(
        success: false,
        message: 'Invalid JSON: $e',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import error: $e',
      );
    }
  }
}

class ImportResult {
  final bool success;
  final int imported;
  final int updated;
  final int skipped;
  final String message;
  final List<String> details;

  ImportResult({
    required this.success,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    required this.message,
    this.details = const [],
  });
}
