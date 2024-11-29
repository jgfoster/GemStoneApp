import 'package:flutter/material.dart';
import 'package:gemstoneapp/version.dart';
import 'package:gemstoneapp/version_download.dart';
import 'package:intl/intl.dart';

class DatabasesTab extends StatefulWidget {
  const DatabasesTab({super.key});

  @override
  DatabasesTabState createState() => DatabasesTabState();
}

class DatabasesTabState extends State<DatabasesTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Version>>(
      // ignore: discarded_futures
      future: Version.versionList(),
      builder: (BuildContext context, AsyncSnapshot<List<Version>> snapshot) {
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

  Future<void> download(BuildContext context, Version database) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return VersionDownload(database: database);
        },
      ),
    );
  }
}
