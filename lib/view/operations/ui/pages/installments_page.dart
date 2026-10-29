import 'package:flutter/material.dart';
import 'financial_records_page.dart';

class InstallmentsPage extends StatelessWidget {
  const InstallmentsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinancialRecordsPage(section: FinancialRecordsSection.installments);
}
