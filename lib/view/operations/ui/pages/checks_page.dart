import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class ChecksPage extends StatelessWidget {
  const ChecksPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.checks);
}
