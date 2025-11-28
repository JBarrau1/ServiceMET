class DecimalHelper {
  static double getDecimalForValue(double value, Map<String, double> dValues) {
    // Extract values with defaults
    final pmax1 = dValues['pmax1'] ?? 0.0;
    final pmax2 = dValues['pmax2'] ?? 0.0;
    final pmax3 = dValues['pmax3'] ?? 0.0;

    final d1 = dValues['d1'] ?? 0.1;
    final d2 = dValues['d2'] ?? 0.1;
    final d3 = dValues['d3'] ?? 0.1;

    // Create a list of ranges sorted by pmax (ascending)
    // We only care about non-zero pmax values to define ranges
    final ranges = [
      {'pmax': pmax3, 'd': d3},
      {'pmax': pmax2, 'd': d2},
      {'pmax': pmax1, 'd': d1},
    ];

    // Filter out entries where pmax is 0 (unused ranges)
    // But keep at least one if all are 0 (fallback to d1)
    final activeRanges =
        ranges.where((r) => (r['pmax'] as double) > 0).toList();

    // Sort by pmax ascending just in case
    activeRanges
        .sort((a, b) => (a['pmax'] as double).compareTo(b['pmax'] as double));

    if (activeRanges.isEmpty) {
      return d1; // Default fallback
    }

    // Find the first range where value <= pmax
    for (final range in activeRanges) {
      if (value <= (range['pmax'] as double)) {
        return range['d'] as double;
      }
    }

    // If value is greater than all pmax, use the d of the largest pmax
    return activeRanges.last['d'] as double;
  }

  static int getDecimalPlaces(double step) {
    if (step <= 0) return 0;
    final s = step.toString();
    if (!s.contains('.')) return 0;
    final frac = s.split('.').last.replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? 0 : frac.length;
  }
}
