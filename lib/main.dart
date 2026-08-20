import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'groq_service.dart';

void main() {
  runApp(const SnapshotChefApp());
}

class SnapshotChefApp extends StatelessWidget {
  const SnapshotChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snapshot Chef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  Map<String, dynamic>? result;
  bool loading = false;



  // Take a photo using the camera
  Future<void> takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) return;

      setState(() {
        selectedImage = image;
        result = null;
      });
    } catch (e) {
      setState(() {
        result = {
        'error': 'Unable to take photo: $e',
        };
      });
    }
  }

  // Choose an existing image
  Future<void> selectPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() {
        selectedImage = image;
        result = null;
      });
    } catch (e) {
      setState(() {
        result = {
        'error': 'Unable to select photo: $e'
        };
      });
    }
  }

  // Send the image to the Cloudflare Worker
  Future<void> analyzeImage() async {
    if (selectedImage == null || loading) return;

    setState(() {
      loading = true;
      result = null;
    });

    try {
      final response = await GroqService.analyzeFridge(
        selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        result = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        result = {
          'error': 'Something went wrong:\n$e',
        };
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }


  Widget buildRecipeCard() {
    if (result == null) {
      return const SizedBox();

    }

    if (result!['error'] != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            result!['error'],
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
            )
          )
        )
      );
    }

    final dish = result!['dish'] ?? 'Your Recipe';
    final ingredients = 
        List<String>.from(result!['ingredients'] ?? []);
    final why = result!['Why'] ?? '';
    final instructions = 
        List<String>.from(result!['instructions'] ?? []);
    final tip = result!['tip'] ?? '';

    return Card(
      elevation: 2, 
      margin: const EdgeInsets.only(top: 24, bottom: 24,),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 650,
        ),
      
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //Recipe heading
            const Text(
              'Your Recipe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              dish,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 107, 235, 112),
              ),
            ),

            const SizedBox(height: 24),

            //Ingredients
            const Text(
              'Foods AI had found',
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8, 
              runSpacing: 8,
              children: ingredients.map((ingredient) {
                return Chip(
                  avatar: const Icon(
                    Icons.check,
                    size: 16,
                  ),
                  label: Text(ingredient),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            //Why
            const Text(
              'Why this recipe',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              
              ),
            ),

            const SizedBox(height: 8),

            Text(
              why,
              style: const TextStyle(
                fontSize: 16, 
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            //Instruction
            const Text(
              'How to cook',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 12),

            ...instructions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final instruction = entry.value;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14, 
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            //chef tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tips from the Chef \n\n$tip',
                style: const TextStyle(
                  fontSize: 15, 
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
        'Snapshot Chef',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        ),
       
        leading: const Icon(
          Icons.kitchen,
          size: 40,
        )
      ),
      
      body: SingleChildScrollView(
      child: Center(
      child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 900,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Your title / description
            const Text(
              'Turn what’s in your fridge into your dinner.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Take a snapshot and discover what you can cook.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // Refrigerator image
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  selectedImage!.path,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.kitchen,
                size: 120,
              ),

            const SizedBox(height: 30),

            // Camera button
            ElevatedButton.icon(
              onPressed: takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a Snapshot of Refrigerator'),
            ),

            const SizedBox(height: 10),

            // Gallery button
            OutlinedButton.icon(
              onPressed: selectPhoto,
              icon: const Icon(Icons.photo),
              label: const Text('Choose from Gallery'),
            ),

            const SizedBox(height: 10),

            // Analyze button
            ElevatedButton(
              onPressed: loading ? null : analyzeImage,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Ask for recipe'),
            ),

            const SizedBox(height: 20),

            // Recipe
            if (result != null)
              buildRecipeCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
),
    );
  }
}