import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled27/main.dart';
import 'package:untitled27/providers/theme_provider.dart';
import 'package:untitled27/providers/transaction_provider.dart';
import 'package:untitled27/data/local/local_storage.dart';
import 'package:untitled27/data/models/transaction.dart';

class FakeLocalStorage extends LocalStorage {
  @override
  List<Transaction> getTransactions() {
    return [];
  }

  @override
  Future<void> saveTransactions(
      List<Transaction> transactions,
      ) async {}

  @override
  Future<void> clearTransactions() async {}
}

void main() {
  testWidgets('Spendly запускается', (tester) async {
    final storage = FakeLocalStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),

          themeProvider.overrideWith(
                () => TestThemeNotifier(),
          ),
        ],
        child: const SpendlyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Spendly'), findsOneWidget);
  });
}

class TestThemeNotifier extends ThemeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  @override
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
  }
}