import 'package:flutter/material.dart';
import 'package:permission_plus_apple/permission_plus_apple.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = PermissionPlusApple();
  String _status = 'Tap a permission to check its status';

  Future<void> _requestPermission(PermissionType type) async {
    try {
      final status = await _plugin.requestPermission(type);
      setState(() {
        _status = '${type.name}: ${status.name}';
      });
    } catch (e) {
      setState(() {
        _status = '${type.name}: Error - $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission Plus Apple Example')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status, style: const TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final type in PermissionType.values)
                    ListTile(
                      title: Text(type.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _requestPermission(type),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
