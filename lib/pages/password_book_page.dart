import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_toast.dart';

class PasswordBookPage extends StatefulWidget {
  const PasswordBookPage({super.key});

  @override
  State<PasswordBookPage> createState() => _PasswordBookPageState();
}

class _PasswordBookPageState extends State<PasswordBookPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<MapEntry<String, String>> _allEntries = [];
  List<MapEntry<String, String>> _filteredEntries = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEntries);
    _searchController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final allData = await _storage.readAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _allEntries = allData.entries.toList();
      _filterEntries();
    });
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = query.isEmpty
          ? _allEntries
          : _allEntries
              .where((e) => e.key.toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _savePassword() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    if (account.isEmpty || password.isEmpty) {
      CustomToast.warning(context, '账号和密码不能为空');
      return;
    }
    final navigator = Navigator.of(context);
    await _storage.write(key: account, value: password);
    _accountController.clear();
    _passwordController.clear();
    await _loadAccounts();
    if (!mounted) {
      return;
    }
    navigator.pop();
    CustomToast.success(context, '密码已保存');
  }

  void _showAddSheet() {
    _accountController.clear();
    _passwordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
            const Text('添加密码',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                  labelText: '账号', hintText: '例如：微信'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: '密码', hintText: '请输入密码'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _savePassword, child: const Text('保存')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordDetail(String account) async {
    final password = await _storage.read(key: account);
    if (!mounted || password == null) {
      return;
    }
    _showDetailSheet(account, password);
  }

  void _showDetailSheet(String account, String password) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24),
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
              Text(account,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(password,
                          style: const TextStyle(
                              fontSize: 16, letterSpacing: 2)),
                    ),
                      IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: password));
                        CustomToast.success(ctx, '密码已复制到剪贴板');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: password));
                        Navigator.pop(ctx);
                        CustomToast.success(context, '密码已复制');
                      },
                      child: const Text('复制密码'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePassword(String account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「$account」的密码吗？'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.delete(key: account);
      await _loadAccounts();
      if (mounted) {
        CustomToast.success(context, '密码已删除');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('密码本')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索账号...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 64,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.15)),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? '暂无保存的密码'
                              : '未找到匹配结果',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];
                      return Dismissible(
                        key: Key(entry.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          _deletePassword(entry.key);
                          return false;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.key,
                                  color: Color(0xFF3B82F6), size: 20),
                            ),
                            title: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text('••••••••',
                                style: TextStyle(
                                    color: theme
                                        .textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.3))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    size: 20,
                                    color: theme
                                        .textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                  onPressed: () =>
                                      _showPasswordDetail(entry.key),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    size: 18,
                                    color: theme
                                        .textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                  onPressed: () async {
                                    final pwd = await _storage.read(
                                        key: entry.key);
                                    if (!context.mounted || pwd == null) {
                                      return;
                                    }
                                    Clipboard.setData(
                                        ClipboardData(text: pwd));
                                    if (!context.mounted) {
                                      return;
                                    }
                                    // ignore: use_build_context_synchronously
                                    CustomToast.success(context, '密码已复制');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
