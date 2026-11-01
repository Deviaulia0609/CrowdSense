import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ewma.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'create_report_screen.dart';
import 'topic_screen.dart';

class StockScreen extends StatelessWidget {
  final String code;
  const StockScreen(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(backgroundColor: bgColor, title: Text(code, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: LoadView(
        load: () => app.loadStock(code),
        builder: (context, d, fromCache) {
          final series = (d['series'] as List).map((e) => (e as num).toInt()).toList();
          final topics = d['topics'] as List;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            if (fromCache) const InfoBanner('Menampilkan data tersimpan terakhir.'),
            Text(d['name'] as String, style: const TextStyle(color: muted)),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Aktivitas Pembahasan', style: TextStyle(fontWeight: FontWeight.w700)),
                  trendPill(Ewma.classify(series)),
                ]),
                const SizedBox(height: 4),
                Text('${series.last} laporan dalam 2 menit terakhir', style: const TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 10),
                Sparkline(series, width: double.infinity, height: 110, fill: true),
                const SizedBox(height: 4),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('10 mnt', style: TextStyle(color: muted, fontSize: 11)),
                  Text('8', style: TextStyle(color: muted, fontSize: 11)),
                  Text('6', style: TextStyle(color: muted, fontSize: 11)),
                  Text('4', style: TextStyle(color: muted, fontSize: 11)),
                  Text('2 mnt', style: TextStyle(color: muted, fontSize: 11)),
                ]),
              ]),
            ),
            AppCard(
              color: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Status Verifikasi', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                statusPill(d['status'] as String),
              ]),
            ),
            const SectionTitle('Laporan Terbaru'),
            if (topics.isEmpty) const InfoBanner('Belum ada laporan untuk saham ini.'),
            for (final t in topics)
              AppCard(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => TopicScreen((t['id'] as num).toInt()))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${t['report_count']} laporan · ${t['source_count']} jenis sumber',
                        style: const TextStyle(color: muted, fontSize: 12)),
                    statusPill(t['status'] as String),
                  ]),
                ]),
              ),
            const Text('Menunjukkan aktivitas pembahasan, bukan rekomendasi beli atau jual.',
                textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          ]);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(color: navy, width: 1.5),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => CreateReportScreen(initialTicker: code))),
            child: Text('+ Laporan untuk $code', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
