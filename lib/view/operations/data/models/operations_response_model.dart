import 'package:base/core/services/services.dart';
import 'package:base/model/domain/treasury_account_model.dart';

class OperationsResponseModel
    implements LoadableResponse<List<TreasuryAccountModel>> {
  const OperationsResponseModel(this.data);
  @override
  final List<TreasuryAccountModel> data;
}
