import 'package:base/model/base/request_state.dart';

class AuthState extends RequestState {
  const AuthState({super.status, super.message, this.isRegisterMode = false});

  final bool isRegisterMode;
}
