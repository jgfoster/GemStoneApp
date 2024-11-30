import 'package:flutter/material.dart';
import 'package:gemstoneapp/version.dart';

class NewDatabaseForm extends StatefulWidget {
  const NewDatabaseForm({super.key});

  @override
  NewDatabaseFormState createState() => NewDatabaseFormState();
}

class NewDatabaseFormState extends State<NewDatabaseForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVersion;
  String? _selectedBaseImage;
  String? _stoneName;
  String? _ldiName;

  final List<String> _versions = ['Version 1', 'Version 2', 'Version 3'];
  final List<String> _baseImages = ['Image 1', 'Image 2', 'Image 3'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Version'),
              value: _selectedVersion,
              onChanged: (newValue) {
                setState(() {
                  _selectedVersion = newValue;
                });
              },
              items: _versions.map((version) {
                return DropdownMenuItem(
                  value: version,
                  child: Text(version),
                );
              }).toList(),
              validator: (value) =>
                  value == null ? 'Please select a version' : null,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Base Image'),
              value: _selectedBaseImage,
              onChanged: (newValue) {
                setState(() {
                  _selectedBaseImage = newValue;
                });
              },
              items: _baseImages.map((image) {
                return DropdownMenuItem(
                  value: image,
                  child: Text(image),
                );
              }).toList(),
              validator: (value) =>
                  value == null ? 'Please select a base image' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Stone Name'),
              onChanged: (value) {
                setState(() {
                  _stoneName = value;
                });
              },
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a stone name';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'LDI Name'),
              onChanged: (value) {
                setState(() {
                  _ldiName = value;
                });
              },
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter an LDI name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Process data
                  print('Version: $_selectedVersion');
                  print('Base Image: $_selectedBaseImage');
                  print('Stone Name: $_stoneName');
                  print('LDI Name: $_ldiName');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
