/// 登录页面
/// 
/// 功能：
/// 1. 检查本地是否已有登录用户 → 有则直接跳转首页
/// 2. 无则显示登录表单
/// 3. 输入昵称或邮箱，查找数据库
/// 4. 存在则登录，不存在则注册新用户
/// 5. 身份选择：男朋友 / 女朋友

import 'package:flutter/material.dart';

import '../../features/home/home_page.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/jpush_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nicknameController = TextEditingController();
  final _authService = AuthService();

  String _role = '女朋友';
  bool _loading = true;
  bool _saving = false;
  String? _roleError; // 身份验证错误提示

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 检查本地是否有已登录用户
  Future<void> _bootstrap() async {
    try {
      // 初始化用户（从本地存储恢复）
      await _authService.initCurrentUser();
      
      // 检查是否有已登录用户
      if (await _authService.hasLoggedInUser()) {
        // 有本地用户，尝试从数据库获取最新资料
        final profile = await _authService.fetchMyProfile();
        if (!mounted) return;
        if (profile != null) {
          JPushService().setAlias(profile.id);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(profile: profile)),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('初始化失败：$e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  /// 提交登录/注册
  Future<void> _submit() async {
    final input = _nicknameController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入昵称或邮箱')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 判断输入是邮箱还是昵称
      final isEmail = input.contains('@');
      final nickname = isEmail ? input.split('@').first : input;
      final email = isEmail ? input : null;

      // 先查找数据库中是否有这个用户
      final existingUser = await _authService.findUserByNameOrEmail(input);
      
      UserProfile profile;
      if (existingUser != null) {
        // 已存在用户，检查身份是否匹配
        if (existingUser.role != _role) {
          setState(() {
            _roleError = '该账号注册身份为「${existingUser.role}」';
          });
          return;
        }
        // 身份匹配，登录
        setState(() { _roleError = null; });
        profile = await _authService.loginExistingUser(existingUser);
      } else {
        // 新用户，注册
        profile = await _authService.createUser(
          nickname: nickname,
          role: _role,
          email: email,
        );
      }

      if (!mounted) return;
      JPushService().setAlias(profile.id);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(profile: profile)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：$e')),
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
                          labelText: '昵称 / 邮箱',
                          hintText: '请输入昵称或绑定的邮箱',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            decoration: InputDecoration(
                              labelText: '身份',
                              errorText: _roleError,
                              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                              border: _roleError != null
                                  ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade300))
                                  : null,
                              enabledBorder: _roleError != null
                                  ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade300))
                                  : null,
                              focusedBorder: _roleError != null
                                  ? OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                                  : null,
                            ),
                            items: const [
                              DropdownMenuItem(value: '男朋友', child: Text('男朋友')),
                              DropdownMenuItem(value: '女朋友', child: Text('女朋友')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _role = value;
                                  _roleError = null; // 选择时清除错误
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? '登录中...' : '进入御膳房'),
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
