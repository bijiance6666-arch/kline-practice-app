import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;
  final int visibleCount;
  final bool showVolume;
  final bool hideLast;
  final int hideCount;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.visibleCount = 50,
    this.showVolume = true,
    this.hideLast = false,
    this.hideCount = 5,
  });

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  late ScrollController _scrollController;
  double _scale = 1.0;
  double _lastScale = 1.0;
  int _tooltipIndex = -1;
  CandleData? _tooltipCandle;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCandles = widget.hideLast
        ? widget.candles.sublist(0, widget.candles.length - widget.hideCount)
        : widget.candles;

    return Column(
      children: [
        if (_tooltipCandle != null) _buildTooltip(_tooltipCandle!),
        Expanded(
          flex: widget.showVolume ? 7 : 10,
          child: GestureDetector(
            onScaleStart: (details) {
              _lastScale = _scale;
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_lastScale * details.scale).clamp(0.5, 3.0);
              });
            },
            onTapUp: (details) {
              setState(() {
                _tooltipIndex = -1;
                _tooltipCandle = null;
              });
            },
            child: CustomPaint(
              painter: CandlePainter(
                candles: visibleCandles,
                scale: _scale,
                tooltipIndex: _tooltipIndex,
              ),
              child: Container(),
            ),
          ),
        ),
        if (widget.showVolume)
          Expanded(
            flex: 2,
            child: CustomPaint(
              painter: VolumePainter(candles: visibleCandles),
              child: Container(),
            ),
          ),
        if (widget.hideLast)
          Container(
            height: 40,
            color: AppColors.surface.withOpacity(0.5),
            child: const Center(
              child: Text(
                '? ? ? ? ?  ← 猜测后续走势',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTooltip(CandleData candle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tooltipItem('开', candle.open, candle.isBullish ? AppColors.bullish : AppColors.bearish),
          const SizedBox(width: 16),
          _tooltipItem('高', candle.high, AppColors.bullish),
          const SizedBox(width: 16),
          _tooltipItem('低', candle.low, AppColors.bearish),
          const SizedBox(width: 16),
          _tooltipItem('收', candle.close, candle.isBullish ? AppColors.bullish : AppColors.bearish),
          const SizedBox(width: 16),
          _tooltipItem('量', candle.volume, AppColors.info),
        ],
      ),
    );
  }

  Widget _tooltipItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class CandlePainter extends CustomPainter {
  final List<CandleData> candles;
  final double scale;
  final int tooltipIndex;

  CandlePainter({
    required this.candles,
    this.scale = 1.0,
    this.tooltipIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final bullPaint = Paint()
      ..color = AppColors.bullish
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    final bearPaint = Paint()
      ..color = AppColors.bearish
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    final wickBullPaint = Paint()
      ..color = AppColors.bullish
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final wickBearPaint = Paint()
      ..color = AppColors.bearish
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 计算价格范围
    double maxHigh = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minLow = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double priceRange = maxHigh - minLow;
    if (priceRange == 0) priceRange = 1;

    final padding = priceRange * 0.05;
    maxHigh += padding;
    minLow -= padding;
    priceRange = maxHigh - minLow;

    final count = candles.length;
    final candleWidth = (size.width / count) * scale;
    final bodyWidth = candleWidth * 0.6;

    // 绘制网格线
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final price = maxHigh - (priceRange * i / 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(1),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y + 2));
    }

    // 绘制K线
    for (int i = 0; i < count; i++) {
      final candle = candles[i];
      final x = (i + 0.5) * (size.width / count);

      final highY = (maxHigh - candle.high) / priceRange * size.height;
      final lowY = (maxHigh - candle.low) / priceRange * size.height;
      final openY = (maxHigh - candle.open) / priceRange * size.height;
      final closeY = (maxHigh - candle.close) / priceRange * size.height;

      final paint = candle.isBullish ? bullPaint : bearPaint;
      final wickPaint = candle.isBullish ? wickBullPaint : wickBearPaint;

      // 影线
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // 实体
      final bodyTop = openY < closeY ? openY : closeY;
      final bodyBottom = openY > closeY ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      if (bodyHeight < 2) {
        // Doji - 画横线
        canvas.drawLine(
          Offset(x - bodyWidth / 2, bodyTop),
          Offset(x + bodyWidth / 2, bodyTop),
          paint,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(
            x - bodyWidth / 2,
            bodyTop,
            bodyWidth,
            bodyHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CandlePainter oldDelegate) =>
      oldDelegate.candles != candles || oldDelegate.scale != scale;
}

class VolumePainter extends CustomPainter {
  final List<CandleData> candles;

  VolumePainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxVol = candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);
    if (maxVol == 0) maxVol = 1;

    final count = candles.length;
    final barWidth = (size.width / count) * 0.6;

    for (int i = 0; i < count; i++) {
      final candle = candles[i];
      final x = (i + 0.5) * (size.width / count);
      final barHeight = (candle.volume / maxVol) * size.height * 0.85;

      final paint = Paint()
        ..color = (candle.isBullish ? AppColors.bullish : AppColors.bearish).withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          x - barWidth / 2,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VolumePainter oldDelegate) =>
      oldDelegate.candles != candles;
}
