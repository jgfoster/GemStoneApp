// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:gemstoneapp/domain/database.dart';
import 'package:gemstoneapp/domain/version.dart';

class NewDatabaseForm extends StatefulWidget {
  const NewDatabaseForm({super.key});

  @override
  NewDatabaseFormState createState() => NewDatabaseFormState();
}

class NewDatabaseFormState extends State<NewDatabaseForm> {
  final _formKey = GlobalKey<FormState>();
  late Database _database;

  DropdownButtonFormField<String> baseImageField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Base Image'),
      initialValue: _database.baseExtent,
      onChanged: (newValue) {
        setState(() {
          // _selectedBaseImage = newValue;
        });
      },
      items: _database.version.extents.map((image) {
        return DropdownMenuItem(
          value: image,
          child: Text(image),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a base image' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New GemStone Database'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: newDatabaseForm(context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _database = Database(
      version: Version.versionList[0],
      stoneName: 'gs64stone',
      ldiName: 'gs64ldi',
    );
  }

  TextFormField netLdiNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'NetLDI Name'),
      initialValue: _database.ldiName,
      onChanged: (value) {
        setState(() {
          _database.ldiName = value;
        });
      },
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter an LDI name';
        }
        return null;
      },
    );
  }

  Form newDatabaseForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          versionField(),
          baseImageField(),
          stoneNameField(),
          netLdiNameField(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _database.createDatabase();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  TextFormField stoneNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Stone Name'),
      initialValue: _database.stoneName,
      onChanged: (value) {
        setState(() {
          _database.stoneName = value;
        });
      },
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter a stone name';
        }
        return null;
      },
    );
  }

  DropdownButtonFormField<Version> versionField() {
    return DropdownButtonFormField<Version>(
      decoration: const InputDecoration(labelText: 'Version'),
      initialValue: _database.version,
      onChanged: (newValue) {
        setState(() {
          _database.version = newValue!;
        });
      },
      items: Version.installedVersions().map((version) {
        return DropdownMenuItem<Version>(
          value: version,
          child: Text(version.name),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a version' : null,
    );
  }
}
