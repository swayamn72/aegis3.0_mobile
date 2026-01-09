import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';

final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService(ref.read(loggerProvider));
});

/// Service for monitoring app performance and tracking slow operations
class PerformanceService {
  final Logger logger;
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _operationDurations = {};

  PerformanceService(this.logger);

  /// Start tracking an operation
  void startTrace(String name) {
    _startTimes[name] = DateTime.now();
    logger.d('⏱️ Started: $name');
  }

  /// Stop tracking an operation and log duration
  void stopTrace(String name) {
    final start = _startTimes[name];
    if (start == null) {
      logger.w('⚠️ Tried to stop trace "$name" that was never started');
      return;
    }

    final duration = DateTime.now().difference(start);
    final durationMs = duration.inMilliseconds;

    // Store duration for analytics
    _operationDurations.putIfAbsent(name, () => []);
    _operationDurations[name]!.add(durationMs);

    // Keep only last 10 measurements
    if (_operationDurations[name]!.length > 10) {
      _operationDurations[name]!.removeAt(0);
    }

    // Log performance
    if (durationMs < 100) {
      logger.d('⚡ $name: ${durationMs}ms (fast)');
    } else if (durationMs < 1000) {
      logger.i('⏱️ $name: ${durationMs}ms');
    } else if (durationMs < 3000) {
      logger.w('⚠️ $name: ${durationMs}ms (slow)');
    } else {
      logger.e('🐌 $name: ${durationMs}ms (very slow!)');
    }

    _startTimes.remove(name);
  }

  /// Wrap an async operation with performance tracking
  Future<T> trace<T>(String name, Future<T> Function() operation) async {
    startTrace(name);
    try {
      return await operation();
    } finally {
      stopTrace(name);
    }
  }

  /// Wrap a sync operation with performance tracking
  T traceSync<T>(String name, T Function() operation) {
    startTrace(name);
    try {
      return operation();
    } finally {
      stopTrace(name);
    }
  }

  /// Get average duration for an operation
  double? getAverageDuration(String name) {
    final durations = _operationDurations[name];
    if (durations == null || durations.isEmpty) return null;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  /// Get statistics for an operation
  Map<String, dynamic>? getStats(String name) {
    final durations = _operationDurations[name];
    if (durations == null || durations.isEmpty) return null;

    durations.sort();
    final min = durations.first;
    final max = durations.last;
    final avg = getAverageDuration(name)!;
    final median = durations[durations.length ~/ 2];

    return {
      'name': name,
      'count': durations.length,
      'min': min,
      'max': max,
      'avg': avg.round(),
      'median': median,
    };
  }

  /// Get all tracked operations with their stats
  Map<String, Map<String, dynamic>> getAllStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final name in _operationDurations.keys) {
      final opStats = getStats(name);
      if (opStats != null) {
        stats[name] = opStats;
      }
    }
    return stats;
  }

  /// Print performance report
  void printReport() {
    logger.i('═══════════════════════════════════════════');
    logger.i('📊 Performance Report');
    logger.i('═══════════════════════════════════════════');

    final stats = getAllStats();
    if (stats.isEmpty) {
      logger.i('No performance data collected yet');
      return;
    }

    // Sort by average duration (slowest first)
    final sortedEntries = stats.entries.toList()
      ..sort(
        (a, b) => (b.value['avg'] as int).compareTo(a.value['avg'] as int),
      );

    for (final entry in sortedEntries) {
      final name = entry.key;
      final s = entry.value;
      logger.i(
        '$name: avg=${s['avg']}ms, min=${s['min']}ms, max=${s['max']}ms, count=${s['count']}',
      );
    }

    logger.i('═══════════════════════════════════════════');
  }

  /// Clear all performance data
  void clear() {
    _startTimes.clear();
    _operationDurations.clear();
    logger.d('Performance data cleared');
  }

  /// Clear data for a specific operation
  void clearOperation(String name) {
    _startTimes.remove(name);
    _operationDurations.remove(name);
    logger.d('Performance data cleared for: $name');
  }
}
