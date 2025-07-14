import 'dart:io';
import 'package:path_provider/path_provider.dart';

late String gsPath;

Future<void> getGsPath() async {
  final Directory dir = await getApplicationDocumentsDirectory();
  gsPath = dir.path;
  // /Users/jfoster/Library/Containers/com.gemtalk.gemstoneapp/Data/Documents
  // shows in Finder as
  // /Users/jfoster/Library/Containers/GemStone SysAdmin/Data/Documents
  if (!Directory(gsPath).existsSync()) {
    Directory(gsPath).createSync(recursive: true);
  }
}
