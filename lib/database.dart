import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemstoneapp/version.dart';
import 'package:intl/intl.dart';

class Database {
  Database({
    required this.version,
    required this.stoneName,
    required this.ldiName,
  });

  static List<Database>? _databaseList;
  static String databasesDir = '${Directory.current.path}/Documents/GemStone';
  String ldiName;
  String stoneName;
  Version version;

  static Future<List<Database>> databaseList() async {
    if (_databaseList != null) {
      return _databaseList!;
    }
    if (!Directory(databasesDir).existsSync()) {
      Directory(databasesDir).createSync(recursive: true);
    }
    _databaseList = <Database>[];
    final databaseFiles = Directory(databasesDir).listSync();
    for (final databaseFile in databaseFiles) {
      print('databaseFile: $databaseFile');
    }
    return _databaseList!;
  }
}
