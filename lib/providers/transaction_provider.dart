import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/local_storage.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

final localStorageProvider = Provider<LocalStorage>(
      (ref) {
    throw UnimplementedError(
      'LocalStorage должен быть инициализирован в main.dart',
    );
  },
);

final transactionRepositoryProvider =
Provider<TransactionRepository>(
      (ref) {
    final storage = ref.watch(localStorageProvider);

    return TransactionRepository(storage);
  },
);

final transactionProvider =
AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
  TransactionNotifier.new,
);

class TransactionNotifier
    extends AsyncNotifier<List<Transaction>> {
  late final TransactionRepository _repository;

  @override
  Future<List<Transaction>> build() async {
    _repository = ref.read(
      transactionRepositoryProvider,
    );

    return _repository.getTransactions();
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required TransactionType type,
    required DateTime date,
  }) async {
    final transaction = Transaction(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      title: title,
      category: category,
      amount: amount,
      type: type,
      date: date,
    );

    try {
      await _repository.addTransaction(transaction);

      state = AsyncData(
        _repository.getTransactions(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);

      state = AsyncData(
        _repository.getTransactions(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }

  Future<void> updateTransaction(
      Transaction transaction,
      ) async {
    try {
      await _repository.updateTransaction(
        transaction,
      );

      state = AsyncData(
        _repository.getTransactions(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }

  Future<void> clearTransactions() async {
    try {
      await _repository.clearTransactions();

      state = const AsyncData([]);
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }
}