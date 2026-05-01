import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../models/peer.dart';

// ─── TACTICAL CARD ───────────────────────────────────────────────
class TacticalCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? bgColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final String? tag; // corner tag like "NODE" or "MSG"

  const TacticalCard({
    super.key,
    required this.child,
    this.borderColor,
    this.bgColor,
    this.padding = const EdgeInsets.all(MeshTheme.s4),
    this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? MeshTheme.border;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _CornerTagPainter(color: bc, tag: tag),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? MeshTheme.bg1,
            border: Border.all(color: bc, width: MeshTheme.borderNorm),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CornerTagPainter extends CustomPainter {
  final Color color;
  final String? tag;
  _CornerTagPainter({required this.color, this.tag});

  @override
  void paint(Canvas canvas, Size size) {
    if (tag == null) return;
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(60, 0)
      ..lineTo(60, 2)
      ..lineTo(2, 2)
      ..lineTo(2, 18)
      ..lineTo(0, 18)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── STATUS BADGE ────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool blink;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.blink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BlinkDot(color: color, blink: blink),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: MeshTheme.fontMono,
            fontSize: 10,
            color: color,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BlinkDot extends StatefulWidget {
  final Color color;
  final bool blink;
  const _BlinkDot({required this.color, required this.blink});

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.blink) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        color: widget.blink
            ? widget.color.withOpacity(_ctrl.value)
            : widget.color,
      ),
    );
  }
}

// ─── TACTICAL BUTTON ─────────────────────────────────────────────
class TacticalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final bool filled;

  const TacticalButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? MeshTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: MeshTheme.s4, vertical: MeshTheme.s3),
        decoration: BoxDecoration(
          color: filled ? c.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: c, width: MeshTheme.borderNorm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: c),
              const SizedBox(width: MeshTheme.s2),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: MeshTheme.fontMono,
                fontSize: 11,
                color: c,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DIVIDER WITH LABEL ──────────────────────────────────────────
class SectionDivider extends StatelessWidget {
  final String label;
  const SectionDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshTheme.s3),
      child: Row(
        children: [
          Container(width: 2, height: 12, color: MeshTheme.accent),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: MeshTheme.fontMono,
              fontSize: 10,
              color: MeshTheme.textSec,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: MeshTheme.border),
          ),
        ],
      ),
    );
  }
}

// ─── PEER LIST TILE ──────────────────────────────────────────────
class PeerTile extends StatelessWidget {
  final Peer peer;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;

  const PeerTile({
    super.key,
    required this.peer,
    required this.index,
    this.onTap,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = peer.connected;
    final borderColor = isConnected ? MeshTheme.accentG : MeshTheme.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: MeshTheme.s4, vertical: MeshTheme.s1),
        decoration: BoxDecoration(
          color: MeshTheme.bg1,
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
            top: BorderSide(color: MeshTheme.border),
            right: BorderSide(color: MeshTheme.border),
            bottom: BorderSide(color: MeshTheme.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MeshTheme.s4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${index.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: MeshTheme.fontMono,
                    fontSize: 11,
                    color: MeshTheme.textDim,
                  ),
                ),
              ),
              const SizedBox(width: MeshTheme.s3),
              Container(
                width: 40,
                height: 40,
                color: isConnected
                    ? MeshTheme.accentG.withOpacity(0.1)
                    : MeshTheme.bg2,
                alignment: Alignment.center,
                child: Text(
                  peer.username.isNotEmpty
                      ? peer.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: MeshTheme.fontMono,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? MeshTheme.accentG : MeshTheme.textSec,
                  ),
                ),
              ),
              const SizedBox(width: MeshTheme.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.username.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: MeshTheme.fontMono,
                        fontSize: 13,
                        color: MeshTheme.textPri,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        StatusBadge(
                          label: isConnected ? 'linked' : 'detected',
                          color: isConnected ? MeshTheme.accentG : MeshTheme.textSec,
                          blink: isConnected,
                        ),
                        const SizedBox(width: 8),
                        _SignalBars(strength: peer.signalStrength),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isConnected)
                TacticalButton(
                  label: 'Link',
                  color: MeshTheme.accent,
                  icon: Icons.link,
                  onTap: onConnect,
                )
              else
                const Icon(Icons.chevron_right,
                    color: MeshTheme.accentG, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final double strength; 
  const _SignalBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    final bars = strength > -50
        ? 4
        : strength > -65
            ? 3
            : strength > -80
                ? 2
                : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 3,
          height: 4.0 + (i * 2.5),
          margin: const EdgeInsets.only(right: 1.5),
          color: active ? MeshTheme.accent : MeshTheme.textDim,
        );
      }),
    );
  }
}

// ─── TACTICAL OVERLAY ─────────────────────────────────────────────
class TacticalOverlay extends StatelessWidget {
  final Widget child;
  const TacticalOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MeshTheme.scanline,
                  Colors.transparent,
                  MeshTheme.scanline,
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _GridPainter(),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MeshTheme.grid
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── PERMISSION DIALOG ───────────────────────────────────────────
class PermissionDialog extends StatelessWidget {
  final VoidCallback onGrant;
  const PermissionDialog({super.key, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      borderColor: MeshTheme.accent,
      tag: 'SYSTEM',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CRITICAL: SYSTEM PERMISSIONS REQUIRED',
            style: TextStyle(fontFamily: MeshTheme.fontMono, color: MeshTheme.accent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'SoTaNik_AI requires Location, Bluetooth, and Nearby scanning to establish mesh uplink. Failure to grant will result in terminal isolation.',
            style: TextStyle(fontSize: 12, color: MeshTheme.textSec),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TacticalButton(
            label: 'AUTHORIZE ACCESS',
            onTap: onGrant,
            filled: true,
          ),
        ],
      ),
    );
  }
}
