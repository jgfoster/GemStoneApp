import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/version.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!widget.version.isDownloaded && !isDownloading) {
      startDownload(context);
    }
    if (isDownloading) {
      return _downloadDialog();
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

  void _callback(String text) {
    if (text[2] == '%') {
      return; // ignore header
    }
    setState(() {
      progressText = text;
      progressPercent = double.tryParse(text.trim().split(' ')[0]) ?? 0.0;
    });
  }

  ElevatedButton _cancelButton() {
    return ElevatedButton(
      onPressed: () async => widget.version.cancelDownload(),
      child: const Text('Cancel'),
    );
  }

  Dialog _downloadDialog() {
    final line1 =
        '   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current';
    final line2 =
        '                                 Dload  Upload   Total   Spent    Left  Speed';
    final courierStyle = TextStyle(fontFamily: 'Courier New');
    final headingStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0);
    return Dialog.fullscreen(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Downloading ${widget.version.name}...', style: headingStyle),
            const SizedBox(height: 16),
            CircularProgressIndicator(value: progressPercent / 100),
            const SizedBox(height: 16),
            Text(line1, style: courierStyle),
            Text(line2, style: courierStyle),
            Text(progressText, style: courierStyle),
            const SizedBox(height: 32),
            _cancelButton(),
          ],
        ),
      ),
    );
  }

  void _downloadError(BuildContext context, dynamic error) {
    isDownloading = false;
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }

  void _downloadFinished(_) {
    isDownloading = false;
    setState(() {});
  }

  void startDownload(BuildContext context) {
    isDownloading = true;
    widget.version
        // ignore: discarded_futures
        .download(_callback)
        // ignore: discarded_futures
        .then(_downloadFinished)
        // ignore: discarded_futures
        .catchError((error) {
      if (context.mounted) {
        _downloadError(context, error);
      }
    });
  }
}
