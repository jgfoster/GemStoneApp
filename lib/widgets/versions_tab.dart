import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/version.dart';
import 'package:gemstoneapp/widgets/version_download.dart';
import 'package:intl/intl.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  DownloadTabState createState() => DownloadTabState();
}

class DownloadTabState extends State<DownloadTab> {
  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final rows = _rows(context);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: columns,
        rows: rows,
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
  }

  Future<void> _deleteDownload(BuildContext context, Version version) async {
    // Show the "Deleting" dialog
    unawaited(
      showDialog(
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
                  Text('Deleting download...'),
                ],
              ),
            ),
          );
        },
      ),
    );
    await version.deleteDownload();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteExtract(BuildContext context, Version version) async {
    unawaited(
      showDialog(
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
                  Text('Deleting extract...'),
                ],
              ),
            ),
          );
        },
      ),
    );
    await version.deleteExtract();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _download(BuildContext context, Version version) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return VersionDownload(version: version);
        },
      ),
    );
  }

  Future<void> _extract(BuildContext context, Version version) async {
    unawaited(
      showDialog(
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
                  Text('Extracting download...'),
                ],
              ),
            ),
          );
        },
      ),
    );
    await version.extract();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  List<DataRow> _rows(BuildContext context) {
    return Version.versionList.map((version) {
      final versionName = version.version;
      final date = version.date;
      final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
      return DataRow(
        cells: <DataCell>[
          DataCell(Text(versionName)),
          DataCell(Text(formattedDate)),
          DataCell(
            Checkbox(
              value: version.isDownloaded,
              onChanged: (newValue) async {
                if (newValue!) {
                  await _download(context, version);
                } else {
                  await _deleteDownload(context, version);
                }
                setState(() {});
              },
            ),
          ),
          DataCell(
            Checkbox(
              value: version.isExtracted,
              onChanged: (newValue) async {
                if (newValue!) {
                  await _extract(context, version);
                } else {
                  await _deleteExtract(context, version);
                }
                setState(() {});
              },
            ),
          ),
        ],
      );
    }).toList();
  }
}
