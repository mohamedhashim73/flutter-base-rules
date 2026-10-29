import 'package:equatable/equatable.dart';

class BrandUsageSummaryModel extends Equatable {
  const BrandUsageSummaryModel({
    required this.brandId,
    required this.brandName,
    required this.providerName,
    required this.usageCount,
    required this.lastUsedAtMillis,
  });

  final String brandId;
  final String brandName;
  final String providerName;
  final int usageCount;
  final int? lastUsedAtMillis;

  @override
  List<Object?> get props => [brandId, usageCount, lastUsedAtMillis];
}
