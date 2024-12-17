import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/platform.dart';

class GsListTab extends StatelessWidget {
  const GsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // ignore: discarded_futures
      future: _fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final lastUpdateTime = DateTime.now().toString().split('.').first;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  snapshot.data!,
                  style: TextStyle(fontFamily: 'Courier New'),
                ),
                SizedBox(height: 8),
                Text('Last update on $lastUpdateTime'),
              ],
            ),
          );
        }
      },
    );
  }

  Future<String> _fetchData() async {
    try {
      final directory = Directory(gsPath);
      final fullList = directory.list(recursive: true);
      final gsList = await fullList.firstWhere(
        (file) => file.path.endsWith('/bin/gslist'),
      );
      final result = await Process.run(
        gsList.path,
        ['-cvl'],
        environment: {
          'GEMSTONE_GLOBAL_DIR': gsPath,
        },
      );
      return result.stdout;
    } catch (e) {
      return 'We are unable to find the gslist executable. Do you have a version of GemStone/S installed?';
    }
  }
}
