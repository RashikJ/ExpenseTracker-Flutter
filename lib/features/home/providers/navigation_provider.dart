import 'package:flutter_riverpod/legacy.dart';

class HistoryFilterRequest {
  final String period; // 'Day' | 'Month' | 'Year'
  final DateTime date;

  const HistoryFilterRequest({required this.period, required this.date});
}

final selectedTabProvider = StateProvider<int>((ref) => 0);

final historyFilterRequestProvider =
    StateProvider<HistoryFilterRequest?>((ref) => null);