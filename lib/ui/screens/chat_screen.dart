import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/mesh_service.dart';
import '../../services/crypto_service.dart';
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.peer.username.toUpperCase(),
              style: const TextStyle(letterSpacing: 1.5, fontSize: 16),
            ),
            Text(
              widget.peer.connected ? 'LINK SECURE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.0,
                color: widget.peer.connected ? const Color(0xFF00D1FF) : const Color(0xFF8892B0),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF00D1FF).withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
        actions: [
          Icon(
            widget.peer.connected ? Icons.satellite_alt : Icons.satellite_alt_outlined,
            size: 16,
            color: widget.peer.connected ? const Color(0xFF00D1FF) : const Color(0xFF8892B0),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Connection warning
          if (!widget.peer.connected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFFFF4D4F).withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D4F), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UPLINK SEVERED. MESSAGES QUEUED FOR TRANSMISSION.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFF4D4F),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Message list
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, child) {
                final messages = storage
                    .getMessages(peerId: widget.peer.id)
                    .where((m) => m.type != 'marker')
                    .toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64,
                            color: const Color(0xFF3A86FF).withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'NO COMMS LOGGED',
                          style: TextStyle(
                            color: Color(0xFF8892B0),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[messages.length - 1 - i];
                    final isMe = msg.senderId == storage.getDeviceId();
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? const Color(0xFF3A86FF).withValues(alpha: 0.15) 
                              : const Color(0xFF112240),
                          border: Border.all(
                            color: isMe
                                ? const Color(0xFF00D1FF).withValues(alpha: 0.5)
                                : const Color(0xFF3A86FF).withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 2),
                            bottomRight: Radius.circular(isMe ? 2 : 12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (msg.type == 'image')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _decodeImageBytes(msg.payload, storage),
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 200,
                                    height: 120,
                                    alignment: Alignment.center,
                                    color: const Color(0xFF0A192F),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Color(0xFFFF4D4F),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                _displayPayload(msg.payload, storage),
                                style: const TextStyle(fontSize: 14, color: Color(0xFFE6F1FF)),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(msg.timestamp),
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.0,
                                      color: const Color(0xFF8892B0).withValues(alpha: 0.8)),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.delivered
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 12,
                                    color: msg.delivered
                                        ? const Color(0xFF00D1FF)
                                        : const Color(0xFF8892B0),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              border: Border(
                  top: BorderSide(color: const Color(0xFF3A86FF).withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Color(0xFF3A86FF)),
                    onPressed: _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'TYPE MESSAGE...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8892B0),
                          letterSpacing: 1.0,
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0A192F),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D1FF).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF3A86FF),
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _sendText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (!mounted) return;
    final meshService = context.read<MeshService>();
    await meshService.sendMessage(
      receiverId: widget.peer.id,
      type: 'text',
      content: text,
    );
  }

  Future<void> _sendImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 50,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final meshService = context.read<MeshService>();
      await meshService.sendMessage(
        receiverId: widget.peer.id,
        type: 'image',
        content: base64Image,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  String _displayPayload(String payload, StorageService storage) {
    return _tryDecryptPayload(payload, storage);
  }

  Uint8List _decodeImageBytes(String payload, StorageService storage) {
    final decodedPayload = _tryDecryptPayload(payload, storage);
    try {
      return base64Decode(decodedPayload);
    } catch (_) {
      return Uint8List(0);
    }
  }

  String _tryDecryptPayload(String payload, StorageService storage) {
    if (!_looksEncrypted(payload)) {
      return payload;
    }

    final keyPair = storage.getKeyPair();
    if (keyPair == null) {
      return payload;
    }

    return CryptoService.decryptPayload(
      encryptedPayloadB64: payload,
      privateKey: keyPair.privateKey,
    );
  }

  bool _looksEncrypted(String payload) {
    try {
      final decoded = utf8.decode(base64Decode(payload));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> && json['encrypted'] == true;
    } catch (_) {
      return false;
    }
  }
}
