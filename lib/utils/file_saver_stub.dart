void saveFile({
  required String content,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('Cannot save file without dart:html or dart:io');
}
