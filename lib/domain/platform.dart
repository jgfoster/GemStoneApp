import 'dart:io';
import 'package:path_provider/path_provider.dart';

late String gsPath;

Future<void> getGsPath() async {
  final Directory dir = await getApplicationDocumentsDirectory();
  gsPath = '${dir.path}/GemStone';
  if (!Directory(gsPath).existsSync()) {
    Directory(gsPath).createSync(recursive: true);
  }
}
