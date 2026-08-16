import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GroqService {

  // LOCAL DEVELOPMENT
  static const String backendUrl =
      'http://127.0.0.1:8787';

  static Future<String> analyzeFridge(File image) async {

    final bytes = await image.readAsBytes();

    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(backendUrl),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'image': 'data:image/jpeg;base64,$base64Image',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error: ${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return data['choices'][0]['message']['content'];
  }
}