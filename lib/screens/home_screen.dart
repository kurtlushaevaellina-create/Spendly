import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spendly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
          return _HomeContent(
            transactions: transactions,
            ref: ref,
          );
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Transaction> transactions;
  final WidgetRef ref;

  const _HomeContent({
    required this.transactions,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    final expenses = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    final balance = income - expenses;

    final recentTransactions = [...transactions]
      ..sort(
            (a, b) => b.date.compareTo(a.date),
      );

    final displayedTransactions =
    recentTransactions.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionProvider);
        await ref.read(transactionProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(
            balance: balance,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Доходы',
                  amount: income,
                  color: Colors.green,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Расходы',
                  amount: expenses,
                  color: Colors.red,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Последние операции',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${displayedTransactions.length}',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (displayedTransactions.isEmpty)
            const _EmptyTransactions()
          else
            ...displayedTransactions.map(
                  (transaction) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TransactionTile(
                      transaction: transaction,
                      onDelete: () {
                        _deleteTransaction(
                          context,
                          ref,
                          transaction,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(
      BuildContext context,
      WidgetRef ref,
      Transaction transaction,
      ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить операцию?'),
          content: Text(
            'Операция «${transaction.title}» будет удалена.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref
        .read(transactionProvider.notifier)
        .deleteTransaction(transaction.id);
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day.$month.$year';
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6750A4),
            Color(0xFF8A6BC1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Текущий баланс',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNegative
                ? 'Расходы превышают доходы'
                : 'Баланс в норме',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Операций пока нет',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Добавьте первую операцию во вкладке «Операции».',
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
              'Не удалось загрузить операции',
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