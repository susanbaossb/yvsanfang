import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/supabase_client.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  late TextEditingController _nicknameController;
  late TextEditingController _roleController;
  late TextEditingController _emailController;

  Uint8List? _pickedAvatarBytes;
  String? _newAvatarUrl;
  bool _saving = false;
  String? _displayEmail; // 显示的邮箱
  bool _isEmailBound = false; // 是否已绑定

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.profile.nickname);
    _roleController = TextEditingController(text: widget.profile.role);
    _emailController = TextEditingController();

    // 优先使用 profile 中的邮箱（实际存储的），否则使用 auth 中的邮箱
    final profileEmail = widget.profile.email;
    final authEmail = _authService.currentUserEmail;
    _displayEmail = profileEmail ?? authEmail;
    _isEmailBound = profileEmail != null && profileEmail.isNotEmpty;
    if (!_isEmailBound && authEmail != null && authEmail.isNotEmpty) {
      _isEmailBound = true;
    }
  }

  Future<void> _unbindEmail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解绑邮箱'),
        content: const Text('确定要解绑邮箱吗？解绑后可通过重新绑定恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定解绑'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      // 清空 profiles 表中的邮箱
      await AppSupabase.client
          .from('profiles')
          .update({'email': null})
          .eq('id', widget.profile.id);
      
      if (!mounted) return;
      setState(() {
        _displayEmail = null;
        _isEmailBound = false;
        _emailController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邮箱已解绑')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解绑失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 256,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedAvatarBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final role = _roleController.text.trim();
    final email = _emailController.text.trim();

    if (nickname.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('昵称和身份不能为空')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String? avatarUrl = widget.profile.avatarUrl;

      // 上传新头像
      if (_pickedAvatarBytes != null) {
        avatarUrl = await _authService.uploadAvatar(
          bytes: _pickedAvatarBytes!,
          userId: widget.profile.id,
        );
      }

      await _authService.saveProfile(
        nickname: nickname,
        role: role,
        avatarUrl: avatarUrl,
        email: email,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头像
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFFF0F7),
                    backgroundImage: _pickedAvatarBytes != null
                        ? MemoryImage(_pickedAvatarBytes!)
                        : (widget.profile.avatarUrl != null
                            ? NetworkImage(widget.profile.avatarUrl!)
                            : null) as ImageProvider?,
                    child: widget.profile.avatarUrl == null && _pickedAvatarBytes == null
                        ? const Icon(Icons.person, size: 50, color: Color(0xFFE85D9A))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE85D9A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('点击更换头像', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 24),

          // 昵称
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // 身份
          DropdownButtonFormField<String>(
            initialValue: _roleController.text.isEmpty ? null : _roleController.text,
            decoration: const InputDecoration(
              labelText: '身份',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '女朋友', child: Text('女朋友')),
              DropdownMenuItem(value: '男朋友', child: Text('男朋友')),
            ],
            onChanged: (value) {
              if (value != null) {
                _roleController.text = value;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请选择身份';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 邮箱
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Color(0xFFE85D9A)),
                      const SizedBox(width: 8),
                      const Text(
                        '邮箱绑定',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const Spacer(),
                      if (_isEmailBound)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '已绑定',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '未绑定',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 已绑定：显示邮箱 + 解绑按钮
                  if (_isEmailBound && _displayEmail != null && _displayEmail!.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayEmail!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : _unbindEmail,
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('解绑'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '输入邮箱',
                        border: OutlineInputBorder(),
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
