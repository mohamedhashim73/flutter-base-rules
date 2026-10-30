import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/view/users/data/repository/users_repository.dart';
import 'users_states.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repository) : super(const UsersState());
  final UsersRepository _repository;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final displayNameController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'employee';
  bool settlementReview = false;
  bool recordsEdit = false;
  bool treasuryReconcile = false;
  bool treasuryAccountsManage = false;
  bool expenseCategoriesManage = false;
  bool recordsDelete = false;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final users = await _repository.listUsers();
      if (isClosed) return;
      emit(UsersState(status: RequestStatus.success, users: users));
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> createUser() async {
    if (isClosed) return;
    if (formKey.currentState?.validate() != true) return;
    emit(state.copyWith(actionStatus: RequestStatus.loading));
    try {
      await _repository.createUser(
        email: emailController.text.trim(),
        displayName: displayNameController.text.trim(),
        temporaryPassword: passwordController.text,
        role: role,
        permissions: {
          'settlements.review': settlementReview,
          'records.edit': recordsEdit,
          'treasury.reconcile': treasuryReconcile,
          'treasury.accounts.manage': treasuryAccountsManage,
          'expenses.categories.manage': expenseCategoriesManage,
          'records.delete': recordsDelete,
        },
      );
      emailController.clear();
      displayNameController.clear();
      passwordController.clear();
      await load();
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.success,
          actionMessage: 'تم إنشاء المستخدم وتعيين صلاحياته.',
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.failure,
          actionMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> updateUserAccess({
    required String uid,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(actionStatus: RequestStatus.loading));
    try {
      await _repository.updateAccess(
        uid: uid,
        role: role,
        permissions: permissions,
      );
      await load();
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.success,
          actionMessage: 'تم تحديث صلاحيات المستخدم.',
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.failure,
          actionMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    displayNameController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
