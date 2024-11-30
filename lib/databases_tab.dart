import 'package:flutter/material.dart';
import 'package:gemstoneapp/database.dart';
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
    return FutureBuilder<List<Database>>(
      // ignore: discarded_futures
      future: Database.databaseList(),
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
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 0.0,
              ),
              title: Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (newValue) async {
                      //
                      setState(() {});
                    },
                  ),
                  SizedBox(
                    width: 60.0,
                    child: Text('abc'),
                  ),
                  SizedBox(
                    width: 200.0,
                    child: Text('xy'),
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
