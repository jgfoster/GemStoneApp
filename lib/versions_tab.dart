import 'package:flutter/material.dart';
import 'package:gemstoneapp/version.dart';
import 'package:gemstoneapp/version_download.dart';
import 'package:intl/intl.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  DownloadTabState createState() => DownloadTabState();
}

class DownloadTabState extends State<DownloadTab> {
  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      const DataColumn(
        label: Expanded(
          child: Text(
            'Installed',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
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
            'Release Date',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
    final rows = Version.versionList.map((database) {
      final version = database.version;
      final date = database.date;
      final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
      return DataRow(
        cells: <DataCell>[
          DataCell(
            Checkbox(
              value: database.isExtracted,
              onChanged: (newValue) async {
                if (newValue!) {
                  await download(context, database);
                } else {
                  await database.deleteProduct();
                }
                setState(() {});
              },
            ),
          ),
          DataCell(Text(version)),
          DataCell(Text(formattedDate)),
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
}
