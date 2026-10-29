import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/view/audit/data/repository/audit_repository.dart';
import 'audit_states.dart';

class AuditCubit extends Cubit<AuditState> {
  AuditCubit(this._repository) : super(const AuditState());

  final AuditRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      emit(
        AuditState(
          status: RequestStatus.success,
          items: await _repository.getAuditLogs(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
