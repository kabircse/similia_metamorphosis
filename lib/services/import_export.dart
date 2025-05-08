import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/disease.dart';
import '../db/disease_db.dart';

Future<void> exportDiseases() async {
  final diseases = await DiseaseDB().getAllDiseases();
  final jsonDiseases = jsonEncode(diseases.map((e) => e.toMap()).toList());

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/diseases_export.json');
  await file.writeAsString(jsonDiseases);

  Share.shareFiles([file.path], text: 'Exported Diseases');
}

Future<void> importDiseases() async {
  final result = await FilePicker.platform.pickFiles();
  if (result != null) {
    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(jsonStr);

    await DiseaseDB().deleteAllDiseases();
    for (var item in decoded) {
      await DiseaseDB().insertDisease(Disease.fromMap(item));
    }
  }
}
