import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class PersonalWithdrawalsPage extends StatelessWidget {
  const PersonalWithdrawalsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.withdrawals);
}
