import 'package:flutter/material.dart';
import 'package:gemstoneapp/database.dart';
import 'package:gemstoneapp/new_database.dart';
import 'package:gemstoneapp/version.dart';
import 'package:gemstoneapp/version_download.dart';

class DatabasesTab extends StatefulWidget {
  const DatabasesTab({super.key});

  @override
  DatabasesTabState createState() => DatabasesTabState();
}

class DatabasesTabState extends State<DatabasesTab> {
  Database? _database;

  Column addRemoveButtons() {
    return Column(
      children: [
        ElevatedButton(
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
        SizedBox(height: 8.0),
        ElevatedButton(
          onPressed: _database == null
              ? null
              : () async {
                  await _showDeleteConfirmationDialog(context);
                },
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 1, child: databasesRow()),
        Expanded(flex: 2, child: Text('Database Details')),
      ],
    );
  }

  Widget databasesRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: databaseList()),
          addRemoveButtons(),
        ],
      ),
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
          if (selected!) {
            setState(() {
              _database = database;
            });
          }
        },
        selected: _database == database,
        cells: <DataCell>[
          DataCell(Text(database.version.version)),
          DataCell(Text(database.stoneName)),
          DataCell(Text(database.ldiName)),
        ],
      );
    }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: columns,
        rows: rows,
      ),
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
