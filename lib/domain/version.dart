import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemstoneapp/domain/platform.dart';
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

  Future<String> _attach() async {
    late String volumePath;
    process = await Process.start(
      'hdiutil',
      ['attach', dmgName],
      workingDirectory: gsPath,
    );
    process?.stdout.transform(utf8.decoder).listen((data) {
      for (final line in data.split('\n')) {
        final match = RegExp(r'.*/Volumes/([^ ]+)$').firstMatch(line);
        if (match != null) {
          volumePath = '/Volumes/${match.group(1)}';
        }
      }
    });
    process?.stderr.transform(utf8.decoder).listen((data) {
      isExtracted = false;
      // await _deleteExtract();
      throw Exception('Failed to attach $dmgName ($data)');
    });
    final exitCode = await process?.exitCode;
    process = null;
    if (exitCode != 0) {
      isExtracted = false;
      // await _deleteExtract();
      throw Exception('Failed to attach $dmgName (exit code $exitCode)');
    }
    return volumePath;
  }

  static Future<void> buildVersionList() async {
    versionList.clear();
    try {
      await downloadVersionList();
    } on TimeoutException {
      await readVersions();
    }
    return;
  }

  Future<void> cancelDownload() async {
    process?.kill();
    process = null;
    await deleteDownload();
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = false;
    final file = File(downloadFilePath);
    if (file.existsSync()) {
      final stat = file.statSync();
      if (stat.size == size) {
        isDownloaded = true;
      } else {
        await deleteDownload();
      }
    }
  }

  Future<void> checkIfExtracted() async {
    isExtracted = Directory(productFilePath).existsSync();
    if (isExtracted) {
      await _fillExtentList();
    }
  }

  Future<void> deleteDownload() async {
    if (File(downloadFilePath).existsSync()) {
      File(downloadFilePath).deleteSync();
    }
    await checkIfDownloaded();
  }

  Future<void> deleteExtract() async {
    final directory = Directory(productFilePath);
    if (directory.existsSync()) {
      await _setDirectoryWritable(directory);
      directory.deleteSync(recursive: true);
    }
    isExtracted = false;
  }

  Future<void> _detach(String volumePath) async {
    process = await Process.start(
      'hdiutil',
      ['detach', volumePath],
    );
    process?.stderr.transform(utf8.decoder).listen((data) {
      isExtracted = false;
      // await _deleteExtract();
      throw Exception('Failed to detach $volumePath ($data)');
    });
    final exitCode = await process?.exitCode;
    process = null;
    if (exitCode != 0) {
      isExtracted = false;
      // await _deleteExtract();
      throw Exception('Failed to detach $volumePath (exit code $exitCode)');
    }
  }

  Future<void> downloadVersion(void Function(String)? callback) async {
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
      await deleteDownload();
      throw Exception('Failed to download $dmgName (exit code $exitCode)');
    }
    File(downloadFilePath).setLastModifiedSync(date);
    isDownloaded = true;
  }

  static Future<void> downloadVersionList() async {
    final result = await Process.run('curl', ['$productsUrlPath/'])
        .timeout(const Duration(seconds: 2));
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
        versions.add(version);
      }
    }
    versionList.addAll(versions.reversed.toList());
  }

  Future<void> extract() async {
    await checkIfExtracted();
    if (isExtracted) {
      return;
    }
    final volumePath = await _attach();
    final list = Directory(volumePath).listSync();
    for (final entity in list) {
      final result = await Process.run('cp', ['-R', entity.path, gsPath]);
      if (result.exitCode != 0) {
        isExtracted = false;
        await deleteExtract();
        throw Exception('Failed to copy $entity to $gsPath');
      }
    }
    await _detach(volumePath);
    await checkIfExtracted();
  }

  Future<void> _fillExtentList() async {
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

  static Future<void> readVersions() async {
    final entries = Directory(gsPath).listSync();
    for (final each in entries) {
      if (each.path.endsWith('-arm64.Darwin.dmg') &&
          await FileSystemEntity.isFile(each.path)) {
        final versionString = each.path.substring(
          gsPath.length + 14,
          each.path.length - 17,
        );
        final stat = File(each.path).statSync();
        final version = Version(
          date: stat.modified,
          size: stat.size,
          version: versionString,
        );
        await version.checkIfDownloaded();
        await version.checkIfExtracted();
        versionList.add(version);
      }
      if (each.path.endsWith('-arm64.Darwin') &&
          await FileSystemEntity.isDirectory(each.path)) {
        final versionString = each.path.substring(
          gsPath.length + 14,
          each.path.length - 13,
        );
        Version? version;
        for (final each in versionList) {
          if (each.version == versionString) {
            version = each;
            break;
          }
        }
        if (version == null) {
          final stat = File(each.path).statSync();
          final version = Version(
            date: stat.modified,
            size: stat.size,
            version: versionString,
          );
          await version.checkIfDownloaded();
          await version.checkIfExtracted();
          versionList.add(version);
        }
      }
    }
  }

  Future<void> _setDirectoryWritable(Directory directory) async {
    await Process.run('chmod', ['-R', 'u+w', directory.path]);
  }
}
