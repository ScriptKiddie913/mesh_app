import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../services/mesh_service.dart';
import '../../services/storage_service.dart';
import '../../models/peer.dart';


class ChatScreen extends StatefulWidget {
  final Peer peer;
  const ChatScreen({super.key, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peer.username),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${widget.peer.signalStrength} dBm'),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, child) {
                final messages = storage.getMessages(peerId: widget.peer.id)
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[messages.length - 1 - i];
                    final isMe = msg.senderId == storage.getDeviceId();
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange : Colors.grey[800],
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: msg.type == 'image'
                          ? Image.file(io.File(msg.payload), height: 200)
                          : Text(msg.payload),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    final meshService = context.read<MeshService>();
    await meshService.sendMessage(
      receiverId: widget.peer.id,
      type: 'text',
      content: text,
    );
    if (!mounted) return;
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Compress
    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      '${image.path}.jpg',
      quality: 70,
    );

    if (!mounted) return;
    final meshService = context.read<MeshService>();
    await meshService.sendMessage(
      receiverId: widget.peer.id,
      type: 'image',
      content: compressed!.path,
    );
  }
}

