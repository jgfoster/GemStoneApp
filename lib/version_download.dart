import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/platform.dart';
import 'package:gemstoneapp/version.dart';

class VersionDownload extends StatefulWidget {
  const VersionDownload({required this.version, super.key});

  final Version version;

  @override
  VersionDownloadState createState() => VersionDownloadState();
}

class VersionDownloadState extends State<VersionDownload> {
  bool isDownloading = false;
  String progressText = 'Downloading...';
  double progressPercent = 0.0;

  void callback(String text) {
    if (text[2] == '%') {
      return; // ignore header
    }
    setState(() {
      progressText = text;
      progressPercent = double.tryParse(text.trim().split(' ')[0]) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.version.isDownloaded && !isDownloading) {
      startDownload(context);
    }
    if (isDownloading) {
      return downloadDialog();
    }
    return extractDialog();
  }

  Dialog downloadDialog() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progressPercent / 100),
            const SizedBox(height: 16),
            const Text(
              '   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current',
              style: TextStyle(fontFamily: 'Courier New'),
            ),
            const Text(
              '                                 Dload  Upload   Total   Spent    Left  Speed',
              style: TextStyle(fontFamily: 'Courier New'),
            ),
            Text(
              progressText,
              style: const TextStyle(fontFamily: 'Courier New'),
            ),
            ElevatedButton(
              onPressed: () async => widget.version.cancelDownload(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Dialog extractDialog() {
    unawaited(Process.run('open', [gsPath]));
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We have downloaded ${widget.version.dmgName}.'),
            const Text(
              'For security reasons, you must extract it manually.\n'
              'Open the .dmg file and drag the contents to the open\n'
              'GemStone folder. You may then eject the disk image.',
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.version.checkIfExtracted();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void startDownload(BuildContext context) {
    unawaited(Process.run('open', [gsPath]));
    isDownloading = true;
    // ignore: discarded_futures
    widget.version.download(callback).then((_) {
      isDownloading = false;
      setState(() {
        progressText = 'Extracting...';
      });
      // ignore: discarded_futures
    }).catchError((error) {
      isDownloading = false;
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
          ),
        );
      }
    });
  }
}
