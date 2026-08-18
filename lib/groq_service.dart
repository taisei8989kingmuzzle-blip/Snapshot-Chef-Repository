import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String backendUrl =
      'https://snapshot-chef-backend.snapshot-chef.workers.dev';

  static Future<String> analyzeFridge(XFile image) async {
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

    final dish = data['dish'] ?? 'Unknown dish';

    final ingredients = data['ingredients'] is List
        ? List<String>.from(data['ingredients'])
        : <String>[];

    final why = data['why'] ?? 'This recipe uses ingredients detected in your refrigerator.';

    final instructions = data['instructions'] is List
        ? List<String>.from(data['instructions'])
        : <String>[];

    final tip = data['tip'] ?? 'None';

    return '''
    $dish

    Ingredients:
    ${ingredients.isEmpty ? 'No ingredients detected.' : ingredients.map((e) => '• $e').join('\n')}

    Why this dish:
    $why

    Instructions:
    ${instructions.isEmpty ? 'No instructions were provided.' : instructions.asMap().entries.map(
      (entry) => '${entry.key + 1}. ${entry.value}'
    ).join('\n')}

    Tip:
    $tip
    ''';
  }
}