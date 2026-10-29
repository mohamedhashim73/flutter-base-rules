class CreditAccountingCalculator {
  const CreditAccountingCalculator._();

  static int monthlyDebt({
    required int creditLimitMinor,
    required int openingBalanceMinor,
  }) {
    return (creditLimitMinor - openingBalanceMinor).clamp(0, 1 << 62).toInt();
  }

  static int remainingMonthlyDebt({
    required int openingDebtMinor,
    required int qualifyingDepositsMinor,
  }) {
    return (openingDebtMinor - qualifyingDepositsMinor)
        .clamp(0, 1 << 62)
        .toInt();
  }
}
