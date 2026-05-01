import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/file_transfer.dart';
import 'nearby_service.dart';

class FileTransferService {
  final Map<String, FileTransfer> _activeTransfers = {};

  Future<void> sendFile({
    required Uint8List fileBytes,
    required String fileName,
    required String targetPeerId,
    required NearbyService nearby,
  }) async {
    final transferId = const Uuid().v4();
    final totalChunks = (fileBytes.length / CHUNK_SIZE).ceil();

    await nearby.sendMessage(targetPeerId, {
      'type': 'file_header',
      'transferId': transferId,
      'fileName': fileName,
      'fileSize': fileBytes.length,
      'totalChunks': totalChunks,
    });

    for (int i = 0; i < totalChunks; i++) {
      final start = i * CHUNK_SIZE;
      final end = (start + CHUNK_SIZE).clamp(0, fileBytes.length);
      final chunk = fileBytes.sublist(start, end);

      await nearby.sendMessage(targetPeerId, {
        'type': 'file_chunk',
        'transferId': transferId,
        'chunkIndex': i,
        'data': base64Encode(chunk),
        'checksum': _simpleChecksum(chunk),
      });

      await Future.delayed(const Duration(milliseconds: 50)); 
    }
  }

  void receiveChunk(Map<String, dynamic> data) {
    final tid = data['transferId'] as String;
    final idx = data['chunkIndex'] as int;
    final bytes = base64Decode(data['data'] as String);

    final transfer = _activeTransfers[tid];
    if (transfer == null) return;

    if (!transfer.chunks.containsKey(idx)) {
      transfer.chunks[idx] = bytes;
      transfer.receivedChunks++;
    }

    if (transfer.isComplete) {
      // Assemble and handle
    }
  }

  Uint8List assembleFile(FileTransfer transfer) {
    final builder = BytesBuilder();
    for (int i = 0; i < transfer.totalChunks; i++) {
      builder.add(transfer.chunks[i]!);
    }
    return builder.toBytes();
  }

  int _simpleChecksum(Uint8List data) {
    return data.fold<int>(0, (sum, byte) => sum + byte);
  }
  
  void registerTransfer(FileTransfer transfer) {
    _activeTransfers[transfer.transferId] = transfer;
  }
}
