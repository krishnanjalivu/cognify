import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cogniaware_record.dart';
import '../models/gait_metrics.dart';
import '../models/typing_metrics.dart';
import '../models/voice_metrics.dart';

/// Local-only storage for Cogniaware Index and Gait/Typing/Voice trends.
/// Raw sensor/audio data is never persisted.
class StorageService {
  static const String _dbName = 'cogniaware.db';
  static const int _version = 2;
  Database? _db;

  Future<Database> _getDb() async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE cogniaware_records ADD COLUMN gaitIndex REAL');
          await db.execute('ALTER TABLE cogniaware_records ADD COLUMN typingIndex REAL');
          await db.execute('ALTER TABLE cogniaware_records ADD COLUMN voiceIndex REAL');
          await db.execute('ALTER TABLE cogniaware_records ADD COLUMN typingMetricsJson TEXT');
          await db.execute('ALTER TABLE cogniaware_records ADD COLUMN voiceMetricsJson TEXT');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE cogniaware_records (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        cogniawareIndex REAL NOT NULL,
        gaitMetricsJson TEXT,
        gaitIndex REAL,
        typingMetricsJson TEXT,
        typingIndex REAL,
        voiceMetricsJson TEXT,
        voiceIndex REAL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_timestamp ON cogniaware_records(timestamp)',
    );
  }

  Future<void> insertRecord(CogniawareRecord record) async {
    final db = await _getDb();
    await db.insert('cogniaware_records', {
      'id': record.id,
      'timestamp': record.timestamp.toIso8601String(),
      'cogniawareIndex': record.cogniawareIndex,
      'gaitMetricsJson': record.gaitMetrics != null
          ? jsonEncode(record.gaitMetrics!.toJson())
          : null,
      'gaitIndex': record.gaitIndex,
      'typingMetricsJson': record.typingMetrics != null
          ? jsonEncode(record.typingMetrics!.toJson())
          : null,
      'typingIndex': record.typingIndex,
      'voiceMetricsJson': record.voiceMetrics != null
          ? jsonEncode(record.voiceMetrics!.toJson())
          : null,
      'voiceIndex': record.voiceIndex,
    });
  }

  Future<List<CogniawareRecord>> getRecords({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _getDb();
    final rows = await db.query(
      'cogniaware_records',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToRecord).toList();
  }

  Future<List<CogniawareRecord>> getRecordsForDays(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getRecords(start: start, end: end);
  }

  CogniawareRecord _rowToRecord(Map<String, dynamic> row) {
    GaitMetrics? gait;
    final gaitStr = row['gaitMetricsJson'] as String?;
    if (gaitStr != null) {
      gait = GaitMetrics.fromJson(
        jsonDecode(gaitStr) as Map<String, dynamic>,
      );
    }
    TypingMetrics? typing;
    final typingStr = row['typingMetricsJson'] as String?;
    if (typingStr != null) {
      typing = TypingMetrics.fromJson(
        jsonDecode(typingStr) as Map<String, dynamic>,
      );
    }
    VoiceMetrics? voice;
    final voiceStr = row['voiceMetricsJson'] as String?;
    if (voiceStr != null) {
      voice = VoiceMetrics.fromJson(
        jsonDecode(voiceStr) as Map<String, dynamic>,
      );
    }
    return CogniawareRecord(
      id: row['id'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      cogniawareIndex: (row['cogniawareIndex'] as num).toDouble(),
      gaitMetrics: gait,
      gaitIndex: (row['gaitIndex'] as num?)?.toDouble(),
      typingMetrics: typing,
      typingIndex: (row['typingIndex'] as num?)?.toDouble(),
      voiceMetrics: voice,
      voiceIndex: (row['voiceIndex'] as num?)?.toDouble(),
    );
  }

  Future<void> clearAll() async {
    final db = await _getDb();
    await db.delete('cogniaware_records');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
