import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/widgets/new_database.dart';
import 'package:gemstoneapp/widgets/run_process.dart';

class DatabasesTab extends StatefulWidget {
  const DatabasesTab({super.key});

  @override
  DatabasesTabState createState() => DatabasesTabState();
}

class DatabasesTabState extends State<DatabasesTab> {
  Widget _actions(Database database) {
    return Row(
      children: [
        _deleteDatabaseButton(database),
        SizedBox(width: 4),
        _startDatabaseButton(database),
        SizedBox(width: 4),
        _stopDatabaseButton(database),
        SizedBox(width: 4),
        _openFinder(database),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: _databaseList()),
          SizedBox(width: 8),
          _newDatabaseButton(),
        ],
      ),
    );
  }

  List<DataColumn> get _columns {
    return <DataColumn>[
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
            'Stone',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'NetLDI',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'Actions',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
  }

  Widget _databaseList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: _columns,
            rows: _rows(),
          ),
        ),
      ],
    );
  }

  Tooltip _deleteDatabaseButton(Database database) {
    return Tooltip(
      message: 'Delete database',
      child: ElevatedButton(
        onPressed: () async {
          await _showDeleteConfirmationDialog(context, database);
        },
        child: const Icon(Icons.remove),
      ),
    );
  }

  Tooltip _newDatabaseButton() {
    return Tooltip(
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
    );
  }

  Tooltip _openFinder(Database database) {
    return Tooltip(
      message: 'Open database folder',
      child: ElevatedButton(
        onPressed: () async {
          await Process.run('open', [database.path]);
        },
        child: const Icon(Icons.folder_open),
      ),
    );
  }

  List<DataRow> _rows() {
    return Database.databaseList.map((database) {
      return DataRow(
        cells: <DataCell>[
          DataCell(Text(database.version.name)),
          DataCell(Text(database.stoneName)),
          DataCell(Text(database.ldiName)),
          DataCell(_actions(database)),
        ],
      );
    }).toList();
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

  Tooltip _startDatabaseButton(Database database) {
    return Tooltip(
      message: 'Start database',
      child: ElevatedButton(
        onPressed: () async {
          await runProcess(
            context: context,
            processFuture: database.startNetLDI(),
            heading: 'Starting ${database.stoneName}',
          );
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Tooltip _stopDatabaseButton(Database database) {
    return Tooltip(
      message: 'Stop database',
      child: ElevatedButton(
        onPressed: () async {
          await database.stop();
        },
        child: const Icon(Icons.stop),
      ),
    );
  }
}
