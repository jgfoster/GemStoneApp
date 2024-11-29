import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/database.dart';
import 'package:intl/intl.dart';

class DownloadVersions extends StatelessWidget {
  const DownloadVersions({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Database>>(
      // ignore: discarded_futures
      future: getVersionList(),
      builder: (BuildContext context, AsyncSnapshot<List<Database>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (BuildContext context, int index) {
            final database = snapshot.data![index];
            final version = database.version;
            final date = database.date;
            final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 0.0,
              ),
              title: Row(
                children: [
                  Checkbox(
                    value: database.isDownloaded,
                    onChanged: (newValue) {},
                  ),
                  SizedBox(
                    width: 60.0,
                    child: Text(version),
                  ),
                  SizedBox(
                    width: 200.0,
                    child: Text(formattedDate),
                  ),
                ],
              ),
              onTap: () async {
                await downloadVersion(snapshot.data![index].version);
              },
            );
          },
        );
      },
    );
  }

  Future<void> downloadVersion(String version) async {
    // get https://downloads.gemtalksystems.com/platforms/i386.Darwin/3.5.0/
    final result = await Process.run('curl', [
      'https://downloads.gemtalksystems.com/platforms/i386.Darwin/$version/',
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to get version list');
    }
    final lines = result.stdout.toString().split('\n');
    for (final line in lines) {
      final match = RegExp('href="([^"]+)"').firstMatch(line);
      if (match != null) {
        final file = match.group(1)!;
        if (file.endsWith('.dmg')) {
          // download https://downloads.gemtalksystems.com/platforms/i386.Darwin/3.5.0/GemStone64Bit3.5.0-1.dmg
          final result = await Process.run('curl', [
            '-O',
            'https://downloads.gemtalksystems.com/platforms/i386.Darwin/$version/$file',
          ]);
          if (result.exitCode != 0) {
            throw Exception('Failed to download $file');
          }
        }
      }
    }
  }

  Future<List<Database>> getVersionList() async {
    const path = 'http://downloads.gemtalksystems.com/platforms/arm64.Darwin/';
    final result = await Process.run('curl', [path]);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    final versions = <Database>[];
    final lines = result.stdout.toString().split('\n');
    for (final line in lines) {
      final match = RegExp(
        r'href="[^"]*GemStone64Bit(\d+\.\d+\.\d+)[^"]*".*?(\d{2}-\w{3}-\d{4})',
      ).firstMatch(line);
      if (match != null) {
        final version = match.group(1)!;
        final dateFormat = DateFormat('dd-MMM-yyyy');
        final date = dateFormat.parse(match.group(2)!);
        final database = Database(version: version, date: date);
        await database.checkIfDownloaded();
        versions.add(database);
      }
    }
    return versions.reversed.toList();
  }
}
