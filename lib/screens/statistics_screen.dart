import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transaction.dart';
import '../providers/transaction_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}

class _StatisticsScreenState
    extends ConsumerState<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorView(
          onRetry: () {
            ref.invalidate(transactionProvider);
          },
        ),
        data: (transactions) {
          return _buildStatistics(transactions);
        },
      ),
    );
  }

  Widget _buildStatistics(
      List<Transaction> transactions,
      ) {
    final monthTransactions = transactions.where(
          (transaction) {
        return transaction.date.year ==
            _selectedMonth.year &&
            transaction.date.month ==
                _selectedMonth.month;
      },
    ).toList();

    final expenses = monthTransactions
        .where((transaction) => transaction.isExpense)
        .toList();

    final income = monthTransactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    final totalExpenses = expenses.fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    final balance = income - totalExpenses;

    final categoryTotals =
    _calculateCategoryTotals(expenses);

    final sortedCategories =
    categoryTotals.entries.toList()
      ..sort(
            (a, b) => b.value.compareTo(a.value),
      );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionProvider);
        await ref.read(transactionProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            canGoNext: !_isCurrentMonth,
          ),

          const SizedBox(height: 16),

          _OverviewCard(
            income: income,
            expenses: totalExpenses,
            balance: balance,
            transactionCount:
            monthTransactions.length,
          ),

          const SizedBox(height: 24),

          const Text(
            'Расходы по категориям',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (expenses.isEmpty)
            const _EmptyStatistics()
          else
            ...sortedCategories.map(
                  (entry) {
                final percent =
                totalExpenses == 0
                    ? 0.0
                    : entry.value / totalExpenses;

                return _StatisticRow(
                  category: entry.key,
                  amount: entry.value,
                  percent: percent,
                );
              },
            ),

          const SizedBox(height: 24),

          const Text(
            'Операции за месяц',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (monthTransactions.isEmpty)
            const Text(
              'За выбранный месяц операций нет.',
            )
          else
            ..._sortedTransactions(
              monthTransactions,
            ).map(
                  (transaction) {
                return _SimpleTransactionRow(
                  transaction: transaction,
                );
              },
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals(
      List<Transaction> expenses,
      ) {
    final result = <String, double>{};

    for (final transaction in expenses) {
      result.update(
        transaction.category,
            (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return result;
  }

  List<Transaction> _sortedTransactions(
      List<Transaction> transactions,
      ) {
    final result = [...transactions];

    result.sort(
          (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();

    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(
              Icons.chevron_left,
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                _monthName(selectedMonth),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(
              Icons.chevron_right,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(DateTime date) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _OverviewCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;
  final int transactionCount;

  const _OverviewCard({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6750A4),
            Color(0xFF8A6BC1),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Итоги месяца',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${balance.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _OverviewItem(
                  title: 'Доходы',
                  value: income,
                  icon: Icons.arrow_downward,
                ),
              ),
              Expanded(
                child: _OverviewItem(
                  title: 'Расходы',
                  value: expenses,
                  icon: Icons.arrow_upward,
                ),
              ),
              Expanded(
                child: _OverviewItem(
                  title: 'Операции',
                  value: transactionCount.toDouble(),
                  icon: Icons.receipt_long,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final bool isCount;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          isCount
              ? value.toInt().toString()
              : '${value.toStringAsFixed(0)} ₽',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;

  const _StatisticRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '${amount.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${(percent * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTransactionRow
    extends StatelessWidget {
  final Transaction transaction;

  const _SimpleTransactionRow({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.category} • ${_formatDate(transaction.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome
                  ? Colors.green.shade700
                  : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day =
    date.day.toString().padLeft(2, '0');
    final month =
    date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }
}

class _EmptyStatistics
    extends StatelessWidget {
  const _EmptyStatistics();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Нет расходов',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'За выбранный месяц расходов пока нет.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Не удалось загрузить статистику',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}