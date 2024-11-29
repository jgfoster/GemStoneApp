import 'dart:io';

class Database {
  Database({
    required this.date,
    required this.version,
  });
  final DateTime date;
  late bool isDownloaded = false;
  final String version;

  Future<void> checkIfDownloaded() async {
    final directory = Directory.current;
    print(directory);
    // final files = directory.listSync();
    // for (final file in files) {
    //   if (file is File) {
    //     if (file.path.contains(version)) {
    //       isDownloaded = true;
    //       break;
    //     }
    //   }
    // }
  }
}
