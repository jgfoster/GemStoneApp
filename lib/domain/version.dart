import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/platform.dart';
import 'package:intl/intl.dart';

class Version with ChangeNotifier {
  Version({required this.date, required this.name, required this.size}) {
    dmgName = 'GemStone64Bit$name-arm64.Darwin.dmg';
    _downloadFilePath = '$gsPath/$dmgName';
    productFilePath = '$gsPath/GemStone64Bit$name-arm64.Darwin';
    _productUrlPath = '$_productsUrlPath/$dmgName';
  }

  final DateTime date;
  late String dmgName;
  late String _downloadFilePath;
  Process? _downloadProcess;
  String downloadProgress = '';
  final List<String> extents = [];
  late bool isDownloaded = false;
  late bool isExtracted = false;
  final String name;
  static final String _productsUrlPath =
      'https://downloads.gemtalksystems.com/platforms/arm64.Darwin';
  late String productFilePath;
  late String _productUrlPath;
  final int size;
  static List<Version> versionList = [];

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
    _downloadProcess?.kill();
    _downloadProcess = null;
    await deleteDownload();
  }

  Future<void> checkIfDownloaded() async {
    isDownloaded = false;
    final file = File(_downloadFilePath);
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
    final bool flag = Directory(productFilePath).existsSync();
    if (flag != isExtracted) {
      isExtracted = flag;
      notifyListeners();
    }
    if (isExtracted) {
      await _fillExtentList();
    }
  }

  Future<void> deleteDownload() async {
    if (File(_downloadFilePath).existsSync()) {
      File(_downloadFilePath).deleteSync();
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

  Future<void> download() async {
    await checkIfDownloaded();
    if (isDownloaded) {
      return;
    }
    _downloadProcess = await Process.start(
      'curl',
      [
        '-O',
        _productUrlPath,
      ],
      workingDirectory: gsPath,
    );
    _downloadProcess?.stderr.transform(utf8.decoder).listen((data) {
      downloadProgress = data;
      notifyListeners();
    });
    final exitCode = await _downloadProcess?.exitCode;
    _downloadProcess = null;
    if (exitCode != 0) {
      isDownloaded = false;
      await deleteDownload();
      throw Exception('Failed to download $dmgName (exit code $exitCode)');
    }
    File(_downloadFilePath).setLastModifiedSync(date);
    isDownloaded = true;
  }

  static Future<void> downloadVersionList() async {
    final result = await Process.run('curl', [
      '$_productsUrlPath/',
    ]).timeout(const Duration(seconds: 2));
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    final versions = <Version>[];
    final lines = result.stdout.toString().split('\n');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    for (final line in lines) {
      // <a href="GemStone64Bit3.6.1-arm64.Darwin.dmg">GemStone64Bit3.6.1-arm64.Darwin.dmg</a>                06-Apr-2021 20:35           145306111
      final match = RegExp(
        r'href="[^"]*GemStone64Bit(\d+\.\d+\.\d+[\.\d]*)[^"]*".*?(\d{2}-\w{3}-\d{4})\s+\d{2}:\d{2}\s+(\d+)',
      ).firstMatch(line);
      if (match != null) {
        final versionString = match.group(1)!;
        final date = dateFormat.parse(match.group(2)!);
        final size = int.parse(match.group(3)!);
        final version = Version(name: versionString, date: date, size: size);
        await version.checkIfDownloaded();
        await version.checkIfExtracted();
        versions.add(version);
      }
    }
    versionList.addAll(versions.reversed.toList());
  }

  Future<void> _fillExtentList() async {
    extents.clear();
    final list = Directory('$productFilePath/bin').listSync();
    list.sort((a, b) => a.path.compareTo(b.path));
    for (final entity in list) {
      final path = entity.path;
      if (entity is File && path.endsWith('.dbf')) {
        final name = path.substring(
          productFilePath.length + 5,
          path.length - 4,
        );
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
          name: versionString,
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
          if (each.name == versionString) {
            version = each;
            break;
          }
        }
        if (version == null) {
          final stat = File(each.path).statSync();
          final version = Version(
            date: stat.modified,
            size: stat.size,
            name: versionString,
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

  Future<void> updateState() async {
    await checkIfDownloaded();
    await checkIfExtracted();
  }
}
