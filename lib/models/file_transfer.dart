import 'dart:typed_data';
import 'enums.dart';

const int CHUNK_SIZE = 32 * 1024; // 32KB per chunk

class FileTransfer {
  final String transferId;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String targetPeerId;
  final String senderId;
  TransferState state;
  int receivedChunks;
  final Map<int, Uint8List> chunks; // index -> data

  double get progress => totalChunks == 0 ? 0 : receivedChunks / totalChunks;
  bool get isComplete => totalChunks > 0 && receivedChunks == totalChunks;

  FileTransfer({
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.targetPeerId,
    required this.senderId,
    this.state = TransferState.pending,
    this.receivedChunks = 0,
    Map<int, Uint8List>? chunks,
  }) : chunks = chunks ?? {};
}
