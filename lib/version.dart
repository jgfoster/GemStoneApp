import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

class Version {
  Version({
    required this.date,
    required this.version,
    // TODO: include download size so we can verify the download
  }) {
    dmgName = 'GemStone64Bit$version-arm64.Darwin.dmg';
    downloadFilePath = '$versionsDir/$dmgName';
    productFilePath = '$versionsDir/GemStone64Bit$version-arm64.Darwin';
    productUrlPath = '$productsUrlPath/$dmgName';
  }

  final DateTime date;
  late String dmgName;
  late String downloadFilePath;
  late bool isDownloaded = false;
  late bool isExtracted = false;
  static String versionsDir =
      '${Directory.current.path}/Library/Application Support/GemStone';
  Process? process;
  static String productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String productUrlPath;
  final String version;
  static List<Version>? _versionList;

  Future<void> cancelDownload() async {
    process?.kill();
    process = null;
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = File(downloadFilePath).existsSync();
  }

  Future<void> checkIfExtracted() async {
    isExtracted = Directory(productFilePath).existsSync();
  }

  Future<void> _deleteDownload() async {
    if (File(downloadFilePath).existsSync()) {
      File(downloadFilePath).deleteSync();
    }
  }

  Future<void> deleteProduct() async {
    if (Directory(productFilePath).existsSync()) {
      Directory(productFilePath).deleteSync(recursive: true);
    }
  }

  Future<void> download(void Function(String)? callback) async {
    if (!Directory(versionsDir).existsSync()) {
      Directory(versionsDir).createSync(recursive: true);
    }
    await _deleteDownload();

    process = await Process.start(
      'curl',
      ['-O', productUrlPath],
      workingDirectory: versionsDir,
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
      await _deleteDownload();
      throw Exception('Failed to download $dmgName (exit code $exitCode)');
    }

    isDownloaded = true;
  }

  static Future<List<Version>> versionList() async {
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
    final versions = <Version>[];
    final lines = result.stdout.toString().split('\n');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    for (final line in lines) {
      final match = RegExp(
        r'href="[^"]*GemStone64Bit(\d+\.\d+\.\d+)[^"]*".*?(\d{2}-\w{3}-\d{4})',
      ).firstMatch(line);
      if (match != null) {
        final version = match.group(1)!;
        final date = dateFormat.parse(match.group(2)!);
        final database = Version(version: version, date: date);
        await database.checkIfExtracted();
        versions.add(database);
      }
    }
    _versionList = versions.reversed.toList();
    return _versionList!;
  }
}
