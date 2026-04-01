import 'dart:math';
import '../models/models.dart';

class PatternService {
  static const List<Map<String, dynamic>> _patterns = [
    {
      'name': 'Doji',
      'nameZh': '十字星',
      'description': '开盘价与收盘价几乎相同，表示市场犹豫不决，可能出现趋势反转',
      'emoji': '✚',
      'isBullish': null, // 中性
    },
    {
      'name': 'Hammer',
      'nameZh': '锤子线',
      'description': '下影线是实体的2倍以上，出现在下跌趋势末端，看涨反转信号',
      'emoji': '🔨',
      'isBullish': true,
    },
    {
      'name': 'Shooting Star',
      'nameZh': '射击之星',
      'description': '上影线是实体的2倍以上，出现在上涨趋势末端，看跌反转信号',
      'emoji': '⭐',
      'isBullish': false,
    },
    {
      'name': 'Bullish Engulfing',
      'nameZh': '看涨吞没',
      'description': '大阳线完全吞没前一根阴线，强烈看涨信号',
      'emoji': '📈',
      'isBullish': true,
    },
    {
      'name': 'Bearish Engulfing',
      'nameZh': '看跌吞没',
      'description': '大阴线完全吞没前一根阳线，强烈看跌信号',
      'emoji': '📉',
      'isBullish': false,
    },
    {
      'name': 'Morning Star',
      'nameZh': '启明星',
      'description': '三根K线：大阴线+小实体+大阳线，看涨反转信号',
      'emoji': '🌅',
      'isBullish': true,
    },
    {
      'name': 'Evening Star',
      'nameZh': '黄昏之星',
      'description': '三根K线：大阳线+小实体+大阴线，看跌反转信号',
      'emoji': '🌆',
      'isBullish': false,
    },
    {
      'name': 'Bullish Harami',
      'nameZh': '看涨孕线',
      'description': '大阴线之后出现小阳线，实体在前一根K线范围内，潜在反转',
      'emoji': '🤰',
      'isBullish': true,
    },
    {
      'name': 'Three White Soldiers',
      'nameZh': '三白兵',
      'description': '连续三根递增阳线，强烈看涨信号',
      'emoji': '⚔️',
      'isBullish': true,
    },
    {
      'name': 'Three Black Crows',
      'nameZh': '三只乌鸦',
      'description': '连续三根递减阴线，强烈看跌信号',
      'emoji': '🐦‍⬛',
      'isBullish': false,
    },
    {
      'name': 'Pin Bar',
      'nameZh': '钉头棒',
      'description': '长影线+小实体，影线指向阻力/支撑区域，强力反转信号',
      'emoji': '📌',
      'isBullish': null,
    },
    {
      'name': 'Inside Bar',
      'nameZh': '内包线',
      'description': '第二根K线完全在第一根范围内，市场蓄势待发',
      'emoji': '📦',
      'isBullish': null,
    },
  ];

  static List<PatternResult> analyzeCandles(List<CandleData> candles) {
    if (candles.isEmpty) return [];

    List<PatternResult> results = [];
    final random = Random();

    // 模拟分析（真实应用中应使用完整的技术分析算法）
    int patternCount = 1 + random.nextInt(3);
    final shuffled = List.from(_patterns)..shuffle(random);

    for (int i = 0; i < patternCount && i < shuffled.length; i++) {
      final pattern = shuffled[i];
      results.add(PatternResult(
        name: pattern['name'],
        nameZh: pattern['nameZh'],
        description: pattern['description'],
        isBullish: pattern['isBullish'] ?? (random.nextBool()),
        confidence: 0.5 + random.nextDouble() * 0.45,
        emoji: pattern['emoji'],
      ));
    }

    return results;
  }

  static List<Map<String, dynamic>> getAllPatterns() => _patterns;

  static Map<String, dynamic>? getPatternByName(String name) {
    try {
      return _patterns.firstWhere((p) => p['name'] == name);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getQuizOptions(String correctPattern) {
    final random = Random();
    List<Map<String, dynamic>> options = [
      _patterns.firstWhere((p) => p['name'] == correctPattern),
    ];

    final others = _patterns.where((p) => p['name'] != correctPattern).toList()
      ..shuffle(random);

    options.addAll(others.take(3));
    options.shuffle(random);

    return options;
  }
}
