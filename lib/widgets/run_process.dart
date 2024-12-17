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
    await Navigator.of(context).push(
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
  List<Map<int, String>> log = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.heading.isNotEmpty) Text(widget.heading),
        Expanded(
          child: logWidget(),
        ),
        _cancelButton(),
      ],
    );
  }

  ElevatedButton _cancelButton() {
    return ElevatedButton(
      onPressed: () async {
        //
      },
      child: const Text('Cancel'),
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
    unawaited(waitForExit());
  }

  ListView logWidget() {
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
          ),
        );
      },
    );
  }

  Future<void> waitForExit() async {
    final exitCode = await widget.process.exitCode;
    if (mounted) {
      Navigator.of(context).pop();
    }
    if (exitCode != 0) {
      throw Exception('Process exit code $exitCode.');
    }
  }
}
