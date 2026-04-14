import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/points_service.dart';

class SettingsManagementPage extends StatefulWidget {
  const SettingsManagementPage({super.key});

  @override
  State<SettingsManagementPage> createState() => _SettingsManagementPageState();
}

class _SettingsManagementPageState extends State<SettingsManagementPage> {
  final _pointsService = PointsService();

  List<UserProfile> _profiles = [];
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    try {
      final data = await _pointsService.fetchAllProfiles();
      if (!mounted) return;
      setState(() => _profiles = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载用户失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePoints(UserProfile profile, {required bool increase}) async {
    String input = '';
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${increase ? '加' : '减'}积分 · ${profile.nickname}'),
        content: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '积分数',
            hintText: '请输入正整数',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(input.trim());
              if (parsed == null || parsed <= 0) return;
              Navigator.of(dialogContext).pop(parsed);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (amount == null) return;


    setState(() => _updating = true);
    try {
      final newPoints = await _pointsService.changePoints(
        userId: profile.id,
        delta: increase ? amount : -amount,
      );
      if (!mounted) return;
      setState(() {
        _profiles = _profiles
            .map((p) => p.id == profile.id
                ? UserProfile(
                    id: p.id,
                    nickname: p.nickname,
                    role: p.role,
                    points: newPoints,
                  )
                : p)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作成功，当前积分：$newPoints')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_profiles.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 120, 12, 12),
          children: const [
            Center(child: Text('暂无用户数据')),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: _profiles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final profile = _profiles[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('身份：${profile.role}'),
                    SelectableText('用户ID：${profile.id}'),
                    const SizedBox(height: 6),
                    Text(
                      '积分：${profile.points}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _updating
                              ? null
                              : () => _changePoints(profile, increase: false),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('减积分'),
                        ),
                        FilledButton.icon(
                          onPressed: _updating
                              ? null
                              : () => _changePoints(profile, increase: true),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('加积分'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置管理')),
      body: SafeArea(child: body),
    );
  }
}
