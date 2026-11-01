import 'dart:math';
import 'package:flutter/material.dart';
import '../core/ewma.dart';
import '../models.dart';

const navy = Color(0xFF14306B);
const ink = Color(0xFF0F172A);
const bgColor = Color(0xFFF4F6FA);
const muted = Color(0xFF5B6678);
const lineColor = Color(0xFFE5E9F0);

class Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Pill(this.text, this.bg, this.fg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

Pill statusPill(String status) => switch (status) {
      'terverifikasi' => const Pill('Terverifikasi', Color(0xFFDCFCE7), Color(0xFF166534)),
      'tidak_ditemukan' => const Pill('Sumber tidak ditemukan', Color(0xFFE5E9F0), Color(0xFF475569)),
      _ => const Pill('Belum ada sumber resmi', Color(0xFFFEF3C7), Color(0xFF92400E)),
    };

Pill trendPill(Trend t) => switch (t) {
      Trend.turun || Trend.stabil => Pill(trendLabel(t), const Color(0xFFE5E9F0), const Color(0xFF475569)),
      _ => Pill(trendLabel(t), const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
    };

class CodeAvatar extends StatelessWidget {
  final String code;
  const CodeAvatar(this.code, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
        child: Text(code, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 10)),
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color, border;
  const AppCard({super.key, required this.child, this.onTap, this.color = Colors.white, this.border = lineColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(14), child: SizedBox(width: double.infinity, child: child)),
          ),
        ),
      );
}

class InfoBanner extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const InfoBanner(this.text, {super.key, this.bg = const Color(0xFFE5E9F0), this.fg = const Color(0xFF334155)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12, height: 1.4)),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ink)),
      );
}

class _LinePainter extends CustomPainter {
  final List<int> v;
  final Color color;
  final bool fill;
  _LinePainter(this.v, this.color, this.fill);
  @override
  void paint(Canvas c, Size s) {
    if (v.length < 2) return;
    final mx = max(1, v.reduce(max)).toDouble();
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(s.width * i / (v.length - 1), s.height - (v[i] / mx) * (s.height - 6) - 3)
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close();
      c.drawPath(area, Paint()..color = color.withAlpha(40));
    }
    c.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = fill ? 3 : 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.v != v;
}

class Sparkline extends StatelessWidget {
  final List<int> data;
  final double width, height;
  final bool fill;
  const Sparkline(this.data, {super.key, this.width = 56, this.height = 24, this.fill = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _LinePainter(data, const Color(0xFF3730A3), fill)),
      );
}

/// Memuat Future dengan state loading / error / retry.
class LoadView extends StatefulWidget {
  final Future<Cached<Map<String, dynamic>>> Function() load;
  final Widget Function(BuildContext, Map<String, dynamic>, bool fromCache) builder;
  const LoadView({super.key, required this.load, required this.builder});
  @override
  State<LoadView> createState() => _LoadViewState();
}

class _LoadViewState extends State<LoadView> {
  late Future<Cached<Map<String, dynamic>>> _f = widget.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<Cached<Map<String, dynamic>>>(
        future: _f,
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Tidak dapat memuat data.'),
                TextButton(onPressed: () => setState(() => _f = widget.load()), child: const Text('Coba lagi')),
              ]),
            );
          }
          return widget.builder(c, snap.data!.data, snap.data!.fromCache);
        },
      );
}

String formatBytes(int b) =>
    b >= 1048576 ? '${(b / 1048576).toStringAsFixed(1)} MB' : '${(b / 1024).round()} KB';

String timeAgo(DateTime t) {
  final m = DateTime.now().difference(t).inMinutes;
  if (m < 1) return 'baru saja';
  if (m < 60) return '$m menit lalu';
  if (m < 1440) return '${m ~/ 60} jam lalu';
  return '${m ~/ 1440} hari lalu';
}
