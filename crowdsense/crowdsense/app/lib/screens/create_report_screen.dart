import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/naive_bayes.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class CreateReportScreen extends StatefulWidget {
  final String? initialTicker;
  const CreateReportScreen({super.key, this.initialTicker});
  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _c = TextEditingController();
  String _source = 'medsos';
  String? _img;
  int? _orig, _comp;
  bool _busy = false;
  static const _sources = {
    'medsos': 'Medsos',
    'forum': 'Forum',
    'grup_chat': 'Grup chat',
    'lainnya': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTicker != null) _c.text = '${widget.initialTicker} ';
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final app = context.read<AppState>();
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final r = await app.images.compress(x.path);
      setState(() {
        _img = r.path;
        _orig = r.original;
        _comp = r.compressed;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _send(List<String> tickers, bool dup) async {
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    if (dup) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Laporan mirip'),
          content: const Text('Kamu sudah pernah mengirim laporan yang hampir sama. Tetap kirim?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Tetap kirim')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    await app.submit(text: _c.text, tickers: tickers, sourceCategory: _source, imagePath: _img);
    nav.pop();
    msg.showSnackBar(const SnackBar(content: Text('Laporan masuk antrean dan dikirim otomatis.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final text = _c.text;
    final tickers = app.detectTickers(text);
    final long = text.trim().length >= 15;
    final dup = long && app.isDuplicate(text);
    final label = text.trim().length >= 10 ? app.classify(text) : 'netral';
    final pressure = label == 'promosi' || label == 'tekanan';
    return Scaffold(
      appBar: AppBar(backgroundColor: bgColor, title: const Text('Buat Laporan')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
        TextField(
          controller: _c,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tulis informasi yang kamu temukan, mis. "Saya melihat pembahasan BBCA meningkat di grup."',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Kode saham terdeteksi:', style: TextStyle(color: muted, fontSize: 12)),
          if (tickers.isEmpty) const Text('belum ada', style: TextStyle(color: muted, fontSize: 12)),
          for (final t in tickers) Pill(t, const Color(0xFFE0E7FF), navy),
        ]),
        const SectionTitle('Kategori Sumber'),
        Wrap(spacing: 8, children: [
          for (final e in _sources.entries)
            ChoiceChip(label: Text(e.value), selected: _source == e.key, onSelected: (_) => setState(() => _source = e.key)),
        ]),
        const SectionTitle('Screenshot'),
        if (_img == null)
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Lampirkan screenshot'),
          )
        else
          AppCard(
            child: Row(children: [
              const Icon(Icons.image, color: muted),
              const SizedBox(width: 12),
              Expanded(child: Text('${formatBytes(_orig!)} → ${formatBytes(_comp!)}', style: const TextStyle(fontWeight: FontWeight.w600))),
              const Pill('Terkompresi', Color(0xFFDCFCE7), Color(0xFF166534)),
            ]),
          ),
        const SizedBox(height: 10),
        if (dup)
          const InfoBanner('Mirip laporan sebelumnya. Kamu sudah pernah mengirim laporan yang hampir sama.',
              bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E)),
        if (pressure)
          InfoBanner('Terdeteksi: ${languageLabels[label]}. Pertimbangkan kata yang lebih netral.',
              bg: const Color(0xFFE0E7FF), fg: const Color(0xFF3730A3)),
        const InfoBanner('Jika tidak ada koneksi, laporan disimpan terenkripsi dan dikirim ulang otomatis.'),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (_busy || tickers.isEmpty || text.trim().length < 5) ? null : () => _send(tickers, dup),
            child: const Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
