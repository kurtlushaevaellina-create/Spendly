import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

enum TransactionFilter {
  all,
  income,
  expense,
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  TransactionFilter _selectedFilter =
      TransactionFilter.all;

  String? _selectedCategory;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операции'),
        actions: [
          IconButton(
            onPressed: () {
              _showFilters();
            },
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
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
          return _buildContent(transactions);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTransactionDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedFilter != TransactionFilter.all ||
        _selectedCategory != null ||
        _selectedDate != null;
  }

  Widget _buildContent(List<Transaction> transactions) {
    final filtered = _filterTransactions(transactions);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск операции...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        _ActiveFilters(
          filter: _selectedFilter,
          category: _selectedCategory,
          date: _selectedDate,
          onClear: _clearFilters,
        ),

        Expanded(
          child: filtered.isEmpty
              ? const _EmptySearchResult()
              : RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionProvider);
              await ref.read(transactionProvider.future);
            },
            child: ListView.builder(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                100,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final transaction = filtered[index];

                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    if (_shouldShowDate(
                      filtered,
                      index,
                    ))
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 8,
                          bottom: 6,
                        ),
                        child: Text(
                          _formatDate(
                            transaction.date,
                          ),
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ),
                    TransactionTile(
                      transaction: transaction,
                      onEdit: () {
                        _showTransactionDialog(
                          transaction: transaction,
                        );
                      },
                      onDelete: () {
                        _deleteTransaction(
                          transaction,
                        );
                      },
                    ),
                    if (index <
                        filtered.length - 1)
                      const SizedBox(height: 2),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Transaction> _filterTransactions(
      List<Transaction> transactions,
      ) {
    final query =
    _searchController.text.trim().toLowerCase();

    final result = transactions.where((transaction) {
      if (_selectedFilter == TransactionFilter.income &&
          !transaction.isIncome) {
        return false;
      }

      if (_selectedFilter == TransactionFilter.expense &&
          !transaction.isExpense) {
        return false;
      }

      if (_selectedCategory != null &&
          transaction.category != _selectedCategory) {
        return false;
      }

      if (_selectedDate != null &&
          !_isSameDate(
            transaction.date,
            _selectedDate!,
          )) {
        return false;
      }

      if (query.isNotEmpty) {
        final title =
        transaction.title.toLowerCase();
        final category =
        transaction.category.toLowerCase();

        if (!title.contains(query) &&
            !category.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    result.sort(
          (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  bool _shouldShowDate(
      List<Transaction> transactions,
      int index,
      ) {
    if (index == 0) {
      return true;
    }

    return !_isSameDate(
      transactions[index].date,
      transactions[index - 1].date,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = TransactionFilter.all;
      _selectedCategory = null;
      _selectedDate = null;
    });
  }

  Future<void> _showFilters() async {
    TransactionFilter tempFilter = _selectedFilter;
    String? tempCategory = _selectedCategory;
    DateTime? tempDate = _selectedDate;

    final categories = _getCategories();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Фильтры',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Тип операции',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SegmentedButton<TransactionFilter>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionFilter.all,
                          label: Text('Все'),
                        ),
                        ButtonSegment(
                          value: TransactionFilter.income,
                          label: Text('Доходы'),
                        ),
                        ButtonSegment(
                          value: TransactionFilter.expense,
                          label: Text('Расходы'),
                        ),
                      ],
                      selected: {tempFilter},
                      onSelectionChanged: (value) {
                        setModalState(() {
                          tempFilter = value.first;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String?>(
                      initialValue: tempCategory,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Все категории'),
                        ),
                        ...categories.map(
                              (category) =>
                              DropdownMenuItem<String?>(
                                value: category,
                                child: Text(category),
                              ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: const Text('Дата'),
                      subtitle: Text(
                        tempDate == null
                            ? 'Любая дата'
                            : _formatDate(tempDate!),
                      ),
                      trailing: tempDate != null
                          ? IconButton(
                        onPressed: () {
                          setModalState(() {
                            tempDate = null;
                          });
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      )
                          : const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final picked =
                        await showDatePicker(
                          context: context,
                          initialDate:
                          tempDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setModalState(() {
                            tempDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter =
                                tempFilter;
                            _selectedCategory =
                                tempCategory;
                            _selectedDate = tempDate;
                          });

                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Применить',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _getCategories() {
    final asyncValue = ref.read(transactionProvider);

    final transactions = asyncValue.when(
      data: (value) => value,
      loading: () => <Transaction>[],
      error: (_, _) => <Transaction>[],
    );

    return transactions
        .map((transaction) => transaction.category)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _showTransactionDialog({
    Transaction? transaction,
  }) async {
    final titleController = TextEditingController(
      text: transaction?.title ?? '',
    );

    final amountController = TextEditingController(
      text: transaction == null
          ? ''
          : transaction.amount.toStringAsFixed(2),
    );

    String selectedCategory =
        transaction?.category ?? 'Еда';

    TransactionType selectedType =
        transaction?.type ?? TransactionType.expense;

    DateTime selectedDate =
        transaction?.date ?? DateTime.now();

    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                transaction == null
                    ? 'Новая операция'
                    : 'Редактирование',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textCapitalization:
                      TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText:
                        'Например, продукты',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Сумма',
                        suffixText: '₽',
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Еда',
                          child: Text('Еда'),
                        ),
                        DropdownMenuItem(
                          value: 'Транспорт',
                          child: Text('Транспорт'),
                        ),
                        DropdownMenuItem(
                          value: 'Покупки',
                          child: Text('Покупки'),
                        ),
                        DropdownMenuItem(
                          value: 'Развлечения',
                          child: Text('Развлечения'),
                        ),
                        DropdownMenuItem(
                          value: 'Дом',
                          child: Text('Дом'),
                        ),
                        DropdownMenuItem(
                          value: 'Здоровье',
                          child: Text('Здоровье'),
                        ),
                        DropdownMenuItem(
                          value: 'Доход',
                          child: Text('Доход'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Расход'),
                          icon: Icon(
                            Icons.arrow_upward,
                          ),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Доход'),
                          icon: Icon(
                            Icons.arrow_downward,
                          ),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (value) {
                        setDialogState(() {
                          selectedType = value.first;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                      ),
                      title: const Text(
                        'Дата операции',
                      ),
                      subtitle: Text(
                        _formatDate(selectedDate),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final picked =
                        await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),

                    if (validationError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        validationError!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Отмена'),
                ),

                FilledButton(
                  onPressed: () async {
                    final title =
                    titleController.text.trim();

                    final amount = double.tryParse(
                      amountController.text
                          .trim()
                          .replaceAll(',', '.'),
                    );

                    if (title.isEmpty) {
                      setDialogState(() {
                        validationError =
                        'Введите название операции';
                      });
                      return;
                    }

                    if (amount == null ||
                        amount <= 0) {
                      setDialogState(() {
                        validationError =
                        'Введите корректную сумму';
                      });
                      return;
                    }

                    if (transaction == null) {
                      await ref
                          .read(
                        transactionProvider.notifier,
                      )
                          .addTransaction(
                        title: title,
                        category:
                        selectedCategory,
                        amount: amount,
                        type: selectedType,
                        date: selectedDate,
                      );
                    } else {
                      final updated =
                      transaction.copyWith(
                        title: title,
                        category: selectedCategory,
                        amount: amount,
                        type: selectedType,
                        date: selectedDate,
                      );

                      await ref
                          .read(
                        transactionProvider.notifier,
                      )
                          .updateTransaction(
                        updated,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(
                    transaction == null
                        ? 'Добавить'
                        : 'Сохранить',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
  }

  Future<void> _deleteTransaction(
      Transaction transaction,
      ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить операцию?'),
          content: Text(
            '«${transaction.title}» будет удалена.',
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

  static bool _isSameDate(
      DateTime first,
      DateTime second,
      ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month =
    date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }
}

class _ActiveFilters extends StatelessWidget {
  final TransactionFilter filter;
  final String? category;
  final DateTime? date;
  final VoidCallback onClear;

  const _ActiveFilters({
    required this.filter,
    required this.category,
    required this.date,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        filter != TransactionFilter.all ||
            category != null ||
            date != null;

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    final labels = <String>[];

    if (filter == TransactionFilter.income) {
      labels.add('Доходы');
    }

    if (filter == TransactionFilter.expense) {
      labels.add('Расходы');
    }

    if (category != null) {
      labels.add(category!);
    }

    if (date != null) {
      labels.add(
        '${date!.day.toString().padLeft(2, '0')}.'
            '${date!.month.toString().padLeft(2, '0')}.'
            '${date!.year}',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: labels
                    .map(
                      (label) => Padding(
                    padding:
                    const EdgeInsets.only(
                      right: 6,
                    ),
                    child: Chip(
                      label: Text(label),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Попробуйте изменить поиск или фильтры.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
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