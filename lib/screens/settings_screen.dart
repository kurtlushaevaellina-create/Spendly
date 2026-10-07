import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          const ListTile(
            leading: Icon(Icons.currency_ruble),
            title: Text('Валюта'),
            subtitle: Text('Российский рубль'),
            trailing: Text(
              '₽',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оформление',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_brightness),
                      label: Text('Система'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Светлая'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Тёмная'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(themeProvider.notifier)
                        .setTheme(selection.first);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Удалить все операции'),
            subtitle: const Text(
              'Удаление всех сохранённых данных',
            ),
            onTap: () {
              _showClearConfirmation(
                context,
                ref,
              );
            },
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('О приложении'),
            subtitle: Text(
              'Spendly — приложение для учёта личных финансов',
            ),
          ),

          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Версия'),
            subtitle: Text('1.0.0'),
          ),

          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Хранение данных'),
            subtitle: Text(
              'Данные хранятся локально на устройстве',
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Spendly',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showClearConfirmation(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Удалить все операции?',
          ),
          content: const Text(
            'Все доходы и расходы будут удалены. '
                'Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(transactionProvider.notifier)
        .clearTransactions();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все операции удалены'),
      ),
    );
  }
}