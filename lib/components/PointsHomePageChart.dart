import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PointsChart extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>>? branchData;
  final bool isLoading;
  final String? errorMessage;

  const PointsChart({
    super.key,
    this.branchData,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<PointsChart> createState() => _PointsChartState();
}

class _PointsChartState extends State<PointsChart> {
  bool showEarned = true;
  String? selectedBranch;

  // Modern gradient colors
  final List<Color> earnedGradient = [
    const Color(0xFF00D4AA),
    const Color(0xFF00A896),
  ];

  final List<Color> redeemedGradient = [
    const Color(0xFFFF6B9D),
    const Color(0xFFC9184A),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSelectedBranch();
  }

  @override
  void didUpdateWidget(PointsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.branchData != oldWidget.branchData) {
      _initializeSelectedBranch();
    }
  }

  void _initializeSelectedBranch() {
    if (widget.branchData != null && widget.branchData!.isNotEmpty) {
      if (selectedBranch == null || !widget.branchData!.containsKey(selectedBranch)) {
        selectedBranch = widget.branchData!.keys.first;
      }
    }
  }

  List<Map<String, dynamic>> get currentData {
    if (widget.branchData == null || selectedBranch == null) {
      return [];
    }
    return widget.branchData![selectedBranch] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),
          // Branch selector and toggle
          _buildControls(),
          const SizedBox(height: 20),
          // Content
          if (widget.isLoading)
            _buildLoadingState()
          else if (widget.errorMessage != null)
            _buildErrorState()
          else if (widget.branchData == null || widget.branchData!.isEmpty)
              _buildEmptyState()
            else if (currentData.isEmpty)
                _buildEmptyState(message: 'No data for selected branch')
              else
                _buildChart(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showEarned ? "Points Earned" : "Points Redeemed",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isLoading
              ? "Loading data..."
              : currentData.isEmpty
              ? "No entries available"
              : "Last ${currentData.length} ${currentData.length == 1 ? 'entry' : 'entries'}",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (widget.isLoading || widget.errorMessage != null || widget.branchData == null || widget.branchData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Branch dropdown
        Expanded(
          child: _buildBranchDropdown(),
        ),
        const SizedBox(width: 12),
        // Toggle button
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildBranchDropdown() {
    final branches = widget.branchData!.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBranch,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[700],
            size: 22,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: branches.map((branch) {
            final dataCount = widget.branchData![branch]?.length ?? 0;
            return DropdownMenuItem<String>(
              value: branch,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: showEarned
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFFFF6B9D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      branch,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$dataCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedBranch = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: showEarned
            ? const Color(0xFF00D4AA).withOpacity(0.1)
            : const Color(0xFFFF6B9D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              showEarned = !showEarned;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showEarned ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: showEarned
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6B9D),
                ),
                const SizedBox(width: 6),
                Text(
                  showEarned ? "Earned" : "Redeemed",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: showEarned
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFFFF6B9D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final data = currentData;
    if (data.isEmpty) return _buildEmptyState();

    // Prepare FlSpots
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < data.length; i++) {
      final y = showEarned
          ? (data[i]['points_earned'] as num).toDouble()
          : (data[i]['points_redeemed'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    // Extract bottom titles (dates)
    List<String> bottomLabels = data
        .map((e) => e['date'].toString().substring(5))
        .toList(); // MM-DD

    // Dynamic Y interval
    final yInterval = maxY > 0 ? (maxY / 5).ceilToDouble() : 1.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY > 0 ? maxY * 1.2 : 10,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  final intVal = value.toInt();
                  String text;
                  if (intVal >= 1000) {
                    text = '${(intVal / 1000).toStringAsFixed(1)}k';
                  } else {
                    text = intVal.toString();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= bottomLabels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      bottomLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              barWidth: 3.5,
              isStrokeCapRound: true,
              gradient: LinearGradient(
                colors: showEarned ? earnedGradient : redeemedGradient,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: (showEarned ? earnedGradient : redeemedGradient)
                      .map((c) => c.withOpacity(0.15))
                      .toList(),
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: showEarned
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFFFF6B9D),
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.white,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              tooltipBorder: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = data[index]['date'].toString();
                  final value = spot.y.toInt();
                  return LineTooltipItem(
                    '$date\n',
                    TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: '$value pts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: showEarned
                              ? const Color(0xFF00D4AA)
                              : const Color(0xFFFF6B9D),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: (showEarned
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFFFF6B9D))
                        .withOpacity(0.3),
                    strokeWidth: 2,
                    dashArray: [5, 5],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: showEarned
                            ? const Color(0xFF00D4AA)
                            : const Color(0xFFFF6B9D),
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 45,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          if (index == 5) return const SizedBox(height: 12);
                          return Container(
                            width: 30,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: _SkeletonChartPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -1.0, end: 2.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        (value - 0.3).clamp(0.0, 1.0),
                        value.clamp(0.0, 1.0),
                        (value + 0.3).clamp(0.0, 1.0),
                      ],
                      colors: const [
                        Colors.transparent,
                        Colors.white38,
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  child: Container(color: Colors.white),
                );
              },
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.show_chart,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'No data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chart data will appear here once available',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.errorMessage ?? 'An error occurred',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.3,
    );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      final y = size.height * 0.5 + (i % 2 == 0 ? -20 : 10);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}