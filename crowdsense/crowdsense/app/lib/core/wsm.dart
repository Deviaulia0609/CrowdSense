/// Proses 6: Weighted Sum Model untuk Personal Relevance Score.
const relevanceWeights = <String, double>{
  'watchlist': 0.4,
  'freshness': 0.2,
  'crowd': 0.2,
  'diversity': 0.1,
  'preference': 0.1,
};

class WeightedSum {
  final Map<String, double> weights;
  const WeightedSum(this.weights);
  double score(Map<String, double> x) =>
      weights.entries.fold(0.0, (s, e) => s + e.value * (x[e.key] ?? 0));
}
