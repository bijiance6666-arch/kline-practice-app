import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/pattern_service.dart';
import '../models/models.dart';
import '../widgets/candlestick_chart.dart';

enum PracticeMode { patternRecognition, upDownPrediction, simulatedTrading }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  PracticeMode _mode = PracticeMode.patternRecognition;
  List<CandleData> _candles = [];
  List<Map<String, dynamic>> _options = [];
  String? _correctAnswer;
  String? _selectedAnswer;
  bool _answered = false;
  int _questionNumber = 0;
  int _score = 0;
  bool _showResult = false;
  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultAnim;
  String _selectedTimeframe = 'M30';
  String _selectedSymbol = 'XAUUSD';

  final List<String> _timeframes = ['M5', 'M15', 'M30', 'H1', 'H4', 'D1'];
  final List<String> _symbols = ['XAUUSD', 'BTCUSDT', 'EURUSD'];

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultAnim = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.elasticOut,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = Random();
    final trends = ['up', 'down', 'random'];
    _candles = MockDataGenerator.generateCandles(
      count: 60,
      startPrice: 2000 + random.nextDouble() * 500,
      trend: trends[random.nextInt(trends.length)],
    );

    if (_mode == PracticeMode.patternRecognition) {
      final patterns = PatternService.getAllPatterns();
      final correct = patterns[random.nextInt(patterns.length)];
      _correctAnswer = correct['name'];
      _options = PatternService.getQuizOptions(correct['name']);
    } else {
      // 涨跌预测模式
      _correctAnswer = _candles.last.isBullish ? 'up' : 'down';
    }

    setState(() {
      _answered = false;
      _selectedAnswer = null;
      _showResult = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final isCorrect = answer == _correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _showResult = true;
      if (isCorrect) {
        _score++;
      }
      _questionNumber++;
    });

    context.read<AppState>().recordAnswer(isCorrect);
    _resultAnimCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildModeSelector(),
          _buildFilterBar(),
          Expanded(
            child: _mode == PracticeMode.patternRecognition
                ? _buildPatternMode()
                : _buildUpDownMode(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '练习训练',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            '本轮: $_score / $_questionNumber',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () {
            setState(() {
              _score = 0;
              _questionNumber = 0;
            });
            _generateQuestion();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () => _showSettings(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _modeTab('形态识别', PracticeMode.patternRecognition),
          _modeTab('涨跌预测', PracticeMode.upDownPrediction),
          _modeTab('模拟交易', PracticeMode.simulatedTrading),
        ],
      ),
    );
  }

  Widget _modeTab(String label, PracticeMode mode) {
    final isSelected = _mode == mode;
    final isPremium = mode == PracticeMode.simulatedTrading;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isPremium) {
            _showPremiumDialog();
            return;
          }
          setState(() {
            _mode = mode;
            _score = 0;
            _questionNumber = 0;
          });
          _generateQuestion();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 4),
                const Text('🔒', style: TextStyle(fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ..._timeframes.map(
            (tf) => GestureDetector(
              onTap: () {
                setState(() => _selectedTimeframe = tf);
                _generateQuestion();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTimeframe == tf
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedTimeframe == tf ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    color: _selectedTimeframe == tf ? AppColors.primary : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: _selectedTimeframe == tf ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(color: AppColors.border, width: 20),
          ..._symbols.map(
            (sym) => GestureDetector(
              onTap: () {
                setState(() => _selectedSymbol = sym);
                _generateQuestion();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedSymbol == sym
                      ? AppColors.info.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedSymbol == sym ? AppColors.info : AppColors.border,
                  ),
                ),
                child: Text(
                  sym,
                  style: TextStyle(
                    color: _selectedSymbol == sym ? AppColors.info : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: _selectedSymbol == sym ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternMode() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildChartHeader(),
                  Expanded(
                    child: CandlestickChart(
                      candles: _candles,
                      visibleCount: 50,
                      showVolume: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '这个K线形态是？',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...List.generate(
                _options.length,
                (i) => _buildPatternOption(_options[i]),
              ),
              if (_answered) _buildNextButton(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedSymbol,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedTimeframe,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Spacer(),
          _buildPriceIndicator(),
        ],
      ),
    );
  }

  Widget _buildPriceIndicator() {
    if (_candles.isEmpty) return const SizedBox();
    final last = _candles.last;
    final prev = _candles[_candles.length - 2];
    final change = ((last.close - prev.close) / prev.close * 100);
    final isUp = change >= 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          last.close.toStringAsFixed(2),
          style: TextStyle(
            color: isUp ? AppColors.bullish : AppColors.bearish,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isUp ? AppColors.bullish : AppColors.bearish).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isUp ? AppColors.bullish : AppColors.bearish,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternOption(Map<String, dynamic> option) {
    final isSelected = _selectedAnswer == option['name'];
    final isCorrect = option['name'] == _correctAnswer;

    Color borderColor = AppColors.border;
    Color bgColor = AppColors.surface;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;

    if (_answered) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.08);
        trailingIcon = Icons.check_circle;
        iconColor = AppColors.success;
      } else if (isSelected) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.08);
        trailingIcon = Icons.cancel;
        iconColor = AppColors.error;
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withOpacity(0.08);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(option['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected || (isCorrect && _answered) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(option['emoji'] ?? '📊', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['nameZh'],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_answered && isCorrect) ...[
                    const SizedBox(height: 2),
                    Text(
                      option['description'],
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailingIcon != null)
              ScaleTransition(
                scale: _resultAnim,
                child: Icon(trailingIcon, color: iconColor, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpDownMode() {
    final hiddenCount = 8;
    final visibleCandles = _candles.sublist(0, _candles.length - hiddenCount);

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildChartHeader(),
                  Expanded(
                    child: CandlestickChart(
                      candles: visibleCandles,
                      showVolume: true,
                      hideLast: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_answered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Text(
                  '预测后续 8 根K线的总体走势',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectAnswer('up'),
                        icon: const Icon(Icons.trending_up, size: 20),
                        label: const Text('看涨 📈'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bullish,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectAnswer('down'),
                        icon: const Icon(Icons.trending_down, size: 20),
                        label: const Text('看跌 📉'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bearish,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_answered) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _resultAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _resultAnim.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == _correctAnswer
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAnswer == _correctAnswer
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedAnswer == _correctAnswer ? '✅' : '❌',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAnswer == _correctAnswer ? '预测正确！+60 XP' : '预测失误，下次加油',
                                style: TextStyle(
                                  color: _selectedAnswer == _correctAnswer
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '实际走势：${_correctAnswer == "up" ? "上涨 ↑" : "下跌 ↓"}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildNextButton(),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _generateQuestion,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.info],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '下一题',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '练习设置',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text('K线数量', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Slider(
              value: 50,
              min: 20,
              max: 100,
              divisions: 8,
              activeColor: AppColors.primary,
              label: '50根',
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            const Text('难度级别', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: ['入门', '进阶', '专家'].map((d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text(d),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔒 高级功能', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          '模拟交易模式需要升级到专业版。体验完整的开仓、止盈、止损操作流程，像真实交易一样练习！',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('升级到专业版'),
          ),
        ],
      ),
    );
  }
}
