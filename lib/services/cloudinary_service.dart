import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dfhdxzncc';
  static const String uploadPreset = 'findback_unsigned';

  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка загрузки изображения: $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    return data['secure_url'] as String;
  }

  Future<List<String>> uploadImages(List<XFile> files) async {
    final List<String> urls = [];

    for (final file in files) {
      final url = await uploadImage(file);
      urls.add(url);
    }

    return urls;
  }
}