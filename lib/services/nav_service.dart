import 'package:collection/collection.dart';
import '../models/peer.dart';

class NavService {
  Map<String, List<_NavEdge>> buildGraph(List<Peer> peers) {
    final graph = <String, List<_NavEdge>>{};
    for (final peer in peers) {
      graph[peer.id] ??= [];
      for (final other in peers) {
        if (peer.id == other.id) continue;
        final weight = _rssiToDistance(peer.signalStrength);
        graph[peer.id]!.add(_NavEdge(other.id, weight));
      }
    }
    return graph;
  }

  List<String> findPath(String fromId, String toId, Map<String, List<_NavEdge>> graph) {
    final dist = <String, double>{};
    final prev = <String, String?>{};
    final queue = PriorityQueue<_QEntry>(
      (a, b) => a.dist.compareTo(b.dist),
    );

    dist[fromId] = 0;
    queue.add(_QEntry(fromId, 0));

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      if (cur.id == toId) break;
      for (final edge in graph[cur.id] ?? []) {
        final newDist = (dist[cur.id] ?? double.infinity) + edge.weight;
        if (newDist < (dist[edge.to] ?? double.infinity)) {
          dist[edge.to] = newDist;
          prev[edge.to] = cur.id;
          queue.add(_QEntry(edge.to, newDist));
        }
      }
    }
    
    final path = <String>[];
    if (prev[toId] == null && fromId != toId) return [];
    
    var cur = toId;
    while (cur != fromId) {
      path.insert(0, cur);
      final p = prev[cur];
      if (p == null) break;
      cur = p;
    }
    return [fromId, ...path];
  }

  double _rssiToDistance(double rssi) {
    return rssi.abs() / 10.0;
  }
}

class _NavEdge { final String to; final double weight; _NavEdge(this.to, this.weight); }
class _QEntry  { final String id; final double dist;  _QEntry(this.id, this.dist);    }
