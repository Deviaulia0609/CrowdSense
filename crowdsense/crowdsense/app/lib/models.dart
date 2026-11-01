import 'core/ewma.dart';

class StockInfo {
  final String code, name;
  StockInfo(this.code, this.name);
  factory StockInfo.fromJson(Map<String, dynamic> j) =>
      StockInfo(j['code'] as String, j['name'] as String);
  Map<String, dynamic> toJson() => {'code': code, 'name': name};
}

class Trending {
  final String code, name;
  final List<int> series;
  final int total;
  final Trend trend;
  Trending(this.code, this.name, this.series, this.total, this.trend);
}

class AlertItem {
  final int topicId, reportCount, sourceCount;
  final String title, status;
  final List<String> tickers;
  final DateTime lastReportAt;
  double score = 0;
  AlertItem({
    required this.topicId,
    required this.title,
    required this.tickers,
    required this.reportCount,
    required this.sourceCount,
    required this.status,
    required this.lastReportAt,
  });
  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        topicId: (j['topic_id'] as num).toInt(),
        title: j['title'] as String,
        tickers: (j['tickers'] as List).cast<String>(),
        reportCount: (j['report_count'] as num).toInt(),
        sourceCount: (j['source_count'] as num).toInt(),
        status: j['status'] as String,
        lastReportAt: DateTime.parse(j['last_report_at'] as String).toLocal(),
      );
}

class PendingReport {
  final String id, text, sourceCategory, languageLabel, simhash;
  final List<String> tickers;
  final String? imagePath;
  final DateTime createdAt;
  PendingReport({
    required this.id,
    required this.text,
    required this.tickers,
    required this.sourceCategory,
    required this.languageLabel,
    required this.simhash,
    required this.createdAt,
    this.imagePath,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'tickers': tickers,
        'source_category': sourceCategory,
        'language_label': languageLabel,
        'simhash': simhash,
        'image_path': imagePath,
        'created_at': createdAt.toIso8601String(),
      };
  factory PendingReport.fromJson(Map<String, dynamic> j) => PendingReport(
        id: j['id'] as String,
        text: j['text'] as String,
        tickers: (j['tickers'] as List).cast<String>(),
        sourceCategory: j['source_category'] as String,
        languageLabel: j['language_label'] as String,
        simhash: j['simhash'] as String,
        imagePath: j['image_path'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class Cached<T> {
  final T data;
  final bool fromCache;
  const Cached(this.data, this.fromCache);
}
