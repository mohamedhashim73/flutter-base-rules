import 'package:base/core/services/services.dart';
import 'package:base/model/domain/credit_card_model.dart';

class CreditCardsResponseModel
    implements LoadableResponse<List<CreditCardModel>> {
  const CreditCardsResponseModel(this.data);

  @override
  final List<CreditCardModel> data;
}
