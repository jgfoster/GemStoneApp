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
  String progressText = 'Downloading...';
  double progressPercent = 10.0;

  void updateProgress(String text, double percent) {
    setState(() {
      progressText = text;
      progressPercent = percent;
    });
  }

  void callback(String text) {
    print(text);
  }

  @override
  Widget build(BuildContext context) {
    unawaited(widget.database.download(callback));
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progressPercent),
            const SizedBox(height: 16),
            Text(progressText),
          ],
        ),
      ),
    );
  }
}

// Future<void> showProgressDialog(
//   BuildContext context,
//   DownloadProgressState progressDialogState,
// ) async {
//   await showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return const DownloadProgress();
//     },
//   ).then((_) {
//     // Optionally handle dialog close
//   });
// }

// void hideProgressDialog(BuildContext context) {
//   Navigator.of(context).pop();
// }

// Future<void> doWithProgress(
//   BuildContext context,
//   Future<void> Function(void Function(String) callback) operation,
// ) async {
//   final progressDialogState = DownloadProgressState();
//   await showProgressDialog(context, progressDialogState);

//   await operation((String data) {
//     progressDialogState.updateProgress(data, 0.0);
//   }).then((_) {
//     if (context.mounted) {
//       hideProgressDialog(context);
//     }
//   }).catchError((error) {
//     if (context.mounted) {
//       hideProgressDialog(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $error')),
//       );
//     }
//   });
// }
