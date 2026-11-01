import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/naive_bayes.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class TopicScreen extends StatelessWidget {
  final int id;
  const TopicScreen(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(backgroundColor: bgColor, title: const Text('Detail Informasi')),
      body: LoadView(
        load: () => app.loadTopic(id),
        builder: (context, d, fromCache) {
          final status = d['status'] as String;
          final sources = d['sources'] as List;
          final att = (d['attachments'] as List).cast<String>();
          final reports = d['reports'] as List;
          final langs = (d['language_counts'] as Map).cast<String, dynamic>();
          final flagged = ['promosi', 'tekanan']
              .where((k) => ((langs[k] ?? 0) as num) > 0)
              .map((k) => '${langs[k]} laporan: ${languageLabels[k]}')
              .join(' · ');
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            if (fromCache) const InfoBanner('Menampilkan data tersimpan terakhir.'),
            Text(d['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final t in (d['tickers'] as List)) Pill('$t', const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
              for (final c in (d['source_categories'] as List)) Pill('$c', const Color(0xFFE5E9F0), const Color(0xFF475569)),
            ]),
            const SizedBox(height: 14),
            AppCard(
              color: status == 'terverifikasi' ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              border: status == 'terverifikasi' ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Status Verifikasi', style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 6),
                statusPill(status),
                const SizedBox(height: 6),
                Text(status == 'terverifikasi'
                    ? 'Ada sumber resmi yang terkait dengan informasi ini.'
                    : 'Pengumuman resmi terkait klaim ini belum ditemukan.'),
              ]),
            ),
            AppCard(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _Stat('${d['user_count']}', 'pengguna'),
                  _Stat('${d['minutes_span']}', 'menit'),
                  _Stat('${d['report_count']}', 'laporan'),
                ]),
                if (flagged.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(flagged, style: const TextStyle(color: muted, fontSize: 12), textAlign: TextAlign.center),
                ],
              ]),
            ),
            if (att.isNotEmpty) ...[
              const SectionTitle('Bukti Screenshot'),
              SizedBox(
                height: 110,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final u in att)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network('${ApiService.baseUrl}$u', width: 110, height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 110, color: const Color(0xFFCBD2DE))),
                      ),
                    ),
                ]),
              ),
            ],
            const SectionTitle('Penelusuran Sumber'),
            if (sources.isEmpty) const InfoBanner('Belum ada sumber resmi yang cocok.'),
            for (final s in sources)
              AppCard(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const Pill('Ditemukan', Color(0xFFDCFCE7), Color(0xFF166534)),
                ]),
              ),
            const SectionTitle('Laporan Pengguna'),
            for (final r in reports)
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${r['text']}'),
                  const SizedBox(height: 4),
                  Text('${r['source_category']} · ${languageLabels[r['language_label']] ?? ''}',
                      style: const TextStyle(color: muted, fontSize: 12)),
                ]),
              ),
            const SizedBox(height: 8),
            const Text('CrowdSense tidak menyatakan informasi benar atau salah, dan bukan rekomendasi beli atau jual.',
                textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          ]);
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String v, l;
  const _Stat(this.v, this.l);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(l, style: const TextStyle(color: muted, fontSize: 12)),
      ]);
}
