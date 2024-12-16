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
            'Date',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'Downloaded',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text(
            'Extracted',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
    final rows = Version.versionList.map((version) {
      final versionName = version.version;
      final date = version.date;
      final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
      return DataRow(
        cells: <DataCell>[
          DataCell(
            Checkbox(
              value: version.isExtracted,
              onChanged: (newValue) async {
                if (newValue!) {
                  await download(context, version);
                } else {
                  await delete(context, version);
                }
                setState(() {});
              },
            ),
          ),
          DataCell(Text(versionName)),
          DataCell(Text(formattedDate)),
          DataCell(Text(version.isDownloaded ? 'Yes' : 'No')),
          DataCell(Text(version.isExtracted ? 'Yes' : 'No')),
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

  Future<void> delete(BuildContext context, Version version) async {
    // Show the "Deleting" dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting...'),
              ],
            ),
          ),
        );
      },
    );

    // Perform the deletion
    await version.deleteProduct();

    // Dismiss the "Deleting" dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> download(BuildContext context, Version version) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return VersionDownload(version: version);
        },
      ),
    );
  }
}
