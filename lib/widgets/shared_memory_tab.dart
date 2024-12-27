import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SharedMemoryTab extends StatelessWidget {
  const SharedMemoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      // ignore: discarded_futures
      future: getSharedMemory(),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        // calculate the values in GB
        final shmmax = snapshot.data![0] / pow(2, 30);
        final shmall = snapshot.data![1] / pow(2, 18);
        if (shmmax >= 4 && shmall >= 4) {
          return Center(
            child: Text(
              'Shared memory is already configured at '
              '${min(shmall, shmmax)} GB, which is at least 4.0 GB.',
            ),
          );
        }
        return Center(
          child: Column(
            children: [
              const Text('Shared memory is not configured with at least 4GB.'),
              const Text('Please copy the following text to a file named'),
              const SelectableText(
                'com.gemtalksystems.shared-memory.plist',
                style: TextStyle(fontFamily: 'Courier New'),
              ),
              const Text('and place it in'),
              ElevatedButton(
                onPressed: () async {
                  await Process.run('open', ['/Library/LaunchDaemons/']);
                },
                child: const Text('/Library/LaunchDaemons/'),
              ),
              const Text(
                'change ownership to root:wheel (using Terminal and your admin password),',
              ),
              const SelectableText(
                'sudo chown root:wheel /Library/LaunchDaemons/com.gemtalksystems.shared-memory.plist',
                style: TextStyle(fontFamily: 'Courier New'),
              ),
              const Text('and then restart your computer.'),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ), // Adjust the color as needed
                ),
                child: SizedBox(
                  height:
                      200, // Adjust the height as needed to show approximately 10 lines
                  child: SingleChildScrollView(
                    child: SelectableText(
                      plist(),
                      style: const TextStyle(fontFamily: 'Courier New'),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: plist()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text copied to clipboard')),
                    );
                  }
                },
                child: const Text('Copy plist contents to clipboard'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<int>> getSharedMemory() async {
    final ProcessResult result = await Process.run('sysctl', ['-a']);
    final List<String> output = result.stdout.split('\n');
    final line1 = output.where((line) => line.contains('kern.sysv.shmmax'));
    final List<String> parts1 = line1.first.split(':');
    final int shmmax = int.parse(parts1[1].trim());
    final line2 = output.where((line) => line.contains('kern.sysv.shmall'));
    final List<String> parts2 = line2.first.split(':');
    final int shmall = int.parse(parts2[1].trim());
    return <int>[shmmax, shmall];
  }

  String plist() {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>shmemsetup</string>
  <key>UserName</key>
  <string>root</string>
  <key>GroupName</key>
  <string>wheel</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/sbin/sysctl</string>
    <string>kern.sysv.shmmax=4294967296</string>
    <string>kern.sysv.shmall=1048576</string>
  </array>
  <key>KeepAlive</key>
  <false/>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
''';
  }
}
