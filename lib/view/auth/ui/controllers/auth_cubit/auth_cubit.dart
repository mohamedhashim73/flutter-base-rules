import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/services/services.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(const AuthState());

  final FirebaseAuthService _authService;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isRegisterMode = false;

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;
    emit(const AuthState(status: RequestStatus.loading));
    try {
      if (isRegisterMode) {
        await _authService.createAccount(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        // Registration creates only an authentication account. Organization
        // membership is assigned separately by an authorized manager or by a
        // documented Firebase Console bootstrap; a new account never grants
        // itself manager access.
      } else {
        await _authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
      emit(
        const AuthState(
          status: RequestStatus.success,
          message: 'تم تسجيل الدخول بنجاح.',
        ),
      );
    } catch (error) {
      emit(AuthState(status: RequestStatus.failure, message: _message(error)));
    }
  }

  void toggleMode() {
    isRegisterMode = !isRegisterMode;
    emit(const AuthState());
  }

  String _message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        'email-already-in-use' => 'هذا البريد الإلكتروني مستخدم بالفعل.',
        'weak-password' => 'كلمة المرور ضعيفة.',
        _ => error.message ?? 'تعذر تنفيذ العملية.',
      };
    }
    return 'تعذر تنفيذ العملية.';
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
