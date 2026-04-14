import 'package:flutter/material.dart';

import '../../features/home/home_page.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nicknameController = TextEditingController();
  final _authService = AuthService();

  String _role = '我';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _authService.ensureSignedIn();
      final profile = await _authService.fetchMyProfile();
      if (!mounted) return;
      if (profile != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(profile: profile)),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('初始化失败：$e')),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入昵称')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await _authService.saveProfile(
        nickname: nickname,
        role: _role,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(profile: profile)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F7), Color(0xFFFFFBFD)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE7F2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.cake_outlined, color: Color(0xFFB23D78), size: 34),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '独家御膳房',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '甜甜的每一餐，都值得认真对待',
                        style: TextStyle(color: Color(0xFF5C4A56)),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: '昵称',
                          hintText: '请输入你的昵称',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: '身份',
                        ),
                        items: const [
                          DropdownMenuItem(value: '我', child: Text('我')),
                          DropdownMenuItem(value: '女朋友', child: Text('女朋友')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _role = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? '保存中...' : '进入御膳房'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
