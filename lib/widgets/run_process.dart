import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

Future<void> runProcess({
  required BuildContext context,
  required Future<Process> processFuture,
  String heading = '',
  bool allowCancel = false,
}) async {
  final process = await processFuture;
  if (context.mounted) {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return RunProcess(
            process: process,
            heading: heading,
            allowCancel: allowCancel,
          );
        },
      ),
    );
    if (result != 0) {
      throw Exception('Process failed with exit code $result');
    }
  }
}

class RunProcess extends StatefulWidget {
  const RunProcess({
    required this.process,
    this.heading = '',
    this.allowCancel = false,
    super.key,
  });

  final bool allowCancel;
  final String heading;
  final Process process;

  @override
  RunProcessState createState() => RunProcessState();
}

class RunProcessState extends State<RunProcess> {
  late int exitCode;
  bool isRunning = true;
  List<Map<int, String>> log = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.heading),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: _logWidget(),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _cancelButton(),
                  SizedBox(width: 8),
                  _closeButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton _cancelButton() {
    return ElevatedButton(
      onPressed: isRunning
          ? () async {
              widget.process.kill();
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                Navigator.of(context).pop(exitCode);
              }
            }
          : null,
      child: const Text('Cancel'),
    );
  }

  ElevatedButton _closeButton() {
    return ElevatedButton(
      onPressed: !isRunning
          ? () async {
              if (mounted) {
                Navigator.of(context).pop(exitCode);
              }
            }
          : null,
      child: const Text('Close'),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.process.stdout.transform(utf8.decoder).listen((data) {
      setState(() {
        log.add({1: data});
      });
    });
    widget.process.stderr.transform(utf8.decoder).listen((data) {
      setState(() {
        log.add({2: data});
      });
    });
    unawaited(_waitForExit());
  }

  ListView _logWidget() {
    return ListView.builder(
      itemCount: log.length,
      itemBuilder: (context, index) {
        final entry = log[index];
        final key = entry.keys.first;
        final value = entry.values.first;
        return Text(
          value,
          style: TextStyle(
            color: key == 1 ? Colors.black : Colors.red,
            fontFamily: 'Courier New',
          ),
        );
      },
    );
  }

  Future<void> _waitForExit() async {
    exitCode = await widget.process.exitCode;
    isRunning = false;
    setState(() {});
  }
}
