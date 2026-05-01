import 'package:flutter/material.dart';
import '../models/identity.dart';
import '../utils/theme.dart';

class IdentityService {
  int calculateTrustScore(NodeIdentity identity) {
    int score = 0;
    
    final daysSinceFirst = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(identity.firstSeen))
        .inDays;
    score += (daysSinceFirst * 2).clamp(0, 20);
    
    score += (identity.messagesRelayed / 10).clamp(0, 30).toInt();
    
    score += (identity.endorsedBy.length * 10).clamp(0, 30);
    
    if (identity.isVerified) score += 20;
    return score.clamp(0, 100);
  }

  static Color roleColor(String role) => switch (role) {
    'leader'   => MeshTheme.accentY,
    'relay'    => MeshTheme.accentG,
    'verified' => MeshTheme.accent,
    _          => MeshTheme.textSec,
  };
}
