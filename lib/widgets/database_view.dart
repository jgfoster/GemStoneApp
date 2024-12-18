import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/domain/gslist.dart';
import 'package:gemstoneapp/widgets/run_process.dart';

class DatabaseView extends StatefulWidget {
  const DatabaseView({required this.database, super.key});
  final Database database;

  @override
  DatabaseViewState createState() => DatabaseViewState();
}

class DatabaseViewState extends State<DatabaseView> {
  final _pathLength = 350.0;

  Widget _body() {
    return FutureBuilder(
      // ignore: discarded_futures
      future: GsList().fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stoneRow(),
              SizedBox(height: 8),
              _netLdiRow(),
              SizedBox(height: 8),
              _pathRow(),
              SizedBox(height: 8),
              _versionRow(),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.stoneName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _body(),
      ),
    );
  }

  Row _netLdiRow() {
    final ldiStartTime = widget.database.ldiStartTime;
    final startTimeString = ldiStartTime.toString();
    final whenStarted = ldiStartTime != null
        ? 'started ${startTimeString.substring(0, startTimeString.length - 7)}'
        : 'not running';
    return Row(
      children: [
        SizedBox(width: 80, child: Text('NetLDI:')),
        SizedBox(
          width: 100,
          child: Text(widget.database.ldiName),
        ),
        SizedBox(
          width: _pathLength - 100,
          child: Text(whenStarted),
        ),
        _startNetLdiButton(),
        SizedBox(width: 8),
        _stopNetLdiButton(),
      ],
    );
  }

  Widget _deleteDatabaseButton() {
    return Tooltip(
      message: 'Delete database',
      child: ElevatedButton(
        onPressed: () async {
          await _showDeleteConfirmationDialog(context, widget.database);
        },
        child: const Icon(Icons.delete),
      ),
    );
  }

  Row _pathRow() {
    return Row(
      children: [
        SizedBox(width: 80, child: Text('Path:')),
        SizedBox(
          width: _pathLength,
          child: Text(widget.database.path),
        ),
        _openFinderOn(widget.database.path),
        SizedBox(width: 8),
        _deleteDatabaseButton(),
      ],
    );
  }

  Widget _openFinderOn(String path) {
    return Tooltip(
      message: 'Open Finder',
      child: ElevatedButton(
        onPressed: () async {
          await Process.run('open', [path]);
        },
        child: const Icon(Icons.folder_open),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    Database database,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to delete ${database.stoneName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await database.deleteDatabase();
                setState(() {});
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _startNetLdiButton() {
    return Tooltip(
      message: 'Start NetLDI',
      child: ElevatedButton(
        onPressed: widget.database.ldiPid == null
            ? () async {
                try {
                  await runProcess(
                    context: context,
                    processFuture: widget.database.startNetLDI(),
                    heading: 'Starting ${widget.database.ldiName}',
                    allowCancel: true,
                  );
                  setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            : null,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _startStoneButton() {
    return Tooltip(
      message: 'Start Stone',
      child: ElevatedButton(
        onPressed: widget.database.stonePid == null
            ? () async {
                try {
                  await runProcess(
                    context: context,
                    processFuture: widget.database.startStone(),
                    heading: 'Starting ${widget.database.stoneName}',
                    allowCancel: true,
                  );
                  setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            : null,
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  Row _stoneRow() {
    final stoneStartTime = widget.database.stoneStartTime;
    final startTimeString = stoneStartTime.toString();
    final whenStarted = stoneStartTime != null
        ? 'started ${startTimeString.substring(0, startTimeString.length - 7)}'
        : 'not running';
    return Row(
      children: [
        SizedBox(width: 80, child: Text('Stone:')),
        SizedBox(
          width: 100,
          child: Text(widget.database.stoneName),
        ),
        SizedBox(
          width: _pathLength - 100,
          child: Text(whenStarted),
        ),
        _startStoneButton(),
        SizedBox(width: 8),
        _stopStoneButton(),
      ],
    );
  }

  Widget _stopNetLdiButton() {
    return Tooltip(
      message: 'Stop NetLDI',
      child: ElevatedButton(
        onPressed: widget.database.ldiPid != null
            ? () async {
                try {
                  await runProcess(
                    context: context,
                    processFuture: widget.database.stopNetLDI(),
                    heading: 'Stopping ${widget.database.ldiName}',
                  );
                  setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            : null,
        child: const Icon(Icons.stop),
      ),
    );
  }

  Widget _stopStoneButton() {
    return Tooltip(
      message: 'Stop Stone',
      child: ElevatedButton(
        onPressed: widget.database.stonePid != null
            ? () async {
                try {
                  await runProcess(
                    context: context,
                    processFuture: widget.database.stopStone(),
                    heading: 'Stopping ${widget.database.stoneName}',
                  );
                  setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            : null,
        child: const Icon(Icons.stop),
      ),
    );
  }

  Row _versionRow() {
    return Row(
      children: [
        SizedBox(width: 80, child: Text('Version:')),
        SizedBox(
          width: _pathLength,
          child: Text(widget.database.version.name),
        ),
        _openFinderOn(widget.database.version.productFilePath),
      ],
    );
  }
}
