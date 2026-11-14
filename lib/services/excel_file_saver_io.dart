import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveExcelBytes(Uint8List bytes, String filename) async {
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(path)],
    subject: filename,
    text: 'تقرير دائرة الاتصالات - وزارة الطوارئ وإدارة الكوارث',
  );
  return path;
}
