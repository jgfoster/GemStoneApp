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

Future<bool> isHostnameInEtcHosts() async {
  try {
    final hostname = Platform.localHostname;
    final hostsFile = File('/etc/hosts');
    
    if (!hostsFile.existsSync()) {
      return false;
    }
    
    final contents = await hostsFile.readAsString();
    final lines = contents.split('\n');
    
    for (final line in lines) {
      // Skip comments and empty lines
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      
      // Check if hostname appears in the line
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length > 1 && parts.sublist(1).contains(hostname)) {
        return true;
      }
    }
    
    return false;
  } catch (e) {
    return false;
  }
}
