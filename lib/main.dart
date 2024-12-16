import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/domain/platform.dart';
import 'package:gemstoneapp/domain/version.dart';
import 'package:gemstoneapp/widgets/databases_tab.dart';
import 'package:gemstoneapp/widgets/shared_memory_tab.dart';
import 'package:gemstoneapp/widgets/versions_tab.dart';

void main() async {
  await setup();
  runApp(const GemStoneTools());
}

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getGsPath();
  if (!Directory('$gsPath/locks').existsSync()) {
    Directory('$gsPath/locks').createSync(recursive: true);
  }
  await Version.buildVersionList();
  await Database.buildDatabaseList();
}

class GemStoneTools extends StatelessWidget {
  const GemStoneTools({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            bottom: tabBar(),
            title: const Text('GemStone/S 64 Bit SysAdmin Tools'),
          ),
          body: const TabBarView(
            children: [
              SharedMemoryTab(),
              DownloadTab(),
              DatabasesTab(),
              Icon(Icons.table_rows),
            ],
          ),
        ),
      ),
    );
  }

  TabBar tabBar() {
    return const TabBar(
      tabs: [
        Tab(
          icon: Icon(Icons.memory),
          text: 'Memory',
        ),
        Tab(
          icon: Icon(Icons.download_for_offline),
          text: 'Versions',
        ),
        Tab(
          icon: Icon(Icons.dataset),
          text: 'Databases',
        ),
        Tab(
          icon: Icon(Icons.table_rows),
          text: 'Processes',
        ),
      ],
    );
  }
}
