import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/version.dart';
import 'package:gemstoneapp/widgets/version_download.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  DownloadTabState createState() => DownloadTabState();
}

class DownloadTabState extends State<DownloadTab> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final rows = _rows(context);
    return VisibilityDetector(
      key: Key('scroll-view-key'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction > 0) {
          // The widget is visible, you can refresh the state or perform actions here
          setState(() {});
        }
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: columns,
          rows: rows,
        ),
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
      const DataColumn(
        label: Expanded(
          child: Text(
            'Folder',
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('App gained focus');
      setState(() {}); // Refresh the state when the app gains focus
    } else if (state == AppLifecycleState.paused) {
      print('App lost focus');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  Widget _downloadCheckbox(Version version, BuildContext context) {
    return Tooltip(
      message: 'Check to download, uncheck to delete downloaded file.',
      child: Checkbox(
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
    try {
      await version.extract();
    } catch (e) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Extraction Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _extractCheckbox(Version version, BuildContext context) {
    return Tooltip(
      message: 'Check to extract, uncheck to delete extracted files.',
      child: Checkbox(
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
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Widget _openFinderOn(String path) {
    return Tooltip(
      message: 'Open folder',
      child: ElevatedButton(
        onPressed: () async {
          await Process.run('open', [path]);
        },
        child: const Icon(Icons.folder_open),
      ),
    );
  }

  List<DataRow> _rows(BuildContext context) {
    return Version.versionList.map((version) {
      final versionName = version.name;
      final date = version.date;
      final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
      return DataRow(
        cells: <DataCell>[
          DataCell(Text(versionName)),
          DataCell(Text(formattedDate)),
          DataCell(_downloadCheckbox(version, context)),
          DataCell(_extractCheckbox(version, context)),
          DataCell(
            version.isExtracted
                ? _openFinderOn(version.productFilePath)
                : Text(''),
          ),
        ],
      );
    }).toList();
  }
}
