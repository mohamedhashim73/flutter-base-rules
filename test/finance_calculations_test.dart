import 'package:flutter_test/flutter_test.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/view/credit_cards/data/repository/credit_accounting_calculator.dart';
import 'package:base/core/services/domain/xlsx_package_builder.dart';

void main() {
  test('commission is calculated in minor units', () {
    expect(
      FinanceMoney.commissionMinor(amountMinor: 1000000, commissionBps: 200),
      20000,
    );
  });

  test('monthly debt follows the agreed opening-balance example', () {
    expect(
      CreditAccountingCalculator.monthlyDebt(
        creditLimitMinor: 40000000,
        openingBalanceMinor: 500000,
      ),
      39500000,
    );
    expect(
      CreditAccountingCalculator.remainingMonthlyDebt(
        openingDebtMinor: 39500000,
        qualifyingDepositsMinor: 10000000,
      ),
      29500000,
    );
  });

  test('negative managed balance is not blocked by the calculator', () {
    expect(1000000 - 2500000, -1500000);
  });

  test('negative opening balance increases monthly debt', () {
    expect(
      CreditAccountingCalculator.monthlyDebt(
        creditLimitMinor: 40000000,
        openingBalanceMinor: -1000000,
      ),
      41000000,
    );
  });

  test('instant collection fee is based on gross before commission', () {
    expect(
      FinanceMoney.expectedCollectionBankAmountMinor(
        grossMinor: 10000000,
        commissionMinor: 200000,
        instant: true,
      ),
      9790000,
    );
  });

  test('collection reservations cannot exceed the settlement remainder', () {
    expect(FinanceMoney.instantCollectionFeeMinor(10000000), 10000);
    expect(
      FinanceMoney.remainingCollectibleMinor(
        netSettlementMinor: 20000000,
        collectedMinor: 5000000,
        requestedMinor: 4000000,
      ),
      11000000,
    );
    expect(
      FinanceMoney.remainingCollectibleMinor(
        netSettlementMinor: 20000000,
        collectedMinor: 15000000,
        requestedMinor: 6000000,
      ),
      0,
    );
  });

  test('xlsx export is a readable OOXML package', () {
    final bytes = XlsxPackageBuilder.build([
      ['Brand', 'Amount'],
      ['A&B', '100.00'],
    ]);
    final binary = String.fromCharCodes(bytes);
    expect(bytes.sublist(0, 4), [0x50, 0x4b, 0x03, 0x04]);
    expect(binary, contains('[Content_Types].xml'));
    expect(binary, contains('xl/workbook.xml'));
    expect(binary, contains('xl/worksheets/sheet1.xml'));
    expect(binary, contains('A&amp;B'));
  });
}
