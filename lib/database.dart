import 'dart:async';
import 'dart:io';
import 'package:gemstoneapp/version.dart';
import 'package:yaml/yaml.dart';

class Database {
  Database({
    required this.version,
    this.baseExtent = 'extent0',
    this.ldiName = 'gs64ldi',
    this.path = '',
    this.stoneName = 'gs64stone',
  });

  static List<Database> databaseList = [];
  static String databasesDir = '${Directory.current.path}/Documents/GemStone';
  String baseExtent;
  String ldiName;
  String path;
  String stoneName;
  Version version;

  Future<void> createDatabase() async {
    var i = 1;
    while (Directory('$databasesDir/db-$i').existsSync()) {
      i++;
    }
    Directory('$databasesDir/db-$i').createSync();
    Directory('$databasesDir/db-$i/conf').createSync();
    Directory('$databasesDir/db-$i/data').createSync();
    Directory('$databasesDir/db-$i/log').createSync();
    Directory('$databasesDir/db-$i/stat').createSync();
    final yamlString = '---\n'
        'baseExtent: "$baseExtent.dbf"\n'
        'ldiName: "$ldiName"\n'
        'stoneName: "$stoneName"\n'
        'version: "${version.version}"\n';
    final yamlFile = File('$databasesDir/db-$i/database.yaml');
    await yamlFile.writeAsString(yamlString);
    databaseList.add(this);
  }

  static Future<void> buildDatabaseList() async {
    if (!Directory(databasesDir).existsSync()) {
      Directory(databasesDir).createSync(recursive: true);
    }
    databaseList.clear();
    final entries = Directory(databasesDir).listSync();
    for (final each in entries) {
      if (await FileSystemEntity.isDirectory(each.path)) {
        final yamlFile = File('${each.path}/database.yaml');
        if (yamlFile.existsSync()) {
          final yamlString = await yamlFile.readAsString();
          final yaml = loadYaml(yamlString);
          final version = Version.versionList.firstWhere(
            (element) => element.version == yaml['version'],
          );
          databaseList.add(
            Database(
              version: version,
              baseExtent: yaml['baseExtent'],
              ldiName: yaml['ldiName'],
              path: each.path,
              stoneName: yaml['stoneName'],
            ),
          );
        }
      }
    }
  }
}
