import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

class Database {
  Database({
    required this.date,
    required this.version,
  }) {
    dmgName = 'GemStone64Bit$version-arm64.Darwin.dmg';
    productFilePath = '$gemstoneFilePath/GemStone64Bit$version-arm64.Darwin';
    productUrlPath = '$productsUrlPath/$dmgName';
  }
  final DateTime date;
  late String dmgName;
  late bool isDownloaded = false;
  static String gemstoneFilePath =
      '${Directory.current.path}/Library/Application Support/GemStone';
  static String productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String productUrlPath;
  static String tmpFilePath = '${Directory.current.path}/tmp/GemStone.dmg';
  final String version;
  static List<Database>? _versionList;

  Future<void> checkIfDownloaded() async {
    isDownloaded = Directory(productFilePath).existsSync();
  }

  Future<void> delete() async {
    Directory(productFilePath).deleteSync(recursive: true);
  }

/*
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0  205M    0  207k    0     0   567k      0  0:06:10 --:--:--  0:06:10  567k
  4  205M    4  9.8M    0     0  7501k      0  0:00:28  0:00:01  0:00:27 7499k
 80  205M   80  164M    0     0  8701k      0  0:00:24  0:00:19  0:00:05 10.6M
 88  205M   88  182M    0     0  9166k      0  0:00:22  0:00:20  0:00:02 12.7M
 97  205M   97  199M    0     0  9555k      0  0:00:21  0:00:21 --:--:-- 14.7M
100  205M  100  205M    0     0  9664k      0  0:00:21  0:00:21 --:--:-- 16.3M
*/
  Future<void> download(void Function(String)? callback) async {
    if (!Directory(gemstoneFilePath).existsSync()) {
      Directory(gemstoneFilePath).createSync(recursive: true);
    }
    if (Directory(tmpFilePath).existsSync()) {
      Directory(tmpFilePath).deleteSync();
    }

    print('Downloading $productUrlPath to $tmpFilePath');
    final process = await Process.start('curl', [
      '-o',
      tmpFilePath,
      productUrlPath,
    ]);

    process.stderr.transform(utf8.decoder).listen((data) {
      if (callback != null) {
        callback(data);
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      isDownloaded = false;
      throw Exception('Failed to download product (exit code $exitCode)');
    }
    isDownloaded = true;
  }

  static Future<List<Database>> versionList() async {
    print('versionList - 1');
    if (_versionList != null) {
      print('versionList - 2');
      return _versionList!;
    }
    print('versionList - 3 - curl $productsUrlPath/');
    final result = await Process.run('curl', ['$productsUrlPath/']);
    print('versionList - 4');
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    print('versionList - 5');
    final versions = <Database>[];
    final lines = result.stdout.toString().split('\n');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    for (final line in lines) {
      final match = RegExp(
        r'href="[^"]*GemStone64Bit(\d+\.\d+\.\d+)[^"]*".*?(\d{2}-\w{3}-\d{4})',
      ).firstMatch(line);
      if (match != null) {
        final version = match.group(1)!;
        final date = dateFormat.parse(match.group(2)!);
        final database = Database(version: version, date: date);
        // await database.checkIfDownloaded();
        versions.add(database);
      }
    }
    _versionList = versions.reversed.toList();
    return _versionList!;
  }
}
