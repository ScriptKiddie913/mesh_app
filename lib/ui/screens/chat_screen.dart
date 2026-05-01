import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/peer.dart';
import '../../models/message.dart';
import '../../models/enums.dart';
import '../../services/mesh_service.dart';
import '../../services/storage_service.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';
import '../widgets/mesh_widgets.dart';

class ChatScreen extends StatefulWidget {
  final Peer peer;
  const ChatScreen({super.key, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  MessagePriority _priority = MessagePriority.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeshTheme.bg0,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: MeshTheme.bg1,
            border: Border(bottom: BorderSide(color: MeshTheme.accent, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: MeshTheme.textPri),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.peer.username.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: MeshTheme.fontMono,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      StatusBadge(
                        label: widget.peer.connected ? 'SECURE LINK' : 'OFFLINE',
                        color: widget.peer.connected ? MeshTheme.accentG : MeshTheme.textDim,
                        blink: widget.peer.connected,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.security, color: MeshTheme.accent, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, child) {
                final messages = storage.getMessages(peerId: widget.peer.id);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(MeshTheme.s4),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == storage.getDeviceId();
                    return _ChatBubble(msg: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(MeshTheme.s4),
      decoration: const BoxDecoration(
        color: MeshTheme.bg1,
        border: Border(top: BorderSide(color: MeshTheme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: MeshTheme.accent),
            onPressed: _sendImage,
          ),
          GestureDetector(
            onTap: _showPriorityPicker,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: _colorFor(_priority), width: 1),
              ),
              child: Icon(Icons.flag, color: _colorFor(_priority), size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: MeshTheme.textPri),
              decoration: const InputDecoration(
                hintText: 'SECURE UPLINK...',
                hintStyle: TextStyle(color: MeshTheme.textDim, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          TacticalButton(
            label: 'SEND',
            onTap: _sendMessage,
            icon: Icons.send,
            filled: true,
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MeshTheme.bg1,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UPLINK PRIORITY', style: TextStyle(fontFamily: MeshTheme.fontMono, letterSpacing: 2)),
            const SizedBox(height: 16),
            ...MessagePriority.values.map((p) => ListTile(
              onTap: () {
                setState(() => _priority = p);
                Navigator.pop(context);
              },
              leading: Container(width: 12, height: 12, color: _colorFor(p)),
              title: Text(p.name.toUpperCase(), style: TextStyle(fontFamily: MeshTheme.fontMono, color: _colorFor(p))),
            )),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<MeshService>().sendMessage(
      receiverId: widget.peer.id,
      type: 'text',
      content: text,
      priority: _priority,
    );
    
    _messageController.clear();
    setState(() => _priority = MessagePriority.normal);
  }

  Future<void> _sendImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress for mesh transmission
    );
    
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (mounted) {
      context.read<MeshService>().sendMessage(
        receiverId: widget.peer.id,
        type: 'image',
        content: base64Image,
        priority: _priority,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Color _colorFor(MessagePriority p) => switch (p) {
    MessagePriority.critical  => MeshTheme.accentR,
    MessagePriority.important => MeshTheme.accentY,
    _                         => MeshTheme.accent,
  };
}

class _ChatBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;

  const _ChatBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(msg.priorityIndex);
    final isImage = msg.type == 'image';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? MeshTheme.accent.withOpacity(0.08) : MeshTheme.bg2,
          border: Border(
            left: BorderSide(color: isMe ? MeshTheme.accent : MeshTheme.textSec, width: 2),
            right: msg.priorityIndex > 0 ? BorderSide(color: priorityColor, width: 2) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isImage)
              _buildImageContent()
            else
              Text(msg.payload, style: const TextStyle(fontSize: 14, color: MeshTheme.textPri)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp)),
                  style: const TextStyle(fontFamily: MeshTheme.fontMono, fontSize: 9, color: MeshTheme.textDim),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 10, color: msg.delivered ? MeshTheme.accentG : MeshTheme.textDim),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    try {
      return Image.memory(
        base64Decode(msg.payload),
        errorBuilder: (_, __, ___) => const Text('[IMAGE DATA CORRUPTED]', style: TextStyle(color: MeshTheme.accentR, fontSize: 12)),
      );
    } catch (_) {
      return const Text('[IMAGE DECRYPTION FAILED]', style: TextStyle(color: MeshTheme.accentR, fontSize: 12));
    }
  }

  Color _priorityColor(int index) => switch (index) {
    2 => MeshTheme.accentR,
    1 => MeshTheme.accentY,
    _ => Colors.transparent,
  };
}
