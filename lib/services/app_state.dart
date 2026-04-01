import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  UserStats _stats = UserStats(
    totalPractices: 247,
    correctAnswers: 183,
    streak: 7,
    maxStreak: 23,
    xp: 3420,
    level: 4,
  );

  bool _isPremium = false;
  int _currentNavIndex = 0;
  String _selectedSymbol = 'XAUUSD';
  String _selectedTimeframe = 'M30';

  UserStats get stats => _stats;
  bool get isPremium => _isPremium;
  int get currentNavIndex => _currentNavIndex;
  String get selectedSymbol => _selectedSymbol;
  String get selectedTimeframe => _selectedTimeframe;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void recordAnswer(bool correct) {
    _stats.totalPractices++;
    if (correct) {
      _stats.correctAnswers++;
      _stats.streak++;
      _stats.xp += 50 + (_stats.streak * 10);
      if (_stats.streak > _stats.maxStreak) {
        _stats.maxStreak = _stats.streak;
      }
    } else {
      _stats.streak = 0;
      _stats.xp += 10;
    }

    // 升级检查
    while (_stats.xp >= _stats.xpToNextLevel) {
      _stats.level++;
    }

    notifyListeners();
  }

  void setSymbol(String symbol) {
    _selectedSymbol = symbol;
    notifyListeners();
  }

  void setTimeframe(String tf) {
    _selectedTimeframe = tf;
    notifyListeners();
  }

  void upgradeToPremium() {
    _isPremium = true;
    notifyListeners();
  }
}
