import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

late String gemstoneGlobalDir;
late String gemstoneProduct;

Future<void> getGsPath() async {
  final Directory dir = await getApplicationDocumentsDirectory();
  gemstoneGlobalDir = dir.path;
  // /Users/jfoster/Library/Containers/com.gemtalk.gemstoneapp/Data/Documents
  // shows in Finder as
  // /Users/jfoster/Library/Containers/GemStone SysAdmin/Data/Documents
  if (!Directory(gemstoneGlobalDir).existsSync()) {
    Directory(gemstoneGlobalDir).createSync(recursive: true);
  }

  const channel = MethodChannel('com.gemtalk.gemstone');
  final x = await channel.invokeMethod<String>('getExecutablePath');
  if (x != null && Directory('$x/bin').existsSync()) {
    gemstoneProduct = x;
  } else {
    throw SignalException('GemStone product not found');
  }
}
