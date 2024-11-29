import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

class Database {
  Database({
    required this.date,
    required this.version,
  }) {
    dmgName = 'GemStone64Bit$version-arm64.Darwin.dmg';
    productFilePath = '$gemstoneDir/GemStone64Bit$version-arm64.Darwin';
    productUrlPath = '$productsUrlPath/$dmgName';
  }

  final DateTime date;
  late String dmgName;
  late bool isDownloaded = false;
  static String gemstoneDir =
      '${Directory.current.path}/Library/Application Support/GemStone';
  Process? process;
  static String productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String productUrlPath;
  final String version;
  static List<Database>? _versionList;

  Future<void> cancelDownload() async {
    process?.kill();
    process = null;
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = Directory(productFilePath).existsSync();
  }

  Future<void> delete() async {
    Directory(productFilePath).deleteSync(recursive: true);
  }

  Future<void> download(void Function(String)? callback) async {
    if (!Directory(gemstoneDir).existsSync()) {
      Directory(gemstoneDir).createSync(recursive: true);
    }
    if (File('$gemstoneDir/$dmgName').existsSync()) {
      File('$gemstoneDir/$dmgName').deleteSync();
    }

    process = await Process.start(
      'curl',
      ['-O', productUrlPath],
      workingDirectory: gemstoneDir,
    );

    process?.stderr.transform(utf8.decoder).listen((data) {
      if (callback != null) {
        callback(data);
      }
    });

    final exitCode = await process?.exitCode;
    process = null;
    if (exitCode != 0) {
      isDownloaded = false;
      if (File('$gemstoneDir/$dmgName').existsSync()) {
        File('$gemstoneDir/$dmgName').deleteSync();
      }
      throw Exception('Failed to download $dmgName (exit code $exitCode)');
    }

    await Process.run('open', [gemstoneDir]);
    isDownloaded = true;
  }

  static Future<List<Database>> versionList() async {
    if (_versionList != null) {
      return _versionList!;
    }
    ProcessResult result;
    try {
      result = await Process.run('curl', ['$productsUrlPath/'])
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // TODO: build a list of already-installed versions
      return [];
    }
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
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
        await database.checkIfDownloaded();
        versions.add(database);
      }
    }
    _versionList = versions.reversed.toList();
    return _versionList!;
  }
}
