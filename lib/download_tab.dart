import 'package:flutter/material.dart';
import 'package:gemstoneapp/database.dart';
import 'package:gemstoneapp/download_progress.dart';
import 'package:intl/intl.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  DownloadTabState createState() => DownloadTabState();
}

class DownloadTabState extends State<DownloadTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Database>>(
      // ignore: discarded_futures
      future: Database.versionList(),
      builder: (BuildContext context, AsyncSnapshot<List<Database>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (BuildContext context, int index) {
            final database = snapshot.data![index];
            final version = database.version;
            final date = database.date;
            final formattedDate = DateFormat('yyyy-MMM-dd').format(date);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 0.0,
              ),
              title: Row(
                children: [
                  Checkbox(
                    value: database.isDownloaded,
                    onChanged: (newValue) async {
                      if (newValue!) {
                        await download(context, database);
                      } else {
                        await database.delete();
                      }
                      setState(() {});
                    },
                  ),
                  SizedBox(
                    width: 60.0,
                    child: Text(version),
                  ),
                  SizedBox(
                    width: 200.0,
                    child: Text(formattedDate),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> download(BuildContext context, Database database) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return DownloadProgress(database: database);
        },
      ),
    );
    // try {
    //   await database.download();
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error: $e')),
    //   );
    // }
  }
}
