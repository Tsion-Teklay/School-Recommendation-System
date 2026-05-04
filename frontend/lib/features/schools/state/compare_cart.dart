import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/school_dtos.dart';

/// In-memory shopping-cart-style holder for schools the user has marked
/// "Add to compare" on. Survives navigation within a session but not a
/// page reload — that's deliberate, the saved-comparison endpoint is the
/// long-term store.
class CompareCart extends ChangeNotifier {
  final List<School> _items = [];
  static const int maxItems = 5;
  static const int minItems = 2;

  List<School> get items => List.unmodifiable(_items);
  int get length => _items.length;
  bool contains(int schoolId) => _items.any((s) => s.id == schoolId);
  bool get canCreateComparison =>
      _items.length >= minItems && _items.length <= maxItems;

  /// Returns true on success, false if we'd exceed the cap (5).
  bool add(School s) {
    if (contains(s.id)) return true;
    if (_items.length >= maxItems) return false;
    _items.add(s);
    notifyListeners();
    return true;
  }

  void remove(int schoolId) {
    final before = _items.length;
    _items.removeWhere((s) => s.id == schoolId);
    if (_items.length != before) notifyListeners();
  }

  void toggle(School s) {
    if (contains(s.id)) {
      remove(s.id);
    } else {
      add(s);
    }
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}

final compareCartProvider = ChangeNotifierProvider<CompareCart>((ref) {
  return CompareCart();
});
