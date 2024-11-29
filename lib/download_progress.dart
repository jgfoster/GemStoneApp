import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/database.dart';

class DownloadProgress extends StatefulWidget {
  const DownloadProgress({required this.database, super.key});

  final Database database;

  @override
  DownloadProgressState createState() => DownloadProgressState();
}

class DownloadProgressState extends State<DownloadProgress> {
  bool isDownloading = false;
  String progressText = 'Downloading...';
  double progressPercent = 0.0;

  void callback(String text) {
    if (text.startsWith('  %') || text.startsWith('   ')) {
      return;
    }
    setState(() {
      progressText = text;
      if (text.startsWith(' ')) {
        progressPercent = double.tryParse(text.trim().split(' ')[0]) ?? 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isDownloading) {
      isDownloading = true;
      // ignore: discarded_futures
      widget.database.download(callback).then((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        // ignore: discarded_futures
      }).catchError((error) {
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
              onPressed: () async => widget.database.cancelDownload(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
