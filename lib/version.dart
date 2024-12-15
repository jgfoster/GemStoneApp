import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemstoneapp/platform.dart';
import 'package:intl/intl.dart';

class Version {
  Version({
    required this.date,
    required this.version,
    required this.size,
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
  late bool isRunnable = false;
  Process? process;
  static String productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String productUrlPath;
  final int size;
  final String version;
  static List<Version> versionList = [];

  Future<void> cancelDownload() async {
    process?.kill();
    process = null;
    await _deleteDownload();
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = false;
    final file = File(downloadFilePath);
    if (file.existsSync()) {
      final stat = file.statSync();
      if (stat.size == size) {
        isDownloaded = true;
      } else {
        await _deleteDownload();
      }
    }
  }

  Future<void> checkIfExtracted() async {
    isExtracted = Directory(productFilePath).existsSync();
    if (isExtracted) {
      await fillExtentList();
    }
  }

  Future<void> checkIfRunnable() async {
    if (isExtracted) {
      final result = await Process.run(
        'xattr',
        ['-l', productFilePath],
      );
      if (result.exitCode == 0) {
        isRunnable = !result.stdout.toString().contains('com.apple.quarantine');
      } else {
        isRunnable = false;
      }
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
    await checkIfDownloaded();
    if (isDownloaded) {
      return;
    }

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
      // <a href="GemStone64Bit3.6.1-arm64.Darwin.dmg">GemStone64Bit3.6.1-arm64.Darwin.dmg</a>                06-Apr-2021 20:35           145306111
      final match = RegExp(
        r'href="[^"]*GemStone64Bit(\d+\.\d+\.\d+)[^"]*".*?(\d{2}-\w{3}-\d{4})\s+\d{2}:\d{2}\s+(\d+)',
      ).firstMatch(line);
      if (match != null) {
        final versionString = match.group(1)!;
        final date = dateFormat.parse(match.group(2)!);
        final size = int.parse(match.group(3)!);
        final version = Version(version: versionString, date: date, size: size);
        await version.checkIfDownloaded();
        await version.checkIfExtracted();
        await version.checkIfRunnable();
        versions.add(version);
      }
    }
    versionList.addAll(versions.reversed.toList());
  }
}
