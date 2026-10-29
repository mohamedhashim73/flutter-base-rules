import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class TreasuryLedgerPage extends StatelessWidget {
  const TreasuryLedgerPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.treasury);
}
