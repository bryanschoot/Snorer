enum RecordingSizeUnit {
  megabytes(symbol: 'MB', bytesPerUnit: 1000 * 1000),
  gigabytes(symbol: 'GB', bytesPerUnit: 1000 * 1000 * 1000);

  const RecordingSizeUnit({required this.symbol, required this.bytesPerUnit});

  final String symbol;
  final int bytesPerUnit;

  static RecordingSizeUnit fromStorage(String? value) => switch (value) {
    'gigabytes' => RecordingSizeUnit.gigabytes,
    _ => RecordingSizeUnit.megabytes,
  };
}
