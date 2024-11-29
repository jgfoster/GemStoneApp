import 'package:flutter/material.dart';
import 'package:gemstoneapp/download_versions.dart';
import 'package:gemstoneapp/shared_memory.dart';

void main() {
  runApp(const GemStoneTools());
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
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.memory),
                  text: 'Configure Memory',
                ),
                Tab(
                  icon: Icon(Icons.download_for_offline),
                  text: 'Download Versions',
                ),
                Tab(
                  icon: Icon(Icons.dataset),
                  text: 'Manage Databases',
                ),
                Tab(
                  icon: Icon(Icons.table_rows),
                  text: 'List  Processes',
                ),
              ],
            ),
            title: const Text('GemStone/S 64 Bit SysAdmin Tools'),
          ),
          body: const TabBarView(
            children: [
              SharedMemory(),
              DownloadVersions(),
              Icon(Icons.dataset),
              Icon(Icons.table_rows),
            ],
          ),
        ),
      ),
    );
  }
}
