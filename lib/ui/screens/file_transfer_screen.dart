import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';

class FileTransferScreen extends StatelessWidget {
  const FileTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Transfers')),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final files = storage.getMessages().where((m) => m.type == 'image').toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (files.isEmpty) {
            return const Center(child: Text('No file transfers yet'));
          }

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final item = files[index];
              final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
              return ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text('Image ${index + 1}'),
                subtitle: Text('${item.payload}\n${dt.toLocal()}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
