import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/custom_toast.dart';

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  late Database _database;
  List<Map<String, dynamic>> _records = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'accounting_v2.db');
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, category TEXT, amount REAL, note TEXT, timestamp INTEGER)',
        );
      },
    );
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    final start =
        DateTime(_selectedYear, _selectedMonth, 1).millisecondsSinceEpoch;
    final end = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch;
    final list = await _database.query(
      'records',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start, end],
      orderBy: 'timestamp DESC',
    );
    if (!mounted) {
      return;
    }
    setState(() => _records = list);
  }

  Future<void> _deleteRecord(int id) async {
    await _database.delete('records', where: 'id = ?', whereArgs: [id]);
    await _loadRecords();
  }

  double _total(String type) {
    final list = _records.where((r) => r['type'] == type);
    if (list.isEmpty) {
      return 0;
    }
    return list
        .map((e) => e['amount'] as double)
        .fold(0.0, (a, b) => a + b);
  }

  Map<String, double> _categoryTotals(String type) {
    final map = <String, double>{};
    for (final r in _records.where((r) => r['type'] == type)) {
      final cat = r['category'] as String? ?? '其他';
      map[cat] = (map[cat] ?? 0) + (r['amount'] as double);
    }
    return map;
  }

  void _changeMonth(int delta) {
    final now = DateTime.now();
    int newMonth = _selectedMonth + delta;
    int newYear = _selectedYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    if (newYear > now.year ||
        (newYear == now.year && newMonth > now.month)) {
      return;
    }
    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = _total('收入');
    final expense = _total('支出');
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账工具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => _showStatistics(context),
            tooltip: '统计',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecord(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1)),
                Text('$_selectedYear年$_selectedMonth月',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1)),
              ],
            ),
            const SizedBox(height: 16),
            _buildBalanceCard(theme, balance, income, expense),
            const SizedBox(height: 24),
            if (_records.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Text('本月暂无记录',
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4))),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                itemBuilder: (context, index) =>
                    _buildRecordItem(theme, _records[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      ThemeData theme, double balance, double income, double expense) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('本月结余',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14)),
          const SizedBox(height: 8),
          Text('¥${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _balanceDetail(
                      '收入', income, Colors.greenAccent)),
              Container(
                  width: 1, height: 36, color: Colors.white24),
              Expanded(
                  child: _balanceDetail(
                      '支出', expense, Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceDetail(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13)),
        const SizedBox(height: 4),
        Text('¥${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRecordItem(
      ThemeData theme, Map<String, dynamic> record) {
    final type = record['type'] as String;
    final category = record['category'] as String? ?? '其他';
    final amount = record['amount'] as double;
    final note = record['note'] as String?;
    final timestamp = record['timestamp'] as int;
    final id = record['id'] as int;
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate =
        DateFormat('MM/dd HH:mm').format(dateTime);
    final isIncome = type == '收入';
    final categories =
        isIncome ? incomeCategories : expenseCategories;
    final catInfo = categories.firstWhere(
        (c) => c.name == category,
        orElse: () => categories.last);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key('record_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12)),
        child:
            const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条记录吗？'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteRecord(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(catInfo.icon,
                  color: catInfo.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      note?.isNotEmpty == true
                          ? note!
                          : category,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('$category · $formattedDate',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme
                              .textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.4))),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}¥${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecord(BuildContext context) {
    String selectedType = '支出';
    String selectedCategory = '餐饮';
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final cats = selectedType == '收入'
              ? incomeCategories
              : expenseCategories;
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('添加记录',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModal(() {
                          selectedType = '支出';
                          selectedCategory =
                              expenseCategories.first.name;
                        }),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == '支出'
                                ? const Color(0xFFEF4444)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selectedType == '支出'
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey),
                          ),
                          child: Center(
                            child: Text('支出',
                                style: TextStyle(
                                    color: selectedType == '支出'
                                        ? Colors.white
                                        : null,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModal(() {
                          selectedType = '收入';
                          selectedCategory =
                              incomeCategories.first.name;
                        }),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == '收入'
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selectedType == '收入'
                                    ? const Color(0xFF10B981)
                                    : Colors.grey),
                          ),
                          child: Center(
                            child: Text('收入',
                                style: TextStyle(
                                    color: selectedType == '收入'
                                        ? Colors.white
                                        : null,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      final selected =
                          cat.name == selectedCategory;
                      return GestureDetector(
                        onTap: () => setModal(
                            () => selectedCategory = cat.name),
                        child: Container(
                          width: 68,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? cat.color
                                    : Colors.grey
                                        .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(cat.icon,
                                  color: cat.color, size: 22),
                              const SizedBox(height: 4),
                              Text(cat.name,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? cat.color
                                          : null,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration: const InputDecoration(
                      labelText: '金额', hintText: '0.00'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      hintText: '例如：午餐'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amountText =
                          amountController.text.trim();
                      if (amountText.isEmpty) {
                        CustomToast.warning(ctx, '请输入金额');
                        return;
                      }
                      final amount =
                          double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        CustomToast.warning(ctx, '请输入有效金额');
                        return;
                      }
                      final navigator = Navigator.of(ctx);
                      await _database.insert('records', {
                        'type': selectedType,
                        'category': selectedCategory,
                        'amount': amount,
                        'note':
                            noteController.text.trim(),
                        'timestamp': DateTime.now()
                            .millisecondsSinceEpoch,
                      });
                      if (!mounted) {
                        return;
                      }
                      navigator.pop();
                      await _loadRecords();
                    },
                    child: const Text('确认添加'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final expByCat = _categoryTotals('支出');
    final incByCat = _categoryTotals('收入');
    final totalExp = _total('支出');
    final totalInc = _total('收入');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                  '$_selectedYear年$_selectedMonth月 统计',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              if (expByCat.isNotEmpty) ...[
                const Text('支出分类',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...expByCat.entries.map((e) {
                  final pct = totalExp > 0
                      ? e.value / totalExp * 100
                      : 0.0;
                  final cat = expenseCategories.firstWhere(
                      (c) => c.name == e.key,
                      orElse: () => expenseCategories.last);
                  return _statItem(theme, cat, e.value, pct);
                }),
                const SizedBox(height: 24),
              ],
              if (incByCat.isNotEmpty) ...[
                const Text('收入分类',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...incByCat.entries.map((e) {
                  final pct = totalInc > 0
                      ? e.value / totalInc * 100
                      : 0.0;
                  final cat = incomeCategories.firstWhere(
                      (c) => c.name == e.key,
                      orElse: () => incomeCategories.last);
                  return _statItem(theme, cat, e.value, pct);
                }),
              ],
              if (expByCat.isEmpty && incByCat.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('暂无数据',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(
      ThemeData theme, CategoryInfo cat, double amount, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    Text('¥${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor:
                        theme.brightness == Brightness.dark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                    color: cat.color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
