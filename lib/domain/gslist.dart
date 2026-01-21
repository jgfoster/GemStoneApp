import 'dart:io';

import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/domain/platform.dart';
// import 'package:simple_native_logger/simple_native_logger.dart';

class GsList {
  factory GsList() {
    return _instance;
  }
  GsList._privateConstructor();

  static final GsList _instance = GsList._privateConstructor();
  DateTime? lastUpdateTime;
  String? output;
  // static final _logger = SimpleNativeLogger(tag: 'GemStone');

  Future<void> fetchData() async {
    try {
      // _logger.i('Finding gslist executable...');
      final directory = Directory(gsPath);
      final fullList = directory.list(recursive: true);
      final gsList = await fullList.firstWhere(
        (file) => file.path.endsWith('/bin/gslist'),
      );
      // _logger.i('Found gslist executable at ${gsList.path}');
      final result = await Process.run(
        gsList.path,
        ['-cvl'],
        environment: {
          'GEMSTONE_GLOBAL_DIR': gsPath,
        },
      );
      // _logger.i('gslist output: ${result.stdout}');
      lastUpdateTime = DateTime.now();
      output = result.stdout;
      _parseOutput();
    } catch (e) {
      // we don't have an executable
      output = null;
    }
  }

  List<String> get months => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

  void _parseOutput() {
    for (final database in Database.databaseList) {
      database.reset();
    }
    final lines = output!.split('\n');
    for (final line in lines) {
      if (line.startsWith('OK')) {
        final parts = line.split(RegExp(r'\s+'));
        final version = parts[1];
        final pid = int.parse(parts[3]);
        final port = int.parse(parts[4]);
        final monthIndex = months.indexOf(parts[5]) + 1;
        final month = monthIndex.toString().padLeft(2, '0');
        final day = parts[6].padLeft(2, '0');
        final year = DateTime.now().year;
        final started = '$year-$month-$day ${parts[7]}';
        final startedDateTime = DateTime.parse(started);
        final type = parts[8];
        final name = parts[9];
        for (final database in Database.databaseList) {
          final isMyStone = type == 'Stone' && database.stoneName == name;
          final isMyLdi = type == 'Netldi' && database.ldiName == name;
          final versionMatches = database.version.name == version;
          if (versionMatches && (isMyStone || isMyLdi)) {
            if (isMyStone) {
              database.stonePid = pid;
              database.stoneStartTime = startedDateTime;
            } else {
              database.ldiPid = pid;
              database.ldiPort = port;
              database.ldiStartTime = startedDateTime;
            }
          }
        }
      }
    }
  }
}
