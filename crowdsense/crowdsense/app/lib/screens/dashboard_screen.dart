import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'create_report_screen.dart';
import 'stock_screen.dart';
import 'topic_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().refreshDashboard());
  }

  void _editWatchlist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Consumer<AppState>(
        builder: (_, st, __) => SafeArea(
          child: ListView(shrinkWrap: true, children: [
            const ListTile(title: Text('Atur Watchlist', style: TextStyle(fontWeight: FontWeight.w700))),
            for (final x in st.stocks)
              CheckboxListTile(
                value: st.watchlist.contains(x.code),
                title: Text(x.code),
                subtitle: Text(x.name),
                onChanged: (_) => st.toggleWatchlist(x.code),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final alerts = s.topAlerts;
    final trending = s.trending;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: s.refreshDashboard,
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 12, 22),
            decoration: const BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pantau isu saham', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                    Text('CrowdSense', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Atur watchlist',
                  onPressed: _editWatchlist,
                  icon: const Icon(Icons.tune, color: Colors.white),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Watchlist', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11)),
                for (final c in s.watchlist) Pill(c, const Color(0xFF1F4290), Colors.white),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (s.queue.items.isNotEmpty)
                InfoBanner('${s.queue.items.length} laporan menunggu dikirim. Dicoba ulang otomatis.',
                    bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
              if (s.dashboardFromCache) const InfoBanner('Koneksi lemah. Menampilkan data tersimpan terakhir.'),
              if (s.dashboardError != null && alerts.isEmpty && trending.isEmpty)
                InfoBanner(s.dashboardError!),
              if (s.dashboardLoading && alerts.isEmpty && trending.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              if (alerts.isNotEmpty) ...[
                const SectionTitle('Alert Prioritas'),
                for (final a in alerts) _AlertCard(a, s.watchlist.any(a.tickers.contains)),
              ],
              if (trending.isNotEmpty) ...[
                const SectionTitle('Sedang Ramai'),
                for (final t in trending) _TrendRow(t),
              ],
              if (!s.dashboardLoading && alerts.isEmpty && trending.isEmpty && s.dashboardError == null)
                const InfoBanner('Belum ada laporan. Jadilah yang pertama melaporkan.'),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReportScreen())),
            child: const Text('+ Buat Laporan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem a;
  final bool inWatchlist;
  const _AlertCard(this.a, this.inWatchlist);
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicScreen(a.topicId))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CodeAvatar(a.tickers.first),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${inWatchlist ? 'Di watchlist · ' : ''}${timeAgo(a.lastReportAt)} · ${a.reportCount} laporan',
                    style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            statusPill(a.status),
            Text('Relevansi ${(a.score * 100).round()}%', style: const TextStyle(color: muted, fontSize: 12)),
          ]),
        ]),
      );
}

class _TrendRow extends StatelessWidget {
  final Trending t;
  const _TrendRow(this.t);
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockScreen(t.code))),
        child: Row(children: [
          CodeAvatar(t.code),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.code, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${t.series.last} laporan terbaru', style: const TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
          Sparkline(t.series),
          const SizedBox(width: 10),
          trendPill(t.trend),
        ]),
      );
}
