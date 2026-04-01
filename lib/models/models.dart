import 'dart:math';

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;
  double get body => (close - open).abs();
  double get upperWick => high - (isBullish ? close : open);
  double get lowerWick => (isBullish ? open : close) - low;
  double get range => high - low;
}

class PatternResult {
  final String name;
  final String nameZh;
  final String description;
  final bool isBullish;
  final double confidence;
  final String emoji;

  PatternResult({
    required this.name,
    required this.nameZh,
    required this.description,
    required this.isBullish,
    required this.confidence,
    required this.emoji,
  });
}

class UserStats {
  int totalPractices;
  int correctAnswers;
  int streak;
  int maxStreak;
  int xp;
  int level;
  Map<String, int> patternAttempts;
  Map<String, int> patternCorrect;

  UserStats({
    this.totalPractices = 0,
    this.correctAnswers = 0,
    this.streak = 0,
    this.maxStreak = 0,
    this.xp = 0,
    this.level = 1,
    Map<String, int>? patternAttempts,
    Map<String, int>? patternCorrect,
  })  : patternAttempts = patternAttempts ?? {},
        patternCorrect = patternCorrect ?? {};

  double get accuracy =>
      totalPractices == 0 ? 0 : correctAnswers / totalPractices;

  int get xpToNextLevel => level * 500;
  int get currentLevelXp => xp - ((level - 1) * (level) ~/ 2 * 500);
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final int requiredValue;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    required this.requiredValue,
  });
}

class MarketSymbol {
  final String symbol;
  final String name;
  final String category;
  final bool isPremium;

  MarketSymbol({
    required this.symbol,
    required this.name,
    required this.category,
    required this.isPremium,
  });
}

// 模拟数据生成器
class MockDataGenerator {
  static final Random _random = Random();

  static List<CandleData> generateCandles({
    int count = 100,
    double startPrice = 2000.0,
    String trend = 'random',
  }) {
    List<CandleData> candles = [];
    double currentPrice = startPrice;
    DateTime now = DateTime.now();

    for (int i = count - 1; i >= 0; i--) {
      double volatility = currentPrice * 0.008;
      double trendBias = trend == 'up'
          ? 0.3
          : trend == 'down'
              ? -0.3
              : (_random.nextDouble() - 0.5) * 0.2;

      double change = (_random.nextDouble() - 0.5 + trendBias) * volatility;
      double open = currentPrice;
      double close = (currentPrice + change).clamp(currentPrice * 0.95, currentPrice * 1.05);

      double wickMultiplier = 0.3 + _random.nextDouble() * 0.7;
      double high = [open, close].reduce(max) + _random.nextDouble() * volatility * wickMultiplier;
      double low = [open, close].reduce(min) - _random.nextDouble() * volatility * wickMultiplier;

      double volume = 500 + _random.nextDouble() * 2000;

      candles.add(CandleData(
        time: now.subtract(Duration(minutes: 30 * i)),
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: double.parse(volume.toStringAsFixed(0)),
      ));

      currentPrice = close;
    }

    return candles;
  }

  static List<MarketSymbol> getSymbols() {
    return [
      MarketSymbol(symbol: 'XAUUSD', name: '黄金/美元', category: '贵金属', isPremium: false),
      MarketSymbol(symbol: 'BTCUSDT', name: '比特币/泰达币', category: '加密货币', isPremium: false),
      MarketSymbol(symbol: 'EURUSD', name: '欧元/美元', category: '外汇', isPremium: false),
      MarketSymbol(symbol: 'AAPL', name: '苹果公司', category: '美股', isPremium: true),
      MarketSymbol(symbol: 'TSLA', name: '特斯拉', category: '美股', isPremium: true),
      MarketSymbol(symbol: 'SPX500', name: '标普500指数', category: '指数', isPremium: true),
      MarketSymbol(symbol: 'ETHUSDT', name: '以太坊/泰达币', category: '加密货币', isPremium: true),
      MarketSymbol(symbol: 'USDJPY', name: '美元/日元', category: '外汇', isPremium: true),
    ];
  }

  static List<Achievement> getAchievements(UserStats stats) {
    return [
      Achievement(
        id: 'first_trade',
        title: '初出茅庐',
        description: '完成第一次练习',
        emoji: '🌱',
        isUnlocked: stats.totalPractices >= 1,
        requiredValue: 1,
      ),
      Achievement(
        id: 'ten_streak',
        title: '连胜王',
        description: '连续答对10次',
        emoji: '🔥',
        isUnlocked: stats.maxStreak >= 10,
        requiredValue: 10,
      ),
      Achievement(
        id: 'hundred_practices',
        title: '百战老手',
        description: '完成100次练习',
        emoji: '⚔️',
        isUnlocked: stats.totalPractices >= 100,
        requiredValue: 100,
      ),
      Achievement(
        id: 'accuracy_80',
        title: '精准狙击手',
        description: '准确率达到80%',
        emoji: '🎯',
        isUnlocked: stats.accuracy >= 0.8,
        requiredValue: 80,
      ),
      Achievement(
        id: 'level_5',
        title: '资深交易员',
        description: '达到5级',
        emoji: '💎',
        isUnlocked: stats.level >= 5,
        requiredValue: 5,
      ),
      Achievement(
        id: 'pattern_master',
        title: '形态大师',
        description: '识别50种不同形态',
        emoji: '🏆',
        isUnlocked: stats.patternAttempts.length >= 50,
        requiredValue: 50,
      ),
    ];
  }
}
