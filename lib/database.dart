import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gemstoneapp/platform.dart';
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
  String baseExtent;
  String ldiName;
  String path;
  String stoneName;
  Version version;

  static Future<void> buildDatabaseList() async {
    if (!Directory(gsPath).existsSync()) {
      Directory(gsPath).createSync(recursive: true);
    }
    databaseList.clear();
    final entries = Directory(gsPath).listSync();
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

  Future<void> copyExtent(String path) async {
    final source = File('${version.productFilePath}/bin/$baseExtent.dbf');
    final destination = File('$path/data/extent0.dbf');
    await source.copy(destination.path);
    await Process.run('chmod', ['u+w', destination.path]);
  }

  Future<void> copyKeyFile(String path) async {
    final source = File('${version.productFilePath}/sys/community.starter.key');
    final destination = File('$path/conf/gemstone.key');
    await source.copy(destination.path);
  }

  Future<void> createDatabase() async {
    var i = 1;
    while (Directory('$gsPath/db-$i').existsSync()) {
      i++;
    }
    path = '$gsPath/db-$i';
    Directory(path).createSync();
    Directory('$path/conf').createSync();
    Directory('$path/data').createSync();
    Directory('$path/log').createSync();
    Directory('$path/stat').createSync();
    await createYamlFile(path);
    await createGemConf(path);
    await createStoneConf(path);
    await createSystemConf(path);
    await copyKeyFile(path);
    await copyExtent(path);
    databaseList.add(this);
  }

  Future<void> createGemConf(String path) async {
    final string =
        '# Edit this file to change your gem or topaz configuration\n'
        '\n'
        'GEM_TEMPOBJ_CACHE_SIZE = 50000;\n'
        'GEM_TEMPOBJ_POMGEN_PRUNE_ON_VOTE = 90;\n'
        '\n'
        '# Set the following to FALSE if you get an error\n'
        '# related to native code when stepping in the debugger\n'
        'GEM_NATIVE_CODE_ENABLED = TRUE;\n';
    final file = File('$path/conf/gem.conf');
    await file.writeAsString(string);
  }

  Future<void> createStoneConf(String path) async {
    final string = '# Edit this file to change your stone configuration.\n'
        '# For example, you might want a larger Shared Page Cache.\n'
        '\n'
        'SHR_PAGE_CACHE_SIZE_KB = 100000;\n'
        'KEYFILE = "$path/conf/gemstone.key";\n';
    final file = File('$path/conf/$stoneName.conf');
    await file.writeAsString(string);
  }

  Future<void> createSystemConf(String path) async {
    final string =
        '# See \$GEMSTONE/data/system.conf for descriptions of these lines.\n'
        '# In general, this file should not be edited.\n'
        '# You may customize the stone config file (stonename.conf) or gem.conf\n'
        '\n'
        'DBF_EXTENT_NAMES = "$gsPath/data/extent0.dbf";\n'
        'STN_TRAN_FULL_LOGGING = TRUE;\n'
        'STN_TRAN_LOG_DIRECTORIES = "$gsPath/data/";\n'
        'STN_TRAN_LOG_SIZES = 1000, 1000;\n';
    final file = File('$path/conf/system.conf');
    await file.writeAsString(string);
  }

  Future<void> createYamlFile(String path) async {
    final string = '---\n'
        'baseExtent: "$baseExtent.dbf"\n'
        'ldiName: "$ldiName"\n'
        'stoneName: "$stoneName"\n'
        'version: "${version.version}"\n';
    final file = File('$path/database.yaml');
    await file.writeAsString(string);
  }

  Future<void> deleteDatabase() async {
    await Directory(path).delete(recursive: true);
    Database.databaseList.remove(this);
  }

  Map<String, String> environment() {
    return {
      'GEMSTONE': version.productFilePath,
      'GEMSTONE_SYS_CONF': '$path/conf',
      'GEMSTONE_GLOBAL_DIR': gsPath,
      'GEMSTONE_LOG': '$path/log/$stoneName.log',
      'GEMSTONE_EXE_CONF': '$path/conf',
      'GEMSTONE_NRS_ALL': '#netldi:$ldiName#dir:$path#log:$path/log/%N_%P.log',
      'PATH': '${version.productFilePath}/bin:${Platform.environment['PATH']}',
      'DYLD_LIBRARY_PATH':
          '${version.productFilePath}/lib:${Platform.environment['DYLD_LIBRARY_PATH']}',
      'MANPATH':
          '${version.productFilePath}/doc:${Platform.environment['MANPATH']}',
    };
  }

  // Future<void> start() async {
  //   final process = await Process.start(
  //     '${version.productFilePath}/bin/$ldiName',
  //     ['start', '-l', '$path/log', '-d', path],
  //   );
  //   process.stdout.transform(utf8.decoder).listen((data) {
  //     print(data);
  //   });
  //   process.stderr.transform(utf8.decoder).listen((data) {
  //     print(data);
  //   });
  //   await process.exitCode;
  // }
}