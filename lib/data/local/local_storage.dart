import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction.dart';

class LocalStorage {
  static const String _boxName = 'spendly_box';
  static const String _transactionsKey = 'transactions';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  Box get _box => Hive.box(_boxName);

  Future<void> saveTransactions(
      List<Transaction> transactions,
      ) async {
    final data = transactions
        .map((transaction) => transaction.toMap())
        .toList();

    await _box.put(
      _transactionsKey,
      jsonEncode(data),
    );
  }

  List<Transaction> getTransactions() {
    final value = _box.get(_transactionsKey);

    if (value == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(value as String);

    return decoded
        .map(
          (item) => Transaction.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<void> clearTransactions() async {
    await _box.delete(_transactionsKey);
  }
}