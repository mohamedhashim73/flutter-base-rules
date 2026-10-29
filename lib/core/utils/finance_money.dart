import 'package:intl/intl.dart';

class FinanceMoney {
  const FinanceMoney._();

  static int parseToMinor(String value) {
    final normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
    return (parsed * 100).round();
  }

  static String formatEgp(int minor) {
    final amount = (minor / 100).abs();
    final formatted = NumberFormat('#,##0.00', 'en_US').format(amount);
    return '${minor < 0 ? '-' : ''} EGP $formatted';
  }

  static int commissionMinor({
    required int amountMinor,
    required int commissionBps,
  }) {
    return (amountMinor * commissionBps + 5000) ~/ 10000;
  }

  static int instantCollectionFeeMinor(int requestedGrossMinor) =>
      commissionMinor(amountMinor: requestedGrossMinor, commissionBps: 10);

  static int expectedCollectionBankAmountMinor({
    required int grossMinor,
    required int commissionMinor,
    required bool instant,
  }) {
    final fee = instant ? instantCollectionFeeMinor(grossMinor) : 0;
    return grossMinor - commissionMinor - fee;
  }

  static int remainingCollectibleMinor({
    required int netSettlementMinor,
    required int collectedMinor,
    required int requestedMinor,
  }) => (netSettlementMinor - collectedMinor - requestedMinor)
      .clamp(0, netSettlementMinor)
      .toInt();
}
