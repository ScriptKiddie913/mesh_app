import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mesh_service.dart';
import '../../services/storage_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Broadcast message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _send,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, _) {
                final items = storage.getMessages().where((m) => m.type == 'broadcast').toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                if (items.isEmpty) {
                  return const Center(child: Text('No broadcasts yet'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final m = items[index];
                    final dt = DateTime.fromMillisecondsSinceEpoch(m.timestamp);
                    return ListTile(
                      leading: const Icon(Icons.campaign),
                      title: Text(m.payload),
                      subtitle: Text('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final mesh = context.read<MeshService>();
    await mesh.sendBroadcast(content: text);
    if (!mounted) return;
    _controller.clear();
  }
}
