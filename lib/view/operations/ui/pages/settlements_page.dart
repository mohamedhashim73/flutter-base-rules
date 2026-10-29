import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class SettlementsPage extends StatelessWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.settlements);
}
