import '../local/local_storage.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final LocalStorage _storage;

  TransactionRepository(this._storage);

  List<Transaction> getTransactions() {
    return _storage.getTransactions();
  }

  Future<void> addTransaction(
      Transaction transaction,
      ) async {
    final transactions = getTransactions();

    transactions.insert(0, transaction);

    await _storage.saveTransactions(transactions);
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = getTransactions();

    transactions.removeWhere(
          (transaction) => transaction.id == id,
    );

    await _storage.saveTransactions(transactions);
  }

  Future<void> updateTransaction(
      Transaction updatedTransaction,
      ) async {
    final transactions = getTransactions();

    final index = transactions.indexWhere(
          (transaction) =>
      transaction.id == updatedTransaction.id,
    );

    if (index == -1) {
      return;
    }

    transactions[index] = updatedTransaction;

    await _storage.saveTransactions(transactions);
  }
  Future<void> clearTransactions() async {
    await _storage.clearTransactions();
  }
}