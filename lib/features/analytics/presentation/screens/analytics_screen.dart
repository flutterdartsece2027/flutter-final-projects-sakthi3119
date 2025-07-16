import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/data/providers/transaction_provider.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class AnalyticsData {
  final Map<String, double> monthlySpending;
  final Map<String, double> categorySpending;

  AnalyticsData({
    required this.monthlySpending,
    required this.categorySpending,
  });

  AnalyticsData copyWith({
    Map<String, double>? monthlySpending,
    Map<String, double>? categorySpending,
  }) {
    return AnalyticsData(
      monthlySpending: monthlySpending ?? this.monthlySpending,
      categorySpending: categorySpending ?? this.categorySpending,
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  AnalyticsData? _analyticsData;

  @override
  void initState() {
    super.initState();
    // Load data when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the route changes and this screen becomes visible again
    final transactionProvider = context.read<TransactionProvider>();
    if (transactionProvider.shouldReload) {
      _loadAnalyticsData();
      transactionProvider.markReloaded();
    }
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading analytics data...');
      final transactionProvider = context.read<TransactionProvider>();
      
      if (transactionProvider == null) {
        throw Exception('TransactionProvider not found');
      }
      
      print('Fetching monthly spending...');
      final monthlySpending = await transactionProvider.getMonthlySpending();
      print('Monthly spending data: $monthlySpending');
      
      print('Fetching category spending...');
      final categorySpending = await transactionProvider.getCategorySpending();
      print('Category spending data: $categorySpending');
      
      if (mounted) {
        setState(() {
          _analyticsData = AnalyticsData(
            monthlySpending: monthlySpending,
            categorySpending: categorySpending,
          );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading analytics data: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAnalyticsData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics data...'),
          ],
        ),
      );
    }

    if (_analyticsData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No data available'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadAnalyticsData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMonthlySpendingChart(_analyticsData!.monthlySpending),
          const SizedBox(height: 24),
          _buildCategoryChart(_analyticsData!.categorySpending),
        ],
      ),
    );
  }

  Widget _buildMonthlySpendingChart(Map<String, double> monthlyData) {
    if (monthlyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No spending data available'),
        ),
      );
    }

    final monthlyEntries = monthlyData.entries.toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(monthlyEntries),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${monthlyEntries[groupIndex].key}\n${CurrencyFormatter.format(rod.toY)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < monthlyEntries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthlyEntries[index].key.split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(CurrencyFormatter.formatCompact(value));
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final monthData = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthData.value,
                          color: _getBarColor(index),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, double> categoryData) {
    if (categoryData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No category data available'),
        ),
      );
    }

    final categoryEntries = categoryData.entries.toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: categoryData.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return PieChartSectionData(
                      value: data.value,
                      title: '${data.key}\n${CurrencyFormatter.formatCompact(data.value)}',
                      radius: 80,
                      color: _getPieColor(index),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...categoryEntries.map((entry) {
              final index = categoryEntries.indexOf(entry);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getPieColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.key),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<MapEntry<String, double>> data) {
    if (data.isEmpty) return 1000;
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  String _getMonthName(int month) {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }

  Color _getBarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Color _getPieColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.lightBlue,
    ];
    return colors[index % colors.length];
  }
}
