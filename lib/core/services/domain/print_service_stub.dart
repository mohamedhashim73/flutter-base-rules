class PrintService {
  const PrintService._();

  static void printPage() {}

  static void downloadExcel({required String filename, required String html}) {}

  static void downloadXlsx({
    required String filename,
    required List<List<String>> rows,
  }) {}

  static void downloadPdf({
    required String filename,
    required List<String> lines,
  }) {}
}
