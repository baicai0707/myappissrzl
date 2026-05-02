import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../widgets/custom_toast.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameController = TextEditingController(
        text: profile.name == '点击编辑昵称' ? '' : profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final profile = context.read<ProfileProvider>();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        profile.updateAvatar(image.path);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, '选择图片失败');
      }
    }
  }

  void _removeAvatar() {
    context.read<ProfileProvider>().updateAvatar(null);
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<ProfileProvider>().updateName(name);
    }
    if (mounted) {
      CustomToast.success(context, '资料已保存');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text('保存',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: profile.avatarPath != null
                        ? ClipOval(
                            child: Image.file(
                              File(profile.avatarPath!),
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(Icons.person,
                                  size: 56,
                                  color: theme.colorScheme.primary),
                            ),
                          )
                        : Icon(Icons.person,
                            size: 56, color: theme.colorScheme.primary),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _pickImage,
                  child: Text('更换头像',
                      style:
                          TextStyle(color: theme.colorScheme.primary)),
                ),
                if (profile.avatarPath != null)
                  TextButton(
                    onPressed: _removeAvatar,
                    child: const Text('移除头像',
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('昵称',
                  style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: '请输入昵称'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('保存资料')),
            ),
          ],
        ),
      ),
    );
  }
}
