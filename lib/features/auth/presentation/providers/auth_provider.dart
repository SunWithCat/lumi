import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';

// 认证状态
class AuthState {
  final bool isLoggedIn;
  final User? currentUser;
  final bool isLoading;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = true,
  });

  // AuthState copyWith({bool? isLoggedIn, User? currentUser, bool? isLoading}) {
  //   return AuthState(
  //     isLoggedIn: isLoggedIn ?? this.isLoggedIn,
  //     currentUser: currentUser ?? this.currentUser,
  //     isLoading: isLoading ?? this.isLoading,
  //   );
  // }
}

// 当前登录用户ID的设置键
const _kCurrentUserIdKey = 'current_user_id';

// 认证管理器
class AuthNotifier extends StateNotifier<AuthState> {
  final AppDatabase _db;

  AuthNotifier(this._db) : super(const AuthState()) {
    _checkLoginState();
  }

  // 检查是否有已注册用户及登录会话（启动时调用）
  Future<void> _checkLoginState() async {
    final hasUser = await _db.hasRegisteredUser();
    if (!hasUser) {
      // 没有注册用户，需要先注册
      state = const AuthState(isLoggedIn: false, isLoading: false);
      return;
    }

    // 检查是否有保存的登录会话
    final savedUserId = await _db.getSetting(_kCurrentUserIdKey);
    if (savedUserId != null) {
      // 有保存的会话，尝试恢复登录状态
      final userId = int.tryParse(savedUserId);
      if (userId != null) {
        final user = await _db.getUser(userId);
        if (user != null) {
          state = AuthState(
            isLoggedIn: true,
            currentUser: user,
            isLoading: false,
          );
          return;
        }
      }
    }

    // 没有保存的会话，需要重新登录
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }

  // 密码哈希
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // 注册
  Future<String?> register(String username, String password) async {
    if (username.trim().isEmpty) return '请输入用户名';
    if (password.length < 4) return '密码至少4位';

    final hash = _hashPassword(password);
    try {
      await _db.createUser(username: username.trim(), passwordHash: hash);
      // 注册后自动登录
      final user = await _db.validateUser(username.trim(), hash);
      if (user != null) {
        // 保存登录会话
        await _db.setSetting(_kCurrentUserIdKey, user.id.toString());
        state = AuthState(
          isLoggedIn: true,
          currentUser: user,
          isLoading: false,
        );
      }
      return null; // 成功返回 null
    } catch (e) {
      return '注册失败: $e';
    }
  }

  // 登录
  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty) return '请输入用户名';
    if (password.isEmpty) return '请输入密码';

    final hash = _hashPassword(password);
    final user = await _db.validateUser(username.trim(), hash);
    if (user == null) return '用户名或密码错误';

    await _db.updateLastLogin(user.id);
    // 保存登录会话
    await _db.setSetting(_kCurrentUserIdKey, user.id.toString());
    state = AuthState(isLoggedIn: true, currentUser: user, isLoading: false);
    return null; // 成功返回 null
  }

  // 退出登录
  Future<void> logout() async {
    // 清除保存的登录会话
    await _db.deleteSetting(_kCurrentUserIdKey);
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }

  // 是否有注册用户
  Future<bool> hasUser() => _db.hasRegisteredUser();
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(databaseProvider);
  return AuthNotifier(db);
});
