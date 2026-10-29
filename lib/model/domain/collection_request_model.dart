import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class CollectionRequestModel extends Equatable {
  const CollectionRequestModel({
    required this.id,
    required this.settlementId,
    required this.amountMinor,
    this.commissionMinor = 0,
    required this.feeMinor,
    required this.netMinor,
    required this.status,
    required this.confirmationReference,
    required this.createdAtMillis,
    this.collectionType = 'instant',
    this.confirmedBy,
    this.confirmedAtMillis,
  });
  final String id;
  final String settlementId;
  final int amountMinor;
  final int commissionMinor;
  final int feeMinor;
  final int netMinor;
  final String status;
  final String confirmationReference;
  final int createdAtMillis;
  final String collectionType;
  final String? confirmedBy;
  final int? confirmedAtMillis;
  factory CollectionRequestModel.fromJson(Object? json) =>
      CollectionRequestModel(
        id: asStringOr(json, 'id'),
        settlementId: asStringOr(json, 'settlementId'),
        amountMinor: asIntOr(json, 'amountMinor'),
        commissionMinor: asIntOr(json, 'commissionMinor'),
        feeMinor: asIntOr(json, 'feeMinor'),
        netMinor: asIntOr(json, 'netMinor'),
        status: asStringOr(json, 'status', fallback: 'pending'),
        confirmationReference: asStringOr(json, 'confirmationReference'),
        createdAtMillis: asIntOr(json, 'createdAtMillis'),
        collectionType: asStringOr(json, 'collectionType', fallback: 'instant'),
        confirmedBy: asStringOrNull(json, 'confirmedBy'),
        confirmedAtMillis: asIntOrNull(json, 'confirmedAtMillis'),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'settlementId': settlementId,
    'amountMinor': amountMinor,
    'commissionMinor': commissionMinor,
    'feeMinor': feeMinor,
    'netMinor': netMinor,
    'status': status,
    'confirmationReference': confirmationReference,
    'createdAtMillis': createdAtMillis,
    'updatedAtMillis': createdAtMillis,
    'collectionType': collectionType,
    'confirmedBy': confirmedBy,
    'confirmedAtMillis': confirmedAtMillis,
  };
  @override
  List<Object?> get props => [
    id,
    settlementId,
    amountMinor,
    commissionMinor,
    status,
    confirmationReference,
    confirmedBy,
    confirmedAtMillis,
    createdAtMillis,
  ];
}
