import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/domain/platform.dart';
import 'package:gemstoneapp/domain/version.dart';
import 'package:gemstoneapp/widgets/new_database.dart';
import 'package:gemstoneapp/widgets/version_download.dart';

class DatabasesTab extends StatefulWidget {
  const DatabasesTab({super.key});

  @override
  DatabasesTabState createState() => DatabasesTabState();
}

class DatabasesTabState extends State<DatabasesTab> {
  Database? _database;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: databaseList()),
          SizedBox(width: 8),
          buttons(),
        ],
      ),
    );
  }

  Widget buttons() {
    return Column(
      children: [
        Tooltip(
          message: 'Create a new database',
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewDatabaseForm(),
                ),
              );
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
        ),
        SizedBox(height: 8),
        Tooltip(
          message: 'Delete database',
          child: ElevatedButton(
            onPressed: _database == null
                ? null
                : () async {
                    await _showDeleteConfirmationDialog(context);
                  },
            child: const Icon(Icons.remove),
          ),
        ),
        SizedBox(height: 8),
        Tooltip(
          message: 'Start database',
          child: ElevatedButton(
            onPressed: _database == null
                ? null
                : () async {
                    await _database!.start();
                  },
            child: const Icon(Icons.play_arrow),
          ),
        ),
        SizedBox(height: 8),
        Tooltip(
          message: 'Stop database',
          child: ElevatedButton(
            onPressed: _database == null
                ? null
                : () async {
                    await _database!.stop();
                  },
            child: const Icon(Icons.stop),
          ),
        ),
        SizedBox(height: 8),
        Tooltip(
          message: 'Open database folder',
          child: ElevatedButton(
            onPressed: () async {
              await Process.run('open', [_database?.path ?? gsPath]);
            },
            child: const Icon(Icons.folder_open),
          ),
        ),
      ],
    );
  }

  Widget databaseList() {
    final columns = <DataColumn>[
      const DataColumn(
        label: Expanded(
          child: Text(
            'Version',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'Stone Name',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'NetLDI Name',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
    final rows = Database.databaseList.map((database) {
      return DataRow(
        onSelectChanged: (selected) {
          setState(() {
            _database = selected! ? database : null;
          });
        },
        selected: _database == database,
        cells: <DataCell>[
          DataCell(Text(database.version.version)),
          DataCell(Text(database.stoneName)),
          DataCell(Text(database.ldiName)),
        ],
      );
    }).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ],
    );
  }

  Future<void> download(BuildContext context, Version database) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return VersionDownload(version: database);
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to delete ${_database!.stoneName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _database!.deleteDatabase();
                _database = null;
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
}
