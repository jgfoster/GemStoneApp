import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemstoneapp/platform.dart';
import 'package:intl/intl.dart';

class Version {
  Version({
    required this.date,
    required this.version,
    // TODO: include download size so we can verify the download
  }) {
    dmgName = 'GemStone64Bit$version-arm64.Darwin.dmg';
    downloadFilePath = '$gsPath/$dmgName';
    productFilePath = '$gsPath/GemStone64Bit$version-arm64.Darwin';
    productUrlPath = '$productsUrlPath/$dmgName';
  }

  final DateTime date;
  late String dmgName;
  late String downloadFilePath;
  final List<String> extents = [];
  late bool isDownloaded = false;
  late bool isExtracted = false;
  Process? process;
  static String productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String productUrlPath;
  final String version;
  static List<Version> versionList = [];

  Future<void> cancelDownload() async {
    process?.kill();
    process = null;
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = File(downloadFilePath).existsSync();
  }

  Future<void> checkIfExtracted() async {
    isExtracted = Directory(productFilePath).existsSync();
    if (isExtracted) {
      await fillExtentList();
    }
  }

  Future<void> _deleteDownload() async {
    if (File(downloadFilePath).existsSync()) {
      File(downloadFilePath).deleteSync();
    }
  }

  Future<void> deleteProduct() async {
    final directory = Directory(productFilePath);
    if (directory.existsSync()) {
      await _setDirectoryWritable(directory);
      directory.deleteSync(recursive: true);
    }
    isExtracted = false;
  }

  Future<void> fillExtentList() async {
    extents.clear();
    final list = Directory('$productFilePath/bin').listSync();
    list.sort((a, b) => a.path.compareTo(b.path));
    for (final entity in list) {
      final path = entity.path;
      if (entity is File && path.endsWith('.dbf')) {
        final name =
            path.substring(productFilePath.length + 5, path.length - 4);
        extents.add(name);
      }
    }
  }

  static List<Version> installedVersions() {
    final versions = <Version>[];
    for (final version in versionList) {
      if (version.isExtracted) {
        versions.add(version);
      }
    }
    return versions;
  }

  Future<void> _setDirectoryWritable(Directory directory) async {
    await Process.run('chmod', ['-R', 'u+w', directory.path]);
  }

  Future<void> download(void Function(String)? callback) async {
    if (!Directory(gsPath).existsSync()) {
      Directory(gsPath).createSync(recursive: true);
    }
    await _deleteDownload();

    process = await Process.start(
      'curl',
      ['-O', productUrlPath],
      workingDirectory: gsPath,
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

  static Future<void> buildVersionList() async {
    versionList.clear();
    ProcessResult result;
    try {
      result = await Process.run('curl', ['$productsUrlPath/'])
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // TODO: build a list of already-installed versions
      return;
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
    versionList.addAll(versions.reversed.toList());
  }
}
