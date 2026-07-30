import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AppColors {
  static const mint = Color(0xFFBFF5D5);
  static const butter = Color(0xFFFFF5C9);
  static const peach = Color(0xFFFFE2CC);
  static const pink = Color(0xFFFFD4DE);
  static const lavender = Color(0xFFE9D8FF);
  static const plum = Color(0xFF735A9C);
  static const ink = Color(0xFF4D4361);
  static const green = Color(0xFF5E9C7D);
  static const coral = Color(0xFFD97883);
}

void main() => runApp(const SmartBudgetApp());

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Smart Budget',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.plum,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFE),
    ),
    home: const BudgetHome(),
  );
}

class Expense {
  const Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.time,
    this.isShared = false,
  });

  final String title;
  final double amount;
  final String category;
  final DateTime time;
  final bool isShared;
}

class ReceiptItem {
  const ReceiptItem(this.name, this.price);
  final String name;
  final double price;
}

class FinancialItem {
  const FinancialItem({required this.name, required this.amount});

  final String name;
  final double amount;
}

class BudgetDraft {
  const BudgetDraft({
    required this.name,
    required this.amount,
    required this.icon,
  });

  final String name;
  final double amount;
  final IconData icon;
}

class BudgetHome extends StatefulWidget {
  const BudgetHome({super.key});

  @override
  State<BudgetHome> createState() => _BudgetHomeState();
}

class _BudgetHomeState extends State<BudgetHome> {
  final SpeechToText _speech = SpeechToText();
  final List<Expense> _expenses = [
    Expense(
      title: 'Rent',
      amount: 1200,
      category: 'Home',
      time: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Expense(
      title: 'Groceries',
      amount: 72,
      category: 'Food',
      time: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      title: 'Train card',
      amount: 24,
      category: 'Transport',
      time: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  int _tab = 0;
  bool _speechReady = false;
  ValueNotifier<String>? _activeVoiceMessage;
  String _userName = 'Alex';

  final _limits = <String, double>{
    'Home': 1200,
    'Food': 500,
    'Transport': 300,
    'Shopping': 300,
    'Fun': 500,
    'Gifts': 150,
    'Subscriptions': 100,
    'Travel': 400,
    'Bills': 250,
    'Health': 150,
    'Education': 150,
  };
  final _budgetIcons = <String, IconData>{};
  final _assets = <FinancialItem>[
    const FinancialItem(name: 'KWSP', amount: 12000),
    const FinancialItem(name: 'Moomoo investment', amount: 6420),
  ];
  final _debts = <FinancialItem>[
    const FinancialItem(name: 'Car loan', amount: 2800),
    const FinancialItem(name: 'House loan', amount: 4000),
  ];
  final _savings = <FinancialItem>[];
  double _savingsGoal = 10000;

  double get _spent {
    final now = DateTime.now();
    return _expenses
        .where(
          (item) =>
              item.time.year == now.year && item.time.month == now.month,
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get _monthlyBudget => _limits.values.fold(0, (sum, item) => sum + item);
  double get _available => (_monthlyBudget - _spent).clamp(0, double.infinity);

  double _categoryTotal(String category) => _expenses
      .where((item) => item.category == category)
      .fold(0, (sum, item) => sum + item.amount);

  Future<void> _prepareSpeech() async {
    if (_speechReady) return;
    _speechReady = await _speech.initialize(
      onError: (error) {
        _activeVoiceMessage?.value = 'Voice error: ${error.errorMsg}';
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _activeVoiceMessage?.value =
              'Finished listening. Check the text below.';
        }
      },
    );
  }

  String _categoryFor(String words) {
    final text = words.toLowerCase();
    if (RegExp(
      r'llaollao|food|meal|lunch|dinner|coffee|tea|makan|makanan|kopi|teh|饭|餐|奶茶|咖啡|吃',
    ).hasMatch(text)) {
      return 'Food';
    }
    if (RegExp(r'grab|taxi|train|bus|petrol|parking|交通|车|油').hasMatch(text)) {
      return 'Transport';
    }
    if (RegExp(r'shirt|shoe|shop|shopping|mall|衣|裤|购物').hasMatch(text)) {
      return 'Shopping';
    }
    if (RegExp(r'gift|present|birthday|wedding|礼物|送礼').hasMatch(text)) {
      return 'Gifts';
    }
    if (RegExp(r'subscription|subscription|netflix|spotify|icloud|会员|订阅').hasMatch(text)) {
      return 'Subscriptions';
    }
    if (RegExp(r'travel|flight|hotel|holiday|trip|旅游|机票|酒店').hasMatch(text)) {
      return 'Travel';
    }
    if (RegExp(r'bill|utility|electric|water|internet|phone bill|账单|电费|水费|网费').hasMatch(text)) {
      return 'Bills';
    }
    if (RegExp(r'medicine|doctor|clinic|hospital|gym|health|药|医生|诊所|医院|健身').hasMatch(text)) {
      return 'Health';
    }
    if (RegExp(r'book|course|tuition|school|education|书|课程|学费').hasMatch(text)) {
      return 'Education';
    }
    if (RegExp(r'game|movie|concert|fun|电影|游戏').hasMatch(text)) {
      return 'Fun';
    }
    return 'Food';
  }

  IconData _suggestBudgetIcon(String name) {
    final text = name.toLowerCase();
    if (RegExp(r'gift|present|礼物').hasMatch(text)) return Icons.card_giftcard_rounded;
    if (RegExp(r'subscription|netflix|spotify|会员|订阅').hasMatch(text)) {
      return Icons.subscriptions_rounded;
    }
    if (RegExp(r'travel|flight|hotel|trip|旅游').hasMatch(text)) {
      return Icons.flight_takeoff_rounded;
    }
    if (RegExp(r'food|makan|meal|餐|食物').hasMatch(text)) return Icons.ramen_dining_rounded;
    if (RegExp(r'car|transport|petrol|交通|车').hasMatch(text)) {
      return Icons.directions_car_filled_rounded;
    }
    if (RegExp(r'health|clinic|doctor|药|医院').hasMatch(text)) return Icons.favorite_rounded;
    if (RegExp(r'book|school|course|教育|学习').hasMatch(text)) return Icons.menu_book_rounded;
    if (RegExp(r'home|rent|house|家|房').hasMatch(text)) return Icons.home_rounded;
    return Icons.category_rounded;
  }

  IconData _iconForBudget(String category) =>
      _budgetIcons[category] ?? _suggestBudgetIcon(category);

  ({double? amount, String title}) _parseExpense(String value) {
    final match = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(value);
    final amount = match == null ? null : double.tryParse(match.group(1)!);
    final title = value.replaceFirst(RegExp(r'(\d+(?:\.\d{1,2})?)'), '').trim();
    return (amount: amount, title: title.isEmpty ? 'New expense' : title);
  }

  List<({double amount, String title})> _parseMultipleExpenses(String value) {
    final parsed = <({double amount, String title})>[];
    final matches = RegExp(
      r'([^\d,，;；\n]+?)\s*(\d+(?:\.\d{1,2})?)',
    ).allMatches(value);
    for (final match in matches) {
      var title = match.group(1)!
          .replaceAll(RegExp(r'^[,，;；\s]+|[,，;；\s]+$'), '')
          .replaceFirst(
            RegExp(r'^(?:and|then|dan|然后)\s*', caseSensitive: false),
            '',
          )
          .trim();
      final amount = double.tryParse(match.group(2)!);
      if (title.toLowerCase() == 'rm') title = '';
      if (amount == null || amount <= 0 || title.isEmpty) continue;
      if (!RegExp(r'[A-Za-z\u4e00-\u9fff]').hasMatch(title)) continue;
      parsed.add((amount: amount, title: title));
    }
    if (parsed.isNotEmpty) return parsed;

    final single = _parseExpense(value);
    return single.amount == null || single.amount! <= 0
        ? []
        : [(amount: single.amount!, title: single.title)];
  }

  void _saveExpense({required String input, required String category}) {
    final parsed = _parseExpense(input);
    if (parsed.amount == null || parsed.amount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type an amount first, for example: 10 llaollao'),
        ),
      );
      return;
    }
    setState(
      () => _expenses.insert(
        0,
        Expense(
          title: parsed.title,
          amount: parsed.amount!,
          category: category,
          time: DateTime.now(),
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${money(parsed.amount!)} added to $category')),
    );
  }

  // ignore: unused_element
  Future<void> _showAddExpense({String initialText = ''}) async {
    final controller = TextEditingController(text: initialText);
    var category = _categoryFor(initialText);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final preview = _parseExpense(controller.text);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add an expense',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Write naturally, for example: “10 llaollao” or “RM 24 Grab”.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: initialText.isEmpty,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) =>
                      setSheetState(() => category = _categoryFor(value)),
                  decoration: const InputDecoration(
                    labelText: 'Amount and activity',
                    hintText: '10 llaollao',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _limits.keys
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => category = value ?? category),
                ),
                if (preview.amount != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Smart suggestion: ${money(preview.amount!)} for ${preview.title} → $category',
                    style: const TextStyle(
                      color: AppColors.plum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save expense'),
                    onPressed: () {
                      final value = controller.text;
                      Navigator.pop(sheetContext);
                      _saveExpense(input: value, category: category);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  void _saveAutomaticExpense(String input) {
    final parsed = _parseMultipleExpenses(input);
    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type an amount first, for example: 10 llaollao'),
        ),
      );
      return;
    }
    setState(() {
      _expenses.insertAll(
        0,
        parsed
            .map(
              (item) => Expense(
                title: item.title,
                amount: item.amount,
                category: _categoryFor(item.title),
                time: DateTime.now(),
              ),
            )
            .toList(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${parsed.length} expense${parsed.length == 1 ? '' : 's'} added to Activity',
        ),
      ),
    );
  }

  Future<void> _showAutomaticExpense({String initialText = ''}) async {
    final input = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _AddExpenseSheet(initialText: initialText, categoryFor: _categoryFor),
    );
    if (input != null && mounted) {
      _saveAutomaticExpense(input);
    }
  }

  Future<void> _showVoiceInput() async {
    final speechMessage = ValueNotifier<String>('Tap Start listening, then speak.');
    _activeVoiceMessage = speechMessage;
    await _prepareSpeech();
    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available on this device.',
            ),
          ),
        );
      }
      if (identical(_activeVoiceMessage, speechMessage)) {
        _activeVoiceMessage = null;
      }
      speechMessage.dispose();
      return;
    }
    if (!mounted) return;
    final availableLocales = await _speech.locales();
    String localeFor(List<String> prefixes) {
      for (final prefix in prefixes) {
        for (final item in availableLocales) {
          if (item.localeId.toLowerCase().startsWith(prefix)) {
            return item.localeId;
          }
        }
      }
      return '';
    }

    final languageChoices = <({String label, String localeId})>[
      (label: 'English (Malaysia)', localeId: localeFor(['en_my', 'en'])),
      // Keep Mandarin visible even when the phone has not downloaded its
      // language pack yet; Android will then report a useful service error.
      (label: 'Mandarin (中文)', localeId: localeFor(['zh']).isEmpty ? 'zh_CN' : localeFor(['zh'])),
      (label: 'Bahasa Melayu', localeId: localeFor(['ms'])),
    ].where((item) => item.localeId.isNotEmpty).toList();
    if (languageChoices.isEmpty) {
      final systemLocale = await _speech.systemLocale();
      languageChoices.add(
        (label: systemLocale?.name ?? 'Device language', localeId: systemLocale?.localeId ?? ''),
      );
    }
    if (!mounted) {
      speechMessage.dispose();
      return;
    }
    final controller = TextEditingController();
    var locale = languageChoices.first.localeId;
    var listening = false;
    final spokenWords = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voice expense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
                const Text('Say “10 llaollao”, “20 ringgit makan”, or “十块奶茶”.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: locale,
                decoration: const InputDecoration(
                  labelText: 'Recognition language',
                  border: OutlineInputBorder(),
                ),
                items: languageChoices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.localeId,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => locale = value ?? locale),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<String>(
                valueListenable: speechMessage,
                builder: (context, message, _) => Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.plum),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Recognized text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: Icon(
                  listening ? Icons.stop_circle_outlined : Icons.mic_rounded,
                ),
                label: Text(listening ? 'Stop listening' : 'Start listening'),
                onPressed: () async {
                  if (listening) {
                    await _speech.stop();
                    setSheetState(() => listening = false);
                  } else {
                    setSheetState(() => listening = true);
                    speechMessage.value = 'Listening… speak now.';
                    try {
                      // Some Android speech services keep the previous session
                      // open briefly. Reset it first to avoid error_busy.
                      await _speech.cancel();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 250),
                      );
                      await _speech.listen(
                        listenOptions: SpeechListenOptions(
                          localeId: locale,
                          partialResults: true,
                          listenFor: const Duration(seconds: 90),
                          pauseFor: const Duration(seconds: 12),
                        ),
                        onResult: (result) {
                          if (sheetContext.mounted) {
                            setSheetState(() {
                              controller.text = result.recognizedWords;
                              listening = !result.finalResult;
                            });
                          }
                          if (result.finalResult) {
                            speechMessage.value = 'Finished listening. Check the text below.';
                          }
                        },
                      );
                      Future<void>.delayed(const Duration(seconds: 6), () {
                        if (sheetContext.mounted &&
                            controller.text.trim().isEmpty &&
                            listening) {
                          speechMessage.value =
                              'No words received. Set a working speech recognizer in Android Settings, then try again.';
                        }
                      });
                    } catch (_) {
                      if (sheetContext.mounted) {
                        setSheetState(() => listening = false);
                      }
                      speechMessage.value =
                          'Could not start voice input. Check microphone permission.';
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _speech.stop();
                    if (!sheetContext.mounted) {
                      return;
                    }
                    Navigator.pop(sheetContext, controller.text);
                  },
                  child: const Text('Use this expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _speech.stop();
    controller.dispose();
    if (identical(_activeVoiceMessage, speechMessage)) {
      _activeVoiceMessage = null;
    }
    speechMessage.dispose();
    if (spokenWords != null && spokenWords.trim().isNotEmpty && mounted) {
      // Wait for the voice sheet to close before opening the Add Expense sheet.
      // Opening two bottom sheets at the same time caused the red assertion.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await _showAutomaticExpense(initialText: spokenWords);
    }
  }

  Future<void> _editExpense(int index) async {
    final updated = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditExpenseSheet(
        expense: _expenses[index],
        categories: _limits.keys.toList(),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _expenses[index] = updated);
    }
  }

  Future<void> _editBudget(String category) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoneyInputSheet(
        title: 'Edit $category budget',
        label: 'Monthly budget',
        initialAmount: _limits[category]!,
      ),
    );
    if (amount != null && mounted) {
      setState(() => _limits[category] = amount);
    }
  }

  Future<void> _addBudgetCategory() async {
    final budget = await showModalBottomSheet<BudgetDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddBudgetSheet(suggestIcon: _suggestBudgetIcon),
    );
    if (budget != null && mounted) {
      final name = budget.name.trim();
      if (_limits.containsKey(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That budget category already exists.')),
        );
        return;
      }
      setState(() {
        // Put new budgets at the top so the user sees the result immediately.
        final existing = Map<String, double>.from(_limits);
        _limits
          ..clear()
          ..[name] = budget.amount
          ..addAll(existing);
        _budgetIcons[name] = budget.icon;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name budget added.')),
      );
    }
  }

  Future<void> _showBudgetManager() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BudgetPickerSheet(limits: _limits),
    );
    if (category != null && mounted) await _editBudget(category);
  }

  Future<void> _deleteExpense(int index) async {
    final expense = _expenses[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove ${expense.title} (${money(expense.amount)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      setState(() => _expenses.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted.')),
      );
    }
  }

  Future<void> _editUserName() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NameInputSheet(initialName: _userName),
    );
    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() => _userName = name.trim());
    }
  }

  Future<void> _addFinancialItem({required bool asset}) async {
    final item = await showModalBottomSheet<FinancialItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FinancialItemSheet(
        title: asset ? 'Add an asset' : 'Add a debt',
        amountLabel: asset ? 'Asset value' : 'Amount owed',
      ),
    );
    if (item != null && mounted) {
      setState(() => (asset ? _assets : _debts).add(item));
    }
  }

  Future<void> _editFinancialItem({required bool asset, required int index}) async {
    final items = asset ? _assets : _debts;
    final updated = await showModalBottomSheet<FinancialItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FinancialItemSheet(
        title: asset ? 'Edit asset' : 'Edit debt',
        amountLabel: asset ? 'Asset value' : 'Amount owed',
        initialItem: items[index],
      ),
    );
    if (updated != null && mounted) {
      setState(() => items[index] = updated);
    }
  }

  Future<void> _editSavingsGoal() async {
    final goal = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoneyInputSheet(
        title: 'Yearly savings target',
        label: 'Target amount',
        initialAmount: _savingsGoal,
      ),
    );
    if (goal != null && mounted) setState(() => _savingsGoal = goal);
  }

  Future<void> _recordSaving() async {
    final saving = await showModalBottomSheet<FinancialItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FinancialItemSheet(
        title: 'Record savings',
        amountLabel: 'Amount saved',
        defaultName: 'Savings deposit',
      ),
    );
    if (saving != null && mounted) setState(() => _savings.insert(0, saving));
  }

  List<ReceiptItem> _itemsFromReceipt(RecognizedText recognized) {
    final lines = recognized.blocks
        .expand((block) => block.lines)
        .where((line) => line.text.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    final groups = <List<TextLine>>[];
    for (final line in lines) {
      final centre = (line.boundingBox.top + line.boundingBox.bottom) / 2;
      if (groups.isEmpty) {
        groups.add([line]);
        continue;
      }
      final lastGroup = groups.last;
      final lastCentre = lastGroup
              .map((item) => (item.boundingBox.top + item.boundingBox.bottom) / 2)
              .reduce((a, b) => a + b) /
          lastGroup.length;
      if ((centre - lastCentre).abs() <= 18) {
        lastGroup.add(line);
      } else {
        groups.add([line]);
      }
    }
    final rows = groups.map((group) {
      group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return group.map((line) => line.text).join(' ');
    }).toList();
    return _itemsFromReceiptRows(rows);
  }

  List<ReceiptItem> _itemsFromReceiptRows(List<String> rows) {
    // A receipt contains many numbers that are not expenses: invoice IDs,
    // dates, phone numbers, cash tendered and change. Only trust rows below a
    // product-table header and stop before the payment summary.
    final tableHeader = RegExp(
      r'description.*(?:qty|price|amount)|(?:qty|price|amount).*description',
      caseSensitive: false,
    );
    final summaryStart = RegExp(
      r'^(?:total\s*item|sub\s*total|total|round\s*amt|cash|change|payment|tax|discount|amount|paid|service\s*charge)',
      caseSensitive: false,
    );
    final metadata = RegExp(
      r'(?:invoice|receipt|date|time|cashier|tel|contact|sales|branch|company|return|exchange|thank)',
      caseSensitive: false,
    );
    // Require exactly two decimal places. This deliberately rejects long
    // reference numbers such as 260726194910386050178.
    final money = RegExp(r'(?<!\d)(\d{1,5}\.\d{2})(?!\d)');
    // Used for receipts that put an RM amount on every product line but do
    // not include column headings. Supports 8.40, 680.0 and 1,274.0.
    final lineAmount = RegExp(
      r'(?:RM\s*)?(\d{1,5}(?:,\d{3})*\.\d{1,2})\b',
      caseSensitive: false,
    );
    final items = <ReceiptItem>[];
    final pendingDescription = <String>[];
    var inProductTable = false;
    var headerWords = '';

    for (final rawLine in rows) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;

      if (!inProductTable) {
        headerWords = '$headerWords ${line.toLowerCase()}';
        if (headerWords.length > 120) {
          headerWords = line.toLowerCase();
        }
      }
      if (tableHeader.hasMatch(line) ||
          (headerWords.contains('description') &&
              headerWords.contains('qty') &&
              (headerWords.contains('price') || headerWords.contains('amount')))) {
        inProductTable = true;
        pendingDescription.clear();
        continue;
      }
      if (!inProductTable) continue;
      if (summaryStart.hasMatch(line)) break;
      if (metadata.hasMatch(line)) continue;

      final values = money.allMatches(line).toList();
      if (values.isEmpty) {
        if (RegExp(r'[A-Za-z]').hasMatch(line) && !RegExp(r'^[-=]+$').hasMatch(line)) {
          pendingDescription.add(line);
        }
        continue;
      }

      final price = double.tryParse(values.last.group(1)!);
      if (price == null || price <= 0 || price > 10000) continue;

      var name = line.substring(0, values.first.start);
      // Remove a leading item number and a trailing quantity, but retain the
      // item code because it is still more useful than an invented item name.
      name = name.replaceFirst(RegExp(r'^\s*\d+\s+'), '');
      name = name.replaceFirst(RegExp(r'\s+\d+\s*$'), '');
      name = [...pendingDescription, name]
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      pendingDescription.clear();

      if (name.length < 2 ||
          !RegExp(r'[A-Za-z]').hasMatch(name) ||
          metadata.hasMatch(name)) {
        continue;
      }
      final duplicate = items.any(
        (item) => item.name == name && item.price == price,
      );
      if (!duplicate) items.add(ReceiptItem(name, price));
    }
    if (items.isNotEmpty) return items;

    // Many minimart and café receipts have no Description/Qty/Price header.
    // Their product rows still consistently read as: item code + name + RM
    // amount. Read every such row, while deliberately ignoring payment and
    // receipt-information lines above and below the item section.
    final detectedItems = <ReceiptItem>[];
    for (final rawLine in rows) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      final lower = line.toLowerCase();
      if (line.isEmpty ||
          summaryStart.hasMatch(line) ||
          metadata.hasMatch(line) ||
          lower.contains('+rm') ||
          lower.contains('-rm')) {
        continue;
      }
      final values = lineAmount.allMatches(line).toList();
      if (values.isEmpty) continue;
      final price = double.tryParse(values.last.group(1)!.replaceAll(',', ''));
      if (price == null || price <= 0 || price > 10000) continue;
      var name = line.substring(0, values.first.start);
      name = name.replaceFirst(RegExp(r'^\s*\d{1,6}\s+'), '');
      name = name.replaceFirst(RegExp(r'\s+RM\s*$', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (name.length < 2 ||
          !RegExp(r'[A-Za-z\u4e00-\u9fff]').hasMatch(name)) {
        continue;
      }
      final duplicate = detectedItems.any(
        (item) => item.name == name && item.price == price,
      );
      if (!duplicate) detectedItems.add(ReceiptItem(name, price));
    }
    if (detectedItems.isNotEmpty) return detectedItems;

    // Some cameras/OCR engines return the column header as separate lines. In
    // that case, find a row with a repeated price (Price + Amount) and a real
    // product name before falling back to the receipt total.
    for (final rawLine in rows) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (summaryStart.hasMatch(line) || metadata.hasMatch(line)) continue;
      final values = money.allMatches(line).toList();
      if (values.length < 2) continue;
      final firstPrice = double.tryParse(values[values.length - 2].group(1)!);
      final price = double.tryParse(values.last.group(1)!);
      if (price == null || firstPrice == null || price <= 0 || price > 10000) {
        continue;
      }
      // A genuine product row normally has its unit price and line amount
      // beside each other. This avoids treating a date or reference code as an
      // expense when the table heading was missed.
      if ((price - firstPrice).abs() > 0.01) continue;
      var name = line.substring(0, values.first.start);
      name = name.replaceFirst(RegExp(r'^\s*\d+\s+'), '');
      name = name.replaceFirst(RegExp(r'\s+\d+\s*$'), '');
      if (name.length >= 2 && RegExp(r'[A-Za-z]').hasMatch(name)) {
        return [ReceiptItem(name, price)];
      }
    }

    // If the product description is unreadable, a real receipt total is still
    // safer and more helpful than showing RM0. It is deliberately labelled so
    // the user knows to check or edit it before confirming.
    for (final rawLine in rows.reversed) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      final lower = line.toLowerCase();
      if (!RegExp(r'^(?:grand\s+)?total\b', caseSensitive: false).hasMatch(line) ||
          lower.contains('total item') ||
          lower.contains('sub total')) {
        continue;
      }
      final values = lineAmount.allMatches(line).toList();
      if (values.isEmpty) continue;
      final total = double.tryParse(values.last.group(1)!.replaceAll(',', ''));
      if (total != null && total > 0 && total <= 10000) {
        return [ReceiptItem('Receipt total — please check', total)];
      }
    }
    return [const ReceiptItem('Edit this item', 0)];
  }

  Future<void> _scanReceipt() async {
    var processingDialogOpen = false;
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add a receipt',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Take a new photo or choose a receipt you already saved.'),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
      if (source == null || !mounted) return;
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 100,
      );
      if (photo == null || !mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      processingDialogOpen = true;
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(photo.path),
      );
      await recognizer.close();
      if (!mounted) return;
      Navigator.of(context).pop();
      processingDialogOpen = false;
      final chosen = await showModalBottomSheet<List<_ReceiptReviewItem>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ReceiptReviewSheet(
          imagePath: photo.path,
          items: _itemsFromReceipt(recognized),
        ),
      );
      if (chosen == null || !mounted) return;
      final additions = chosen
          .where(
            (item) =>
                item.selected && item.price > 0 && item.name.trim().isNotEmpty,
          )
          .map(
            (item) => Expense(
              title: item.name.trim(),
              amount: item.price / item.splitWith,
              category: _categoryFor(item.name),
              time: DateTime.now(),
              isShared: item.splitWith > 1,
            ),
          )
          .toList();
      if (additions.isEmpty) return;
      setState(() => _expenses.insertAll(0, additions));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${additions.length} receipt expenses added to Activity',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        if (processingDialogOpen) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read this receipt. Try taking a clearer photo.',
            ),
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _showReceiptReview() async {
    const items = [
      ReceiptItem('Iced latte', 8.50),
      ReceiptItem('Tote bag', 24),
      ReceiptItem('Phone case', 18),
      ReceiptItem('Dessert', 12),
    ];
    final selected = <bool>[true, false, true, true];
    var shareDessert = true;
    var splitWith = 2;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedTotal = List.generate(items.length, (index) => index)
              .where((index) => selected[index])
              .fold(
                0.0,
                (sum, index) =>
                    sum +
                    (items[index].name == 'Dessert' && shareDessert
                        ? items[index].price / splitWith
                        : items[index].price),
              );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review receipt',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Select only the items that belong to you.'),
                const SizedBox(height: 10),
                ...List.generate(
                  items.length,
                  (index) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected[index],
                    onChanged: (value) =>
                        setSheetState(() => selected[index] = value ?? false),
                    title: Text(items[index].name),
                    subtitle: items[index].name == 'Dessert' && shareDessert
                        ? Text('Shared by $splitWith people')
                        : null,
                    secondary: Text(
                      money(items[index].price),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: shareDessert,
                  onChanged: (value) =>
                      setSheetState(() => shareDessert = value),
                  title: const Text('Split the dessert'),
                  subtitle: const Text('Only your share is recorded'),
                ),
                if (shareDessert)
                  DropdownButtonFormField<int>(
                    initialValue: splitWith,
                    decoration: const InputDecoration(
                      labelText: 'Split with',
                      border: OutlineInputBorder(),
                    ),
                    items: const [2, 3, 4, 5]
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count people'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => splitWith = value ?? splitWith),
                  ),
                const SizedBox(height: 14),
                Text(
                  'Your total: ${money(selectedTotal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final additions = <Expense>[];
                      for (var i = 0; i < items.length; i++) {
                        if (!selected[i]) {
                          continue;
                        }
                        final isShared =
                            items[i].name == 'Dessert' && shareDessert;
                        additions.add(
                          Expense(
                            title: items[i].name,
                            amount: isShared
                                ? items[i].price / splitWith
                                : items[i].price,
                            category: _categoryFor(items[i].name),
                            time: DateTime.now(),
                            isShared: isShared,
                          ),
                        );
                      }
                      setState(() => _expenses.insertAll(0, additions));
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt items added to Activity'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Confirm my expenses'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          _Dashboard(
            userName: _userName,
            available: _available,
            spent: _spent,
            monthlyBudget: _monthlyBudget,
            limits: _limits,
            iconForBudget: _iconForBudget,
            categoryTotal: _categoryTotal,
            onAdd: _showAutomaticExpense,
            onVoice: _showVoiceInput,
            onReceipt: _scanReceipt,
            onEditBudget: _editBudget,
            onAddBudget: _addBudgetCategory,
            onEditName: _editUserName,
            onEditBudgets: _showBudgetManager,
          ),
          _ActivityPage(
            expenses: _expenses,
            onEdit: _editExpense,
            onDelete: _deleteExpense,
          ),
          _InsightsPage(
            expenses: _expenses,
            monthlyBudget: _monthlyBudget,
            categoryTotal: _categoryTotal,
          ),
          _WealthPage(
            assets: _assets,
            debts: _debts,
            savings: _savings,
            savingsGoal: _savingsGoal,
            onAddAsset: () => _addFinancialItem(asset: true),
            onAddDebt: () => _addFinancialItem(asset: false),
            onEditAsset: (index) => _editFinancialItem(asset: true, index: index),
            onEditDebt: (index) => _editFinancialItem(asset: false, index: index),
            onEditSavingsGoal: _editSavingsGoal,
            onRecordSaving: _recordSaving,
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Insights',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Wealth',
        ),
      ],
    ),
  );
}

class _ReceiptReviewItem {
  _ReceiptReviewItem({required this.name, required this.price});

  String name;
  double price;
  bool selected = true;
  int splitWith = 1;
}

class _ReceiptReviewSheet extends StatefulWidget {
  const _ReceiptReviewSheet({required this.imagePath, required this.items});

  final String imagePath;
  final List<ReceiptItem> items;

  @override
  State<_ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends State<_ReceiptReviewSheet> {
  late final List<_ReceiptReviewItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items
        .map((item) => _ReceiptReviewItem(name: item.name, price: item.price))
        .toList();
  }

  double get _total => _items
      .where((item) => item.selected)
      .fold(0, (sum, item) => sum + item.price / item.splitWith);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Review scanned receipt',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Only product rows are pre-filled. Edit any mistake, or add an item if needed.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(widget.imagePath),
            height: 112,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: item.selected,
                        onChanged: (value) =>
                            setState(() => item.selected = value ?? false),
                        title: const Text('This is my expense'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.name,
                              onChanged: (value) => item.name = value,
                              decoration: const InputDecoration(
                                labelText: 'Item name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 108,
                            child: TextFormField(
                              initialValue: item.price.toStringAsFixed(2),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) =>
                                  item.price = double.tryParse(value) ?? 0,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                prefixText: 'RM ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: item.splitWith,
                        decoration: const InputDecoration(
                          labelText: 'Share this item with',
                          border: OutlineInputBorder(),
                        ),
                        items: const [1, 2, 3, 4, 5]
                            .map(
                              (count) => DropdownMenuItem(
                                value: count,
                                child: Text(
                                  count == 1 ? 'Just me' : '$count people',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => item.splitWith = value ?? 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(
            () => _items.add(_ReceiptReviewItem(name: '', price: 0)),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add an item'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your total: ${money(_total)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, _items),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirm my expenses'),
          ),
        ),
      ],
    ),
  );
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.initialText,
    required this.categoryFor,
  });

  final String initialText;
  final String Function(String) categoryFor;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({double? amount, String title}) get _preview {
    final match = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(_controller.text);
    final amount = match == null ? null : double.tryParse(match.group(1)!);
    final title = _controller.text
        .replaceFirst(RegExp(r'(\d+(?:\.\d{1,2})?)'), '')
        .trim();
    return (amount: amount, title: title.isEmpty ? 'New expense' : title);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final category = widget.categoryFor(_controller.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add an expense',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Enter an amount and activity. Example: 10 food.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: widget.initialText.isEmpty,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Enter amount and activity',
              hintText: '10 food',
              prefixIcon: Icon(Icons.edit_note_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.plum,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preview.amount == null
                        ? 'Smart category will appear here.'
                        : 'Auto-categorized as $category',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (preview.amount != null) ...[
            const SizedBox(height: 10),
            Text('${money(preview.amount!)} for ${preview.title}'),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (preview.amount == null || preview.amount! <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please type an amount first.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, _controller.text);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({required this.expense, required this.categories});

  final Expense expense;
  final List<String> categories;

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _category = widget.expense.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit expense',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Correct the activity, amount, or category.'),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Activity',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'RM ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: widget.categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value ?? _category),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save changes'),
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              final title = _titleController.text.trim();
              if (amount == null || amount <= 0 || title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter an activity and a valid amount.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                Expense(
                  title: title,
                  amount: amount,
                  category: _category,
                  time: widget.expense.time,
                  isShared: widget.expense.isShared,
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _MoneyInputSheet extends StatefulWidget {
  const _MoneyInputSheet({
    required this.title,
    required this.label,
    required this.initialAmount,
  });

  final String title;
  final String label;
  final double initialAmount;

  @override
  State<_MoneyInputSheet> createState() => _MoneyInputSheetState();
}

class _NameInputSheet extends StatefulWidget {
  const _NameInputSheet({required this.initialName});

  final String initialName;

  @override
  State<_NameInputSheet> createState() => _NameInputSheetState();
}

class _NameInputSheetState extends State<_NameInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What should we call you?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'e.g. Aisha',
            prefixIcon: Icon(Icons.face_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Save name'),
          ),
        ),
      ],
    ),
  );
}

class _MoneyInputSheetState extends State<_MoneyInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixText: 'RM ',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final amount = double.tryParse(_controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount.')),
                );
                return;
              }
              Navigator.pop(context, amount);
            },
            child: const Text('Save'),
          ),
        ),
      ],
    ),
  );
}

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({required this.suggestIcon});

  final IconData Function(String) suggestIcon;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  var _selectedIcon = Icons.category_rounded;
  var _iconChosenManually = false;

  static const _iconOptions = [
    Icons.card_giftcard_rounded,
    Icons.subscriptions_rounded,
    Icons.flight_takeoff_rounded,
    Icons.favorite_rounded,
    Icons.menu_book_rounded,
    Icons.ramen_dining_rounded,
    Icons.directions_car_filled_rounded,
    Icons.home_rounded,
    Icons.shopping_bag_rounded,
    Icons.movie_rounded,
    Icons.savings_rounded,
    Icons.pets_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a monthly budget',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('We suggest an icon from the name, or you can choose one.'),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          autofocus: true,
          onChanged: (value) {
            if (!_iconChosenManually) {
              setState(() => _selectedIcon = widget.suggestIcon(value));
            }
          },
          decoration: const InputDecoration(
            labelText: 'Budget category',
            hintText: 'e.g. Gifts',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly budget',
            prefixText: 'RM ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Choose an icon', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iconOptions
              .map(
                (icon) => ChoiceChip(
                  label: Icon(icon, color: AppColors.plum),
                  selected: _selectedIcon == icon,
                  selectedColor: AppColors.pink,
                  onSelected: (_) => setState(() {
                    _selectedIcon = icon;
                    _iconChosenManually = true;
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Add budget'),
            onPressed: () {
              final name = _nameController.text.trim();
              final amount = double.tryParse(_amountController.text);
              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a category and valid budget.')),
                );
                return;
              }
              Navigator.pop(
                context,
                BudgetDraft(name: name, amount: amount, icon: _selectedIcon),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _BudgetPickerSheet extends StatelessWidget {
  const _BudgetPickerSheet({required this.limits});

  final Map<String, double> limits;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 430,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Text(
            'Edit monthly budgets',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Choose a category to change its budget.'),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: limits.entries
                  .map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(entry.key),
                      trailing: Text(money(entry.value)),
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FinancialItemSheet extends StatefulWidget {
  const _FinancialItemSheet({
    required this.title,
    required this.amountLabel,
    this.initialItem,
    this.defaultName,
  });

  final String title;
  final String amountLabel;
  final FinancialItem? initialItem;
  final String? defaultName;

  @override
  State<_FinancialItemSheet> createState() => _FinancialItemSheetState();
}

class _FinancialItemSheetState extends State<_FinancialItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? widget.defaultName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialItem?.amount.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          autofocus: widget.initialItem == null,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. KWSP or Car loan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.amountLabel,
            prefixText: 'RM ',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final amount = double.tryParse(_amountController.text);
              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a name and valid amount.')),
                );
                return;
              }
              Navigator.pop(context, FinancialItem(name: name, amount: amount));
            },
            child: const Text('Save'),
          ),
        ),
      ],
    ),
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.userName,
    required this.available,
    required this.spent,
    required this.monthlyBudget,
    required this.limits,
    required this.iconForBudget,
    required this.categoryTotal,
    required this.onAdd,
    required this.onVoice,
    required this.onReceipt,
    required this.onEditBudget,
    required this.onAddBudget,
    required this.onEditName,
    required this.onEditBudgets,
  });
  final String userName;
  final double available;
  final double spent;
  final double monthlyBudget;
  final Map<String, double> limits;
  final IconData Function(String) iconForBudget;
  final double Function(String) categoryTotal;
  final VoidCallback onAdd;
  final VoidCallback onVoice;
  final VoidCallback onReceipt;
  final ValueChanged<String> onEditBudget;
  final VoidCallback onAddBudget;
  final VoidCallback onEditName;
  final VoidCallback onEditBudgets;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.pink,
              child: Text(
                userName.isEmpty ? 'A' : userName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, $userName',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text('July 2026', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            IconButton(
              onPressed: onEditName,
              tooltip: 'Edit your name',
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _BalanceCard(
          available: available,
          spent: spent,
          monthlyBudget: monthlyBudget,
          onEditBudgets: onEditBudgets,
        ),
        const SizedBox(height: 24),
        const Text(
          'Quick actions',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_rounded,
                label: 'Add expense',
                onTap: onAdd,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.document_scanner_outlined,
                label: 'Scan receipt',
                onTap: onReceipt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.mic_none_rounded,
                label: 'Voice input',
                onTap: onVoice,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Monthly budgets',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onAddBudget,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...limits.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BudgetItem(
              icon: iconForBudget(entry.key),
              name: entry.key,
              spent: categoryTotal(entry.key),
              limit: entry.value,
              onTap: () => onEditBudget(entry.key),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Smart insight',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.butter,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.plum),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dining is down 18%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keeping this pace could free up another RM 52 this month.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.available,
    required this.spent,
    required this.monthlyBudget,
    required this.onEditBudgets,
  });

  final double available;
  final double spent;
  final double monthlyBudget;
  final VoidCallback onEditBudgets;

  @override
  Widget build(BuildContext context) {
    final progress = monthlyBudget == 0
        ? 0.0
        : (spent / monthlyBudget).clamp(0, 1).toDouble();
    return Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.mint, AppColors.peach],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You can still spend this month',
          style: TextStyle(color: AppColors.ink),
        ),
        const SizedBox(height: 5),
        Text(
          money(available),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 38,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${money(spent)} spent of ${money(monthlyBudget)} budget',
          style: const TextStyle(color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white70,
            valueColor: const AlwaysStoppedAnimation(AppColors.plum),
          ),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: Colors.white70),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: AppColors.plum),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Monthly budget  ${money(monthlyBudget)}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEditBudgets,
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text('Edit'),
            ),
          ],
        ),
      ],
    ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: AppColors.plum),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BudgetItem extends StatelessWidget {
  const _BudgetItem({
    required this.icon,
    required this.name,
    required this.spent,
    required this.limit,
    required this.onTap,
  });
  final IconData icon;
  final String name;
  final double spent;
  final double limit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final progress = (spent / limit).clamp(0, 1).toDouble();
    final color = progress >= 1
        ? AppColors.coral
        : progress >= .85
        ? const Color(0xFFFFA245)
        : AppColors.plum;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${money(spent)} / ${money(limit)}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: color.withValues(alpha: .13),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 17, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Expense> expenses;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    children: [
      const Text(
        'Activity',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        '${expenses.length} recorded expenses',
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      ...expenses.asMap().entries.map((entry) {
        final index = entry.key;
        final expense = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onEdit(index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.lavender,
                      foregroundColor: AppColors.plum,
                      child: Icon(_activityIcon(expense.category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${expense.category}${expense.isShared ? ' · Shared item' : ''}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(expense.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 1),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete expense',
                          onPressed: () => onDelete(index),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ],
  );
}

class _InsightsPage extends StatelessWidget {
  const _InsightsPage({
    required this.expenses,
    required this.monthlyBudget,
    required this.categoryTotal,
  });

  final List<Expense> expenses;
  final double monthlyBudget;
  final double Function(String) categoryTotal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthly = expenses
        .where((item) => item.time.year == now.year && item.time.month == now.month)
        .toList();
    final annual = expenses.where((item) => item.time.year == now.year).toList();
    final monthSpent = monthly.fold(0.0, (sum, item) => sum + item.amount);
    final yearSpent = annual.fold(0.0, (sum, item) => sum + item.amount);
    final byCategory = <String, double>{};
    for (final expense in monthly) {
      byCategory.update(
        expense.category,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final ordered = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordered.isEmpty ? null : ordered.first;
    final remaining =
        (monthlyBudget - monthSpent).clamp(0, double.infinity).toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Insights',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'A gentle summary of your spending habits.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _reportCard(
          color: AppColors.butter,
          icon: Icons.calendar_month_rounded,
          title: 'Monthly report',
          headline: '${money(monthSpent)} spent this month',
          body: top == null
              ? 'Add an expense to start your monthly report.'
              : '${top.key} is your largest category at ${money(top.value)}. You still have ${money(remaining)} within your monthly budget.',
        ),
        const SizedBox(height: 16),
        if (ordered.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This month by category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...ordered.take(5).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          money(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _reportCard(
          color: AppColors.lavender,
          icon: Icons.auto_graph_rounded,
          title: 'Yearly report',
          headline: '${money(yearSpent)} recorded in ${now.year}',
          body: annual.isEmpty
              ? 'Your yearly report will grow as you record expenses.'
              : '${annual.length} expenses have been recorded this year. Keep adding expenses and savings to build a clearer long-term picture.',
        ),
      ],
    );
  }

  Widget _reportCard({
    required Color color,
    required IconData icon,
    required String title,
    required String headline,
    required String body,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.plum),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          headline,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: AppColors.ink)),
      ],
    ),
  );
}

class _WealthPage extends StatelessWidget {
  const _WealthPage({
    required this.assets,
    required this.debts,
    required this.savings,
    required this.savingsGoal,
    required this.onAddAsset,
    required this.onAddDebt,
    required this.onEditAsset,
    required this.onEditDebt,
    required this.onEditSavingsGoal,
    required this.onRecordSaving,
  });

  final List<FinancialItem> assets;
  final List<FinancialItem> debts;
  final List<FinancialItem> savings;
  final double savingsGoal;
  final VoidCallback onAddAsset;
  final VoidCallback onAddDebt;
  final ValueChanged<int> onEditAsset;
  final ValueChanged<int> onEditDebt;
  final VoidCallback onEditSavingsGoal;
  final VoidCallback onRecordSaving;

  double get _assetsTotal => assets.fold(0, (sum, item) => sum + item.amount);
  double get _debtsTotal => debts.fold(0, (sum, item) => sum + item.amount);
  double get _savingsTotal => savings.fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    final progress = savingsGoal == 0
        ? 0.0
        : (_savingsTotal / savingsGoal).clamp(0, 1).toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Financial position',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _summaryRow(
                Icons.trending_up_rounded,
                'Assets',
                money(_assetsTotal),
                AppColors.green,
              ),
              const Divider(height: 26),
              _summaryRow(
                Icons.credit_card_rounded,
                'Debts',
                '-${money(_debtsTotal)}',
                AppColors.coral,
              ),
              const Divider(height: 26),
              _summaryRow(
                Icons.account_balance_rounded,
                'Net worth',
                money(_assetsTotal - _debtsTotal),
                AppColors.plum,
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _financialSection(
          title: 'Assets',
          icon: Icons.add_circle_outline_rounded,
          actionLabel: 'Add asset',
          items: assets,
          color: AppColors.green,
          onAdd: onAddAsset,
          onEdit: onEditAsset,
        ),
        const SizedBox(height: 20),
        _financialSection(
          title: 'Debts',
          icon: Icons.add_circle_outline_rounded,
          actionLabel: 'Add debt',
          items: debts,
          color: AppColors.coral,
          onAdd: onAddDebt,
          onEdit: onEditDebt,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yearly savings goal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: onEditSavingsGoal,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit savings target',
                  ),
                ],
              ),
              Text(
                '${money(_savingsTotal)} saved of ${money(savingsGoal)}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white70,
                  valueColor: const AlwaysStoppedAnimation(AppColors.plum),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${money((savingsGoal - _savingsTotal).clamp(0, double.infinity))} to go',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRecordSaving,
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Record savings'),
              ),
              if (savings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...savings.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(item.name)),
                        Text(money(item.amount)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String amount,
    Color color, {
    bool emphasize = false,
  }) => Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          color: color,
          fontSize: emphasize ? 20 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _financialSection({
    required String title,
    required IconData icon,
    required String actionLabel,
    required List<FinancialItem> items,
    required Color color,
    required VoidCallback onAdd,
    required ValueChanged<int> onEdit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(icon, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
      ...items.asMap().entries.map(
        (entry) => Card(
          child: ListTile(
            leading: Icon(
              title == 'Assets' ? Icons.account_balance_wallet_outlined : Icons.credit_score_outlined,
              color: color,
            ),
            title: Text(entry.value.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  money(entry.value.amount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 18),
              ],
            ),
            onTap: () => onEdit(entry.key),
          ),
        ),
      ),
    ],
  );
}

IconData _activityIcon(String category) => switch (category) {
  'Home' => Icons.home_rounded,
  'Food' => Icons.ramen_dining_rounded,
  'Transport' => Icons.directions_car_filled_rounded,
  'Shopping' => Icons.shopping_bag_rounded,
  'Fun' => Icons.movie_rounded,
  'Gifts' => Icons.card_giftcard_rounded,
  'Subscriptions' => Icons.subscriptions_rounded,
  'Travel' => Icons.flight_takeoff_rounded,
  'Bills' => Icons.receipt_long_rounded,
  'Health' => Icons.favorite_rounded,
  'Education' => Icons.menu_book_rounded,
  _ => Icons.category_rounded,
};

String money(double value) =>
    'RM ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
