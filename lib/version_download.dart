import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/version.dart';

class VersionDownload extends StatefulWidget {
  const VersionDownload({required this.version, super.key});

  final Version version;

  @override
  VersionDownloadState createState() => VersionDownloadState();
}

class VersionDownloadState extends State<VersionDownload> {
  bool isDownloading = false;
  bool isExtracting = false;
  String progressText = 'Downloading...';
  double progressPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.version.isDownloaded && !isDownloading) {
      startDownload(context);
    }
    if (isDownloading) {
      return downloadDialog();
    }
    if (!widget.version.isExtracted && !isExtracting) {
      startExtract(context);
    }
    if (isExtracting) {
      return extractDialog();
    }
    Future.delayed(const Duration(milliseconds: 1), () async {
      await widget.version.checkIfDownloaded();
      await widget.version.checkIfExtracted();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
    return const SizedBox.shrink();
  }

  void callback(String text) {
    if (text[2] == '%') {
      return; // ignore header
    }
    setState(() {
      progressText = text;
      progressPercent = double.tryParse(text.trim().split(' ')[0]) ?? 0.0;
    });
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

  void downloadError(BuildContext context, dynamic error) {
    isDownloading = false;
    isExtracting = false;
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }

  void downloadFinished(_) {
    isDownloading = false;
    setState(() {});
  }

  Dialog extractDialog() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            Text('Extracting...'),
          ],
        ),
      ),
    );
  }

  FutureOr<Null> extractFinished(_) {
    isExtracting = false;
    setState(() {
      progressText = 'Done extracting...';
    });
  }

  void startDownload(BuildContext context) {
    isDownloading = true;
    widget.version
        // ignore: discarded_futures
        .downloadVersion(callback)
        // ignore: discarded_futures
        .then(downloadFinished)
        // ignore: discarded_futures
        .catchError((error) {
      if (context.mounted) {
        downloadError(context, error);
      }
    });
  }

  void startExtract(BuildContext context) {
    isExtracting = true;
    widget.version
        // ignore: discarded_futures
        .extract()
        // ignore: discarded_futures
        .then(extractFinished)
        // ignore: discarded_futures
        .catchError((error) {
      if (context.mounted) {
        downloadError(context, error);
      }
    });
  }
}
