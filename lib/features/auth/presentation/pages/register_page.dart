import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumi/core/router/app_router.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:toastification/toastification.dart';

/// 注册页面
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // 确认密码校验
    if (_passwordController.text != _confirmController.text) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: const Text(
          '两次密码不一致噢~',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        type: ToastificationType.error,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: context.colorScheme.primary,
        ),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        boxShadow: [
          BoxShadow(
            color: context.lumiColors.shadowColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await ref
        .read(authProvider.notifier)
        .register(_usernameController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (error != null && mounted) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: Text(
          error,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        type: ToastificationType.error,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: context.colorScheme.primary,
        ),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        boxShadow: [
          BoxShadow(
            color: context.lumiColors.shadowColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.lumiColors.backgroundGradientTop,
              context.lumiColors.backgroundGradientMiddle,
              context.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 区域
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.lumiColors.primaryGradientStart
                              .withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/lumi_icon.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '创建账号',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开始你的专属伴侣之旅',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.lumiColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 用户名
                  _buildTextField(
                    controller: _usernameController,
                    icon: Icons.person_outline_rounded,
                    hint: '用户名（1-20字符）',
                  ),
                  const SizedBox(height: 16),

                  // 密码
                  _buildTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: '密码（至少4位）',
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: context.lumiColors.textSecondary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 确认密码
                  _buildTextField(
                    controller: _confirmController,
                    icon: Icons.lock_outline_rounded,
                    hint: '确认密码',
                    obscure: true,
                  ),
                  const SizedBox(height: 32),

                  // 注册按钮
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: context.lumiColors.shadowColor.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: context.colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '注  册',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 跳转登录
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text.rich(
                      TextSpan(
                        text: '已有账号？',
                        style: TextStyle(color: context.lumiColors.textSecondary),
                        children: [
                          TextSpan(
                            text: '立即登录',
                            style: TextStyle(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: context.colorScheme.primary, size: 22),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(
            color: context.lumiColors.textSecondary.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
