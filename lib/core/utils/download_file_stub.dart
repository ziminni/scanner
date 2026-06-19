void downloadAsset({required String assetPath, required String fileName}) {
  throw UnsupportedError('File download is only available on Flutter Web.');
}

void downloadBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) {
  throw UnsupportedError('File download is only available on Flutter Web.');
}
