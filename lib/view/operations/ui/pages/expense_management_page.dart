import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class ExpenseManagementPage extends StatelessWidget {
  const ExpenseManagementPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.expenses);
}
