import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/widgets/database_view.dart';
import 'package:gemstoneapp/widgets/new_database.dart';

class DatabasesTab extends StatefulWidget {
  const DatabasesTab({super.key});

  @override
  DatabasesTabState createState() => DatabasesTabState();
}

class DatabasesTabState extends State<DatabasesTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: _databaseList()),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _newDatabaseButton(),
            ],
          ),
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
    ];
  }

  Widget _databaseList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            showCheckboxColumn: false,
            columns: _columns,
            rows: _rows(),
          ),
        ),
      ],
    );
  }

  Widget _newDatabaseButton() {
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

  DataRow row(Database database) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(database.version.name)),
        DataCell(Text(database.stoneName)),
        DataCell(Text(database.ldiName)),
      ],
      onSelectChanged: (selected) async {
        if (selected != null && selected) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatabaseView(database: database),
            ),
          );
          setState(() {});
        }
      },
    );
  }

  List<DataRow> _rows() {
    return Database.databaseList.map((database) {
      return row(database);
    }).toList();
  }
}
